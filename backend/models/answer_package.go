package models

import (
	"time"
)

// AnswerPackage adalah struktur file .ans yang diupload siswa
type AnswerPackage struct {
	Header    AnswerHeader `json:"header"`
	Payload   string       `json:"payload"`   // Encrypted JSON of AnswerPayload
	Signature string       `json:"signature"` // Hash/Signature of payload
}

type AnswerHeader struct {
	ExamID      string    `json:"exam_id"`
	StudentID   string    `json:"student_id"`
	AttemptID   string    `json:"attempt_id"`
	DeviceID    string    `json:"device_id"`
	SubmitTime  time.Time `json:"submit_time"`
	IV          string    `json:"iv"`
}

type AnswerPayload struct {
	Answers []AnswerItem `json:"answers"`
	Logs    []AuditLog   `json:"logs"`
}

type AnswerItem struct {
	QuestionID string      `json:"q_id"`
	Answer     interface{} `json:"ans"` // string or []string
	TimeSpent  int         `json:"time_spent_sec"`
}

type AuditLog struct {
	Event     string    `json:"event"` // "app_focus_lost", "wifi_on"
	Timestamp time.Time `json:"ts"`
}

// DB Model for storing Results
type ExamResult struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	ExamID      string    `json:"exam_id"`
	StudentID   string    `json:"student_id"`
	AttemptID   string    `json:"attempt_id"`
	Score       float64   `json:"score"`
	EssayScore  float64   `json:"essay_score"`
	FinalScore  float64   `json:"final_score"`
	SubmitTime  time.Time `json:"submit_time"`
	AnswerFile  string    `json:"answer_file_path"` // Path to .ans file
	RawAnswers  string    `json:"raw_answers_json"` // Decrypted JSON (for easy viewing)
	EssayScores string    `json:"essay_scores_json"` // JSON map: q_id -> score
}
