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
)

// In-memory store for MVP (Replace with DB later)
var exams = make(map[string]models.ExamHeader)
var questions = make(map[string][]models.Question)

// Kunci enkripsi statis untuk MVP (Ganti dengan manajemen kunci yang aman nanti)
var masterKey = []byte("01234567890123456789012345678901") // 32 bytes

// CreateExam: Guru membuat metadata ujian baru
func CreateExam(c *gin.Context) {
	var req models.ExamHeader
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	req.ExamID = fmt.Sprintf("exam-%d", time.Now().Unix())
	req.CreatedAt = time.Now()
	
	exams[req.ExamID] = req
	questions[req.ExamID] = []models.Question{} // Init question list

	c.JSON(http.StatusOK, gin.H{"message": "Exam created", "exam": req})
}

// AddQuestion: Guru menambahkan soal ke ujian
func AddQuestion(c *gin.Context) {
	examID := c.Param("examId")
	if _, exists := exams[examID]; !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Exam not found"})
		return
	}

	var q models.Question
	if err := c.ShouldBindJSON(&q); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	q.ID = fmt.Sprintf("q-%d", len(questions[examID])+1)
	questions[examID] = append(questions[examID], q)

	c.JSON(http.StatusOK, gin.H{"message": "Question added", "question": q})
}

// PublishExam: Generate file .exam terenkripsi
func PublishExam(c *gin.Context) {
	examID := c.Param("examId")
	header, exists := exams[examID]
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Exam not found"})
		return
	}

	qList := questions[examID]
	if len(qList) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot publish exam with no questions"})
		return
	}

	// 1. Siapkan Payload
	payload := models.ExamPayload{
		Questions: qList,
		Config: models.ExamConfig{
			AllowWifi: false,
			RandomizeOrder: true,
			ShowResult: false,
		},
	}

	payloadBytes, _ := json.Marshal(payload)

	// 2. Enkripsi Payload
	ivHex, ciphertextB64, err := crypto.EncryptAES(string(payloadBytes), masterKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Encryption failed"})
		return
	}

	// 3. Update Header dengan IV
	header.EncryptionIV = ivHex
	header.Version += 1

	// 4. Hitung Signature (HMAC) dari Header + Ciphertext
	// Sederhana: sign string "examID.version.ciphertext"
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
	filePath := filepath.Join("storage", "exams", filename)
	
	if err := os.WriteFile(filePath, pkgBytes, 0644); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to write file"})
		return
	}

	// 7. Update status ujian (di memory/DB)
	exams[examID] = header

	// Return URL download (simulasi)
	downloadURL := fmt.Sprintf("http://localhost:8080/files/%s", filename)
	c.JSON(http.StatusOK, gin.H{
		"message": "Exam published",
		"file_url": downloadURL,
		"file_path": filePath,
	})
}
