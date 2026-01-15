package models

import (
	"time"
)

// ExamPackage adalah struktur file .exam yang didownload siswa
type ExamPackage struct {
	Header  ExamHeader  `json:"header"`
	Payload string      `json:"payload"` // Encrypted JSON string of ExamPayload
	Signature string    `json:"signature"` // HMAC/RSA signature of Header+Payload
}

// ExamHeader berisi metadata publik (tidak terenkripsi) agar app bisa validasi awal
type ExamHeader struct {
	ExamID        string    `json:"exam_id" gorm:"primaryKey"`
	Title         string    `json:"title"`
	Version       int       `json:"version"`
	EncryptionIV  string    `json:"iv"` // Initialization Vector untuk AES
	ValidFrom     time.Time `json:"valid_from"`
	ValidUntil    time.Time `json:"valid_until"`
	DurationMins  int       `json:"duration_mins"`
	CreatedAt     time.Time `json:"created_at"`
	
	// Relation
	Questions []Question `json:"-" gorm:"foreignKey:ExamID"`
}

// ExamPayload adalah isi soal yang dienkripsi
type ExamPayload struct {
	Questions []Question `json:"questions"`
	Config    ExamConfig `json:"config"`
}

type ExamConfig struct {
	AllowWifi       bool `json:"allow_wifi"`
	RandomizeOrder  bool `json:"randomize_order"`
	ShowResult      bool `json:"show_result"`
}

type Question struct {
	ID      string   `json:"id" gorm:"primaryKey"`
	ExamID  string   `json:"exam_id"` // FK
	Type    string   `json:"type"` // "mc", "essay"
	Content string   `json:"content"` // HTML/Markdown
	Options []Option `json:"options,omitempty" gorm:"foreignKey:QuestionID"`
	Points  int      `json:"points"`
}

type Option struct {
	DBID       uint   `json:"-" gorm:"primaryKey"`
	QuestionID string `json:"-"`
	
	ID         string `json:"id" gorm:"column:option_label"` // "A", "B"
	Content    string `json:"content"`
	IsCorrect  bool   `json:"is_correct,omitempty"` 
}
