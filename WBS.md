# Work Breakdown Structure (WBS) - Sistem Ujian Offline-First (BYOD)

Dokumen ini adalah acuan kerja tunggal. Setiap langkah harus dieksekusi berurutan atau paralel sesuai dependensi.

## 1. Fondasi & Protokol Data (Hari 1)
- [x] **1.1 Definisi Struktur Data (.exam & .ans)**
    - [x] 1.1.1 Buat Struct Go untuk `ExamPackage` (Header + Encrypted Payload).
    - [x] 1.1.2 Buat Struct Go untuk `AnswerPackage` (Header + Encrypted Answers + Signature).
    - [x] 1.1.3 Porting Struct ke Dart (Flutter) agar mobile bisa baca/tulis format yang sama.
- [x] **1.2 Implementasi Kriptografi Core**
    - [x] 1.2.1 Backend: Fungsi `GenerateExamPackage(json, key) -> .exam file`.
    - [x] 1.2.2 Mobile: Fungsi `DecryptExamPackage(file, key) -> json object`.
    - [x] 1.2.3 Mobile: Fungsi `SealAnswerPackage(json, key) -> .ans file`.
    - [x] 1.2.4 Backend: Fungsi `VerifyAnswerPackage(file, key) -> valid/invalid`.

## 2. Backend Service (Hari 2-3)
- [x] **2.1 Manajemen Ujian (Guru)**
    - [x] 2.1.1 API `POST /exams` (Create Exam Metadata).
    - [x] 2.1.2 API `POST /exams/{id}/questions` (Add Questions).
    - [x] 2.1.3 API `POST /exams/{id}/publish` (Trigger generate .exam file & simpan ke storage).
- [x] **2.2 Manajemen Sesi (Siswa)**
    - [x] 2.2.1 API `GET /exams/available` (List ujian aktif).
    - [x] 2.2.2 API `GET /exams/{id}/download` (Return URL file .exam).
- [x] **2.3 Pengumpulan Hasil (Upload)**
    - [x] 2.3.1 API `POST /exams/{id}/upload-url` (Generate Pre-signed URL S3/MinIO).
    - [x] 2.3.2 API `POST /attempts/confirm` (Validasi file .ans yang sudah diupload siswa).

## 3. Aplikasi Mobile Siswa (Hari 4-6)
- [x] **3.1 Flow Persiapan (Online)**
    - [x] 3.1.1 Login Screen & Token Storage.
    - [x] 3.1.2 Dashboard: List Ujian (Fetch from API).
    - [x] 3.1.3 Download `.exam` & Validasi Integritas File lokal (Hash Check).
- [x] **3.2 Flow Ujian (Offline)**
    - [x] 3.2.1 "Exam Gate": Cek koneksi internet (Wajib Off).
    - [x] 3.2.2 Render Soal (PG/Esai) dari memori yang didekripsi.
    - [x] 3.2.3 Autosave Logic: Simpan jawaban ke encrypted local storage tiap 10 detik.
    - [x] 3.2.4 Timer Logic: Monotonic clock countdown.
- [x] **3.3 Flow Submit & Upload**
    - [x] 3.3.1 Finalize Attempt: Generate file `.ans` immutable.
    - [x] 3.3.2 Upload Manager: Queue upload, retry logic, resume capability.
    - [x] 3.3.3 Receipt Display: Tampilkan kode unik bukti submit.

## 4. Web Admin Guru (Hari 7)
- [x] **4.1 Bank Soal UI**
    - [x] 4.1.1 Form input soal sederhana.
    - [x] 4.1.2 Tombol "Publish" yang memanggil API Backend.
- [x] **4.2 Monitoring & Grading**
    - [x] 4.2.1 Tabel status submit siswa (Real-time update dari backend).
    - [ ] 4.2.2 Detail jawaban siswa & Input nilai esai.

## 5. Dokumentasi & Tutorial (Hari 8)
- [x] **5.1 Panduan Guru**
    - [x] 5.1.1 Cara buat soal & publish.
    - [x] 5.1.2 Cara rekap nilai & export Excel.
- [x] **5.2 Panduan Siswa**
    - [x] 5.2.1 Cara download ujian (di rumah).
    - [x] 5.2.2 Cara mengerjakan (mode airplane).
    - [x] 5.2.3 Cara upload (setelah selesai).
