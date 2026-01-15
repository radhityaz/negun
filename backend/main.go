package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	// Setup Routes
	api := r.Group("/api/v1")
	{
		api.POST("/auth/login", AuthLogin)
		api.GET("/exams/available", ListExams)
		api.POST("/exams/:examId/upload-url", GetUploadURL)
		api.POST("/attempts/confirm", ConfirmAttempt)
	}

	log.Println("Server starting on :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatal(err)
	}
}

// Stubs for handlers (Moved to handlers package in real impl, but here for single-file demo)

func AuthLogin(c *gin.Context) {
	// TODO: Implement DB check
	c.JSON(http.StatusOK, gin.H{"token": "dummy-jwt-token", "user": gin.H{"id": "1", "role": "student"}})
}

func ListExams(c *gin.Context) {
	// TODO: Return exams from DB
	c.JSON(http.StatusOK, []gin.H{
		{"id": "exam-001", "title": "Matematika Dasar", "download_url": "http://store/exam-001.exam", "hash": "sha256:abc..."},
	})
}

func GetUploadURL(c *gin.Context) {
	// TODO: Generate Pre-signed URL
	examId := c.Param("examId")
	c.JSON(http.StatusOK, gin.H{
		"upload_url": "http://store/upload/" + examId + "/attempt-xyz.ans",
		"attempt_id": "attempt-xyz",
	})
}

func ConfirmAttempt(c *gin.Context) {
	// TODO: Verify signature and update DB
	c.JSON(http.StatusOK, gin.H{"status": "received", "receipt_code": "RCPT-12345"})
}
