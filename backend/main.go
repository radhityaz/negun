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
	// Load Env
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using default env vars")
	}

	// Connect to DB
	database.Connect()

	r := gin.Default()

	// CORS Setup (Important for Web Admin)
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "X-Admin-Secret"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Serve static files (simulasi CDN/Storage)
	r.Static("/files", "./storage/exams")

	// Setup Routes
	api := r.Group("/api/v1")
	{
		// Teacher Routes (Protected)
		teacher := api.Group("/teacher")
		teacher.Use(middleware.AdminAuth())
		{
			// Note: We changed path slightly to group them, or we can keep existing path but wrap with middleware
			// Let's keep existing paths but use specific group if possible, or just apply middleware to specific routes.
			// But for cleaner API, let's keep original paths but apply middleware.
			// However, original paths were /exams (create).
			// Student also uses /exams (list).
			// So we should separate them or check method.
			
			// Let's refactor paths slightly to be safer.
			// POST /exams -> Create (Teacher)
			// GET /exams/available -> List (Student)
		}

		// Let's apply middleware explicitly to Teacher endpoints
		// 1. Create Exam
		api.POST("/exams", middleware.AdminAuth(), handlers.CreateExam)
		// 2. Add Question
		api.POST("/exams/:examId/questions", middleware.AdminAuth(), handlers.AddQuestion)
		// 3. Publish
		api.POST("/exams/:examId/publish", middleware.AdminAuth(), handlers.PublishExam)

		// Student Routes (Public / Student Auth)
		api.POST("/auth/login", AuthLogin)
		api.GET("/exams/available", handlers.ListAvailableExams)
		api.POST("/exams/:examId/upload-url", handlers.GetUploadURL)
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
