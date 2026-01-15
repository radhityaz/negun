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
	
	q.ID = fmt.Sprintf("%s-q-%d", examID, count+1) // Make ID unique globally by prefixing examID? Or just q-X.
	// Previously it was q-%d. Since Question.ID is Primary Key, it must be unique. 
	// Ideally use UUID or auto-increment ID. But let's stick to string ID for now but make it unique.
	// Or maybe just let the user provide it? No, the code generates it.
	// Let's use a composite string or just UUID.
	// For now: examID-q-index
	q.ID = fmt.Sprintf("%s-q-%d", examID, count+1)
	q.ExamID = examID
	
	if result := database.DB.Create(&q); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
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
