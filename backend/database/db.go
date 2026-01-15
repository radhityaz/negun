package database

import (
	"log"
	"exam-system-backend/models"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var DB *gorm.DB

func Connect() {
	var err error
	// Use SQLite for now (creates a file named 'exam.db')
	DB, err = gorm.Open(sqlite.Open("exam.db"), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	log.Println("Database connected successfully")

	// Auto Migrate
	err = DB.AutoMigrate(&models.ExamHeader{}, &models.Question{}, &models.Option{})
	if err != nil {
		log.Fatal("Failed to migrate database:", err)
	}
}
