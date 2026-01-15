package handlers

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
)

// ListAvailableExams: Siswa melihat daftar ujian yang sudah dipublish
func ListAvailableExams(c *gin.Context) {
	// Di sistem nyata, filter berdasarkan kelas siswa
	// Untuk MVP, return semua ujian yang ada di memory
	
	type ExamResponse struct {
		ID           string `json:"id"`
		Title        string `json:"title"`
		DownloadURL  string `json:"download_url"`
		Version      int    `json:"version"`
		DurationMins int    `json:"duration_mins"`
	}

	var response []ExamResponse

	for _, exam := range exams {
		// Hanya tampilkan yang punya Version > 0 (sudah dipublish)
		if exam.Version > 0 {
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
	}

	c.JSON(http.StatusOK, response)
}

// GetUploadURL: Siswa minta link buat upload hasil .ans
func GetUploadURL(c *gin.Context) {
	examID := c.Param("examId")
	
	// Generate unique attempt ID
	attemptID := fmt.Sprintf("att-%s-%d", examID, time.Now().UnixNano())
	
	// Di produksi: Generate S3 Presigned URL
	// Di MVP: Return URL lokal backend yang handle upload
	uploadURL := fmt.Sprintf("http://localhost:8080/api/v1/attempts/upload/%s", attemptID)

	c.JSON(http.StatusOK, gin.H{
		"upload_url": uploadURL,
		"attempt_id": attemptID,
	})
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

	// TODO: Validasi signature & hash file (Integrity Check)
	// Update status di DB jadi 'submitted'

	c.JSON(http.StatusOK, gin.H{
		"status": "received",
		"receipt_code": fmt.Sprintf("RCPT-%s", req.AttemptID[len(req.AttemptID)-6:]),
	})
}
