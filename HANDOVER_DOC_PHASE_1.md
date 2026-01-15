# Dokumen Serah Terima: Fase 1 (Hardening & Operational Readiness)

**Tanggal:** 2026-01-16  
**Status:** Siap untuk UAT (User Acceptance Testing)  
**Prioritas:** Critical (Showstopper Fixes)

## 1. Ringkasan Eksekutif
Fase ini mengubah status proyek dari "Prototipe Rapuh" menjadi "Sistem Siap Lapangan". Fokus utama adalah persistensi data (agar data tidak hilang saat restart), keamanan dasar (agar siswa tidak mudah curang), dan mekanisme pemulihan bencana (manual export).

---

## 2. Spesifikasi Pengiriman (Deliverables)

### A. Backend Service (v1.1.0)
*   **Perubahan Utama:**
    *   Migrasi dari In-Memory Map ke **SQLite Database** (via GORM).
    *   Implementasi **Admin Auth Middleware** untuk endpoint guru.
    *   Konfigurasi via `.env` (tidak ada lagi hardcoded keys).
*   **Lokasi:** `d:\negun\backend\`
*   **Spesifikasi Teknis:**
    *   Database: `exam.db` (SQLite file).
    *   Port: 8080 (Default).
    *   Security: Header `X-Admin-Secret` wajib untuk operasi tulis.

### B. Mobile Application (v1.0.1)
*   **Perubahan Utama:**
    *   **Offline Gatekeeper:** Deteksi koneksi internet aktif dengan layar kunci paksa.
    *   **Secure Autosave:** Penyimpanan jawaban terenkripsi lokal setiap 10 detik.
    *   **Dashboard UI:** Pemisahan tab Online/Offline dan status Upload.
    *   **Manual Export:** Fitur "Share" file `.ans` via WhatsApp/Bluetooth.
*   **Lokasi:** `d:\negun\mobile\`
*   **Platform:** Android (Tested), iOS (Code-ready).

### C. Web Admin (v1.1.0)
*   **Perubahan Utama:**
    *   Input "Admin Secret" untuk autentikasi ke backend.
    *   Perbaikan alur UX pembuatan soal.
*   **Lokasi:** `d:\negun\web_admin\index.html`

---

## 3. Kriteria Penerimaan (Acceptance Criteria)

Untuk menyatakan fase ini selesai, pengujian berikut harus lulus:

### Skenario 1: Ketahanan Data (Backend)
- [ ] Jalankan Backend -> Buat Ujian Baru.
- [ ] Matikan Backend (Ctrl+C) -> Nyalakan lagi.
- [ ] **Pass:** Data ujian yang dibuat sebelumnya masih ada dan bisa diakses.

### Skenario 2: Keamanan Ujian (Mobile)
- [ ] Buka Aplikasi -> Download Ujian.
- [ ] Matikan Internet -> Masuk Ujian.
- [ ] Di tengah ujian, nyalakan WiFi/Data.
- [ ] **Pass:** Muncul layar merah "UJIAN DIHENTIKAN" dan tidak bisa lanjut sampai internet mati.

### Skenario 3: Pemulihan Bencana (Mobile)
- [ ] Kerjakan ujian -> Klik "Selesai".
- [ ] Matikan server backend (simulasi server down).
- [ ] Coba Upload -> Gagal.
- [ ] Klik icon "Share" pada item yang gagal.
- [ ] **Pass:** File `.ans` berhasil dikirim ke aplikasi lain (misal: WA/File Manager).

### Skenario 4: Keamanan Admin (Web)
- [ ] Buka Web Admin -> Kosongkan kolom "Admin Secret".
- [ ] Coba buat ujian.
- [ ] **Pass:** Muncul pesan error "Unauthorized" atau "Gagal".

---

## 4. Panduan Menjalankan (Run Guide)

### Backend
```bash
cd backend
go mod tidy
go run main.go
# Server akan jalan di :8080 dan membuat file exam.db
```

### Web Admin
Buka file `web_admin/index.html` langsung di browser.
*   Masukkan Secret Default: `rahasia_guru_123` (sesuai .env).

### Mobile App
```bash
cd mobile
flutter pub get
flutter run
# Pastikan emulator/device satu jaringan dengan backend
# (Edit baseUrl di api_service.dart jika pakai device fisik)
```

---

## 5. Catatan Rilis & Batasan (Known Limitations)
1.  **Database:** Menggunakan SQLite yang cocok untuk < 5000 concurrent users. Untuk skala lebih besar, ganti driver ke PostgreSQL di `db.go`.
2.  **Upload:** Fitur upload otomatis di dashboard mobile masih mock logic (mengandalkan Share Manual sebagai fallback utama saat ini).
3.  **iOS:** Fitur Guided Access perlu diaktifkan manual oleh user (OS Limitation).
