package database

import (
	"log"
	"os"
	"exam-system-backend/models"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var DB *gorm.DB

func Connect() {
	var err error
	if err := os.MkdirAll("data", 0755); err != nil {
		log.Fatal("Failed to create data directory:", err)
	}

	DB, err = gorm.Open(sqlite.Open("data/exam.db"), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	log.Println("Database connected successfully")

	// Auto Migrate
	err = DB.AutoMigrate(
		&models.ExamHeader{}, 
		&models.Question{}, 
		&models.Option{},
		&models.ExamResult{}, // Added ExamResult
	)
	if err != nil {
		log.Fatal("Failed to migrate database:", err)
	}
}
