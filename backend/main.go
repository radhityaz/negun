package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/cors"
	"github.com/joho/godotenv"
	"exam-system-backend/handlers"
	"exam-system-backend/database"
	"exam-system-backend/middleware"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using default env vars")
	}

	database.Connect()

	r := gin.Default()

	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "X-Admin-Secret"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	r.Static("/files", "./storage/exams")

	// Setup Routes
	api := r.Group("/api/v1")
	{
		
		api.POST("/exams", middleware.AdminAuth(), handlers.CreateExam)
		api.POST("/exams/:examId/questions", middleware.AdminAuth(), handlers.AddQuestion)
		api.POST("/exams/:examId/publish", middleware.AdminAuth(), handlers.PublishExam)
		api.GET("/results", middleware.AdminAuth(), handlers.ListResults)
		api.GET("/results/:id", middleware.AdminAuth(), handlers.GetResult)
		api.GET("/results/:id/detail", middleware.AdminAuth(), handlers.GetResultDetail)
		api.POST("/results/:id/essay-scores", middleware.AdminAuth(), handlers.SetEssayScores)

		api.POST("/auth/login", AuthLogin)
		api.GET("/exams/available", handlers.ListAvailableExams)
		api.POST("/exams/:examId/upload-url", handlers.GetUploadURL)
		
		api.POST("/attempts/upload/:attemptId", handlers.UploadAnswerHandler)
		api.POST("/attempts/confirm", handlers.ConfirmAttempt)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("Server starting on :" + port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func AuthLogin(c *gin.Context) {
	// TODO: Implement DB check
	c.JSON(http.StatusOK, gin.H{"token": "dummy-jwt-token", "user": gin.H{"id": "1", "role": "student"}})
}
