package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"exam-system-backend/models"
	"exam-system-backend/pkg/crypto"
	"exam-system-backend/database"
)

// CreateExam: Guru membuat metadata ujian baru
func CreateExam(c *gin.Context) {
	var req models.ExamHeader
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	req.ExamID = fmt.Sprintf("exam-%d", time.Now().Unix())
	req.CreatedAt = time.Now()
	
	if result := database.DB.Create(&req); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Exam created", "exam": req})
}

// AddQuestion: Guru menambahkan soal ke ujian
func AddQuestion(c *gin.Context) {
	examID := c.Param("examId")
	
	// Check if exam exists
	var exam models.ExamHeader
	if result := database.DB.First(&exam, "exam_id = ?", examID); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Exam not found"})
		return
	}

	var q models.Question
	if err := c.ShouldBindJSON(&q); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	// Count existing questions to generate ID
	var count int64
	database.DB.Model(&models.Question{}).Where("exam_id = ?", examID).Count(&count)
	
	q.ID = fmt.Sprintf("%s-q-%d", examID, count+1)
	q.ExamID = examID
	
	if result := database.DB.Create(&q); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	if len(q.Options) > 0 {
		for i := range q.Options {
			q.Options[i].QuestionID = q.ID
		}
		if result := database.DB.Create(&q.Options); result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
			return
		}
	}
	c.JSON(http.StatusOK, gin.H{"message": "Question added", "question": q})
}

// PublishExam: Generate file .exam terenkripsi
func PublishExam(c *gin.Context) {
	examID := c.Param("examId")
	
	var header models.ExamHeader
	// Preload Questions and Options
	if result := database.DB.Preload("Questions.Options").First(&header, "exam_id = ?", examID); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Exam not found"})
		return
	}

	if len(header.Questions) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot publish exam with no questions"})
		return
	}

	// 1. Siapkan Payload
	payload := models.ExamPayload{
		Questions: header.Questions,
		Config: models.ExamConfig{
			AllowWifi: false,
			RandomizeOrder: true,
			ShowResult: false,
		},
	}

	payloadBytes, _ := json.Marshal(payload)

	// Get Master Key from Env
	masterKeyStr := os.Getenv("MASTER_KEY")
	if len(masterKeyStr) != 32 {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid MASTER_KEY configuration"})
		return
	}
	masterKey := []byte(masterKeyStr)

	// 2. Enkripsi Payload
	ivHex, ciphertextB64, err := crypto.EncryptAES(string(payloadBytes), masterKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Encryption failed"})
		return
	}

	// 3. Update Header dengan IV
	header.EncryptionIV = ivHex
	header.Version += 1
	
	// Save version update to DB
	database.DB.Save(&header)

	// 4. Hitung Signature (HMAC) dari Header + Ciphertext
	signData := fmt.Sprintf("%s.%d.%s", header.ExamID, header.Version, ciphertextB64)
	signature := crypto.ComputeHMAC(signData, masterKey)

	// 5. Bungkus jadi ExamPackage
	pkg := models.ExamPackage{
		Header: header,
		Payload: ciphertextB64,
		Signature: signature,
	}

	// 6. Simpan ke File System (Storage)
	pkgBytes, _ := json.Marshal(pkg)
	filename := fmt.Sprintf("%s-v%d.exam", examID, header.Version)
	
	// Ensure storage directory exists
	if err := os.MkdirAll(filepath.Join("storage", "exams"), 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create storage directory"})
		return
	}
	
	filePath := filepath.Join("storage", "exams", filename)
	
	if err := os.WriteFile(filePath, pkgBytes, 0644); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to write file"})
		return
	}

	// Return URL download (simulasi)
	downloadURL := fmt.Sprintf("http://localhost:8080/files/%s", filename)
	c.JSON(http.StatusOK, gin.H{
		"message": "Exam published",
		"file_url": downloadURL,
		"file_path": filePath,
	})
}

// ListResults: Admin melihat semua hasil ujian yang masuk
func ListResults(c *gin.Context) {
	type ResultListItem struct {
		ID         uint      `json:"id"`
		ExamID     string    `json:"exam_id"`
		StudentID  string    `json:"student_id"`
		AttemptID  string    `json:"attempt_id"`
		Score      float64   `json:"score"`
		EssayScore float64   `json:"essay_score"`
		FinalScore float64   `json:"final_score"`
		SubmitTime time.Time `json:"submit_time"`
		AnswerFile string    `json:"answer_file_path"`
	}

	var results []ResultListItem
	if err := database.DB.Model(&models.ExamResult{}).
		Select("id, exam_id, student_id, attempt_id, score, essay_score, final_score, submit_time, answer_file").
		Order("submit_time desc").
		Find(&results).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, results)
}

func GetResult(c *gin.Context) {
	id := c.Param("id")

	var result models.ExamResult
	if err := database.DB.First(&result, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Result not found"})
		return
	}

	c.JSON(http.StatusOK, result)
}

func GetResultDetail(c *gin.Context) {
	id := c.Param("id")

	var result models.ExamResult
	if err := database.DB.First(&result, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Result not found"})
		return
	}

	var payload models.AnswerPayload
	if err := json.Unmarshal([]byte(result.RawAnswers), &payload); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid stored answers"})
		return
	}

	var questions []models.Question
	if err := database.DB.Preload("Options").Where("exam_id = ?", result.ExamID).Find(&questions).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	answerMap := map[string]interface{}{}
	for _, a := range payload.Answers {
		answerMap[a.QuestionID] = a.Answer
	}

	essayScoreMap := map[string]float64{}
	if result.EssayScores != "" {
		_ = json.Unmarshal([]byte(result.EssayScores), &essayScoreMap)
	}

	type QuestionDetail struct {
		QuestionID    string      `json:"question_id"`
		Type          string      `json:"type"`
		Content       string      `json:"content"`
		Points        int         `json:"points"`
		StudentAnswer interface{} `json:"student_answer"`
		CorrectAnswer string      `json:"correct_answer,omitempty"`
		IsCorrect     *bool       `json:"is_correct,omitempty"`
		Awarded       float64     `json:"awarded"`
	}

	details := make([]QuestionDetail, 0, len(questions))

	for _, q := range questions {
		studentAns := answerMap[q.ID]
		var correctAnswer string
		var isCorrect *bool
		awarded := 0.0

		if q.Type == "mc" {
			for _, opt := range q.Options {
				if opt.IsCorrect {
					correctAnswer = opt.ID
					break
				}
			}
			if s, ok := studentAns.(string); ok {
				val := s == correctAnswer
				isCorrect = &val
				if val {
					awarded = float64(q.Points)
				}
			}
		} else {
			if s, ok := essayScoreMap[q.ID]; ok {
				awarded = s
			}
		}

		details = append(details, QuestionDetail{
			QuestionID:    q.ID,
			Type:          q.Type,
			Content:       q.Content,
			Points:        q.Points,
			StudentAnswer: studentAns,
			CorrectAnswer: correctAnswer,
			IsCorrect:     isCorrect,
			Awarded:       awarded,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"result":    result,
		"questions": details,
	})
}

func SetEssayScores(c *gin.Context) {
	id := c.Param("id")

	var result models.ExamResult
	if err := database.DB.First(&result, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Result not found"})
		return
	}

	var req struct {
		Scores map[string]float64 `json:"scores"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var questions []models.Question
	if err := database.DB.Where("exam_id = ?", result.ExamID).Find(&questions).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	qPoints := map[string]int{}
	for _, q := range questions {
		qPoints[q.ID] = q.Points
	}

	validated := map[string]float64{}
	essayTotal := 0.0
	for qid, s := range req.Scores {
		max, ok := qPoints[qid]
		if !ok {
			continue
		}
		if s < 0 {
			s = 0
		}
		if s > float64(max) {
			s = float64(max)
		}
		validated[qid] = s
		essayTotal += s
	}

	bytes, _ := json.Marshal(validated)
	result.EssayScores = string(bytes)
	result.EssayScore = essayTotal
	result.FinalScore = result.Score + essayTotal

	if err := database.DB.Save(&result).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}
