package models

import "time"

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
