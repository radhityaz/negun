package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"exam-system-backend/handlers"
)

func main() {
	r := gin.Default()

	// Serve static files (simulasi CDN/Storage)
	r.Static("/files", "./storage/exams")

	// Setup Routes
	api := r.Group("/api/v1")
	{
		// Teacher Routes
		api.POST("/exams", handlers.CreateExam)
		api.POST("/exams/:examId/questions", handlers.AddQuestion)
		api.POST("/exams/:examId/publish", handlers.PublishExam)

		// Student Routes
		api.POST("/auth/login", AuthLogin)
		api.GET("/exams/available", handlers.ListAvailableExams)
		api.POST("/exams/:examId/upload-url", handlers.GetUploadURL)
		api.POST("/attempts/confirm", handlers.ConfirmAttempt)
	}

	log.Println("Server starting on :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatal(err)
	}
}

func AuthLogin(c *gin.Context) {
	// TODO: Implement DB check
	c.JSON(http.StatusOK, gin.H{"token": "dummy-jwt-token", "user": gin.H{"id": "1", "role": "student"}})
}
