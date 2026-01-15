package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"exam-system-backend/database"
	"exam-system-backend/models"
	"exam-system-backend/pkg/crypto"
)

// ListAvailableExams: Siswa melihat daftar ujian yang sudah dipublish
func ListAvailableExams(c *gin.Context) {
	type ExamResponse struct {
		ID           string `json:"id"`
		Title        string `json:"title"`
		DownloadURL  string `json:"download_url"`
		Version      int    `json:"version"`
		DurationMins int    `json:"duration_mins"`
	}

	var response []ExamResponse
	var exams []models.ExamHeader

	// Query DB where version > 0
	if result := database.DB.Where("version > ?", 0).Find(&exams); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	for _, exam := range exams {
		filename := fmt.Sprintf("%s-v%d.exam", exam.ExamID, exam.Version)
		downloadURL := fmt.Sprintf("http://localhost:8080/files/%s", filename)
		
		response = append(response, ExamResponse{
			ID:           exam.ExamID,
			Title:        exam.Title,
			DownloadURL:  downloadURL,
			Version:      exam.Version,
			DurationMins: exam.DurationMins,
		})
	}

	c.JSON(http.StatusOK, response)
}

// GetUploadURL: Siswa minta link buat upload hasil .ans
func GetUploadURL(c *gin.Context) {
	examID := c.Param("examId")
	
	// Generate unique attempt ID
	attemptID := fmt.Sprintf("att-%s-%d", examID, time.Now().UnixNano())
	
	uploadURL := fmt.Sprintf("/api/v1/attempts/upload/%s", attemptID)

	c.JSON(http.StatusOK, gin.H{
		"upload_url": uploadURL,
		"attempt_id": attemptID,
	})
}

// UploadAnswerHandler: Handle actual file upload
func UploadAnswerHandler(c *gin.Context) {
	attemptID := c.Param("attemptId")
	
	// 1. Receive File
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No file uploaded"})
		return
	}

	// Ensure storage directory exists
	saveDir := filepath.Join("storage", "answers")
	if err := os.MkdirAll(saveDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Storage init failed"})
		return
	}

	// Save File (.ans)
	filePath := filepath.Join(saveDir, fmt.Sprintf("%s.ans", attemptID))
	if err := c.SaveUploadedFile(file, filePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
		return
	}

	go processAnswerFile(filePath, attemptID)

	c.JSON(http.StatusOK, gin.H{"message": "File uploaded successfully"})
}

func processAnswerFile(filePath, attemptID string) {
	fileBytes, err := os.ReadFile(filePath)
	if err != nil {
		fmt.Printf("Error reading file %s: %v\n", filePath, err)
		return
	}

	var pkg models.AnswerPackage
	if err := json.Unmarshal(fileBytes, &pkg); err != nil {
		fmt.Printf("Error parsing JSON %s: %v\n", filePath, err)
		return
	}

	masterKeyStr := os.Getenv("MASTER_KEY")
	masterKey := []byte(masterKeyStr)

	decryptedJSON, err := crypto.DecryptAES(pkg.Payload, pkg.Header.IV, masterKey)
	if err != nil {
		fmt.Printf("Error decrypting %s: %v\n", filePath, err)
		return
	}

	var payload models.AnswerPayload
	if err := json.Unmarshal([]byte(decryptedJSON), &payload); err != nil {
		fmt.Printf("Error parsing payload %s: %v\n", filePath, err)
		return
	}

	score := calculateScore(pkg.Header.ExamID, payload.Answers)

	result := models.ExamResult{
		ExamID:     pkg.Header.ExamID,
		StudentID:  pkg.Header.StudentID, // In real app, validate this ID
		AttemptID:  pkg.Header.AttemptID,
		Score:      score,
		EssayScore: 0,
		FinalScore: score,
		SubmitTime: pkg.Header.SubmitTime,
		AnswerFile: filePath,
		RawAnswers: decryptedJSON,
		EssayScores: "{}",
	}

	if err := database.DB.Create(&result).Error; err != nil {
		fmt.Printf("Error saving result to DB: %v\n", err)
	} else {
		fmt.Printf("Successfully graded attempt %s. Score: %.2f\n", attemptID, score)
	}
}

func calculateScore(examID string, answers []models.AnswerItem) float64 {
	var questions []models.Question
	if err := database.DB.Preload("Options").Where("exam_id = ?", examID).Find(&questions).Error; err != nil {
		return 0
	}

	totalScore := 0.0

	qMap := make(map[string]models.Question)
	for _, q := range questions {
		qMap[q.ID] = q
	}

	for _, ans := range answers {
		q, exists := qMap[ans.QuestionID]
		if !exists {
			continue
		}

		if q.Type == "mc" {
			var correctOptionID string
			for _, opt := range q.Options {
				if opt.IsCorrect {
					correctOptionID = opt.ID 
					break
				}
			}
			userAns, ok := ans.Answer.(string)
			if ok && userAns == correctOptionID {
				totalScore += float64(q.Points)
			}
		} else {
		}
	}
	return totalScore
}

// ConfirmAttempt: Validasi akhir setelah upload selesai
func ConfirmAttempt(c *gin.Context) {
	var req struct {
		AttemptID       string `json:"attempt_id"`
		FileHash        string `json:"file_hash"`
		ClientSignature string `json:"client_signature"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "received",
		"receipt_code": fmt.Sprintf("RCPT-%s", req.AttemptID[len(req.AttemptID)-6:]),
	})
}
