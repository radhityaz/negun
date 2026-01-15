-- Schema Database Sistem Ujian Offline-First (BYOD)
-- Target: PostgreSQL
-- Fokus: Performa tinggi, integritas data, dan dukungan untuk upload asinkron (opsi 3)

-- Enums
CREATE TYPE user_role AS ENUM ('admin', 'teacher', 'student');
CREATE TYPE exam_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE attempt_status AS ENUM ('in_progress', 'submitted', 'verified', 'rejected');
CREATE TYPE question_type AS ENUM ('multiple_choice', 'multi_select', 'short_answer', 'essay');

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role user_role NOT NULL DEFAULT 'student',
    class_name VARCHAR(50), -- Nullable for teachers/admins
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_class ON users(class_name);

-- Exams (Metadata Ujian)
CREATE TABLE exams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    teacher_id UUID REFERENCES users(id),
    duration_minutes INT NOT NULL DEFAULT 60,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    status exam_status DEFAULT 'draft',
    settings JSONB DEFAULT '{}', -- Config: allow_wifi, random_seed, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Exam Packages (Versi file .exam yang didownload siswa)
CREATE TABLE exam_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id UUID REFERENCES exams(id) ON DELETE CASCADE,
    version INT NOT NULL,
    file_url VARCHAR(255) NOT NULL, -- URL ke Object Storage
    file_hash VARCHAR(64) NOT NULL, -- SHA-256 integrity check
    signature VARCHAR(512) NOT NULL, -- Digital signature
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_exam_packages_version ON exam_packages(exam_id, version);

-- Questions (Bank Soal - disimpan di DB untuk generate paket)
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id UUID REFERENCES exams(id) ON DELETE CASCADE,
    content TEXT NOT NULL, -- Markdown/HTML supported
    q_type question_type NOT NULL,
    options JSONB, -- Array of options for MC/Multi-select
    correct_answer JSONB, -- Encrypted or plain (depending on strategy)
    points INT DEFAULT 1,
    "order" INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Attempts (Sesi Ujian Siswa)
-- Dibuat saat siswa pertama kali lapor mulai (jika online) atau saat submit (jika full offline)
-- Untuk Opsi 3 (Offline -> Online Upload), record ini mungkin baru dibuat saat upload pertama.
CREATE TABLE attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id UUID REFERENCES exams(id),
    student_id UUID REFERENCES users(id),
    device_id VARCHAR(100), -- Device fingerprint
    start_time TIMESTAMP WITH TIME ZONE,
    submit_time TIMESTAMP WITH TIME ZONE, -- Waktu siswa klik submit di HP
    upload_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- Waktu data diterima server
    status attempt_status DEFAULT 'submitted',
    score DECIMAL(5, 2), -- Null jika belum dinilai
    integrity_log JSONB, -- Log pelanggaran (pause, disconnect, etc.)
    client_signature VARCHAR(512), -- Tanda tangan dari aplikasi siswa
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_attempts_student_exam ON attempts(student_id, exam_id);

-- Answers (Jawaban Detail)
-- Disimpan sebagai JSON blob besar per attempt untuk performa insert, 
-- atau dipecah per soal jika butuh query analitik granular.
-- Untuk performa tinggi saat upload massal: simpan JSON blob dulu.
CREATE TABLE attempt_answers (
    attempt_id UUID PRIMARY KEY REFERENCES attempts(id) ON DELETE CASCADE,
    answers_blob JSONB NOT NULL, -- { "q_id": "answer", ... }
    file_url VARCHAR(255) -- Jika file .ans disimpan utuh di object storage
);

-- Audit Logs (Keamanan & Debugging)
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
