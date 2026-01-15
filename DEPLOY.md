# Cara Melihat Hasil & Deploy

Dokumen ini menjelaskan cara menjalankan sistem secara lokal dan cara deploy sederhana.

## 1) Jalankan Lokal (Tanpa Docker)

### Backend (Go)
Prasyarat: Go terinstal.

```bash
cd backend
go mod tidy
go run .
```

Backend berjalan di `http://localhost:8080`.

### Web Admin
Opsi paling simpel:
- Buka file `web_admin/index.html` langsung di browser, atau
- Jalankan server static (opsional).

Di Web Admin:
- Set **API** ke `http://localhost:8080/api/v1`
- Set **Admin Secret** sesuai `backend/.env` (`ADMIN_SECRET`)

## 2) Jalankan Lokal Pakai Docker (Recommended)
Prasyarat: Docker + Docker Compose.

Di root project:

```bash
docker compose up --build
```

- Backend: `http://localhost:8080`
- Web Admin: `http://localhost:8081`

Konfigurasi backend dibaca dari `backend/.env`.

## 3) Test Cepat End-to-End
1. Buka Web Admin `http://localhost:8081`
2. Isi **API** = `http://localhost:8080/api/v1`
3. Isi **Admin Secret**
4. Buat ujian → tambah soal (pilih jawaban benar untuk PG) → publish
5. Dari mobile: download `.exam` → kerjakan offline → submit → upload
6. Kembali ke Web Admin → tab **Hasil & Penilaian** → refresh

## 4) Deploy Sederhana ke VPS
Rekomendasi paling aman untuk MVP: deploy di VPS pakai Docker.

Langkah umum:
1. Install Docker + Compose di VPS
2. Upload/copy repo ke VPS
3. Edit `backend/.env` (ganti `MASTER_KEY` dan `ADMIN_SECRET`)
4. Jalankan:

```bash
docker compose up --build -d
```

Catatan:
- Untuk HTTPS dan domain, letakkan reverse proxy (mis. Nginx/Caddy) di depan `:8080` dan `:8081`.
- SQLite cocok untuk MVP; kalau sudah multi-instance atau butuh HA, pindahkan DB ke Postgres.

## 5) Mobile (Android Emulator vs HP Fisik)
File: `mobile/lib/services/api_service.dart`

- Emulator Android: gunakan `10.0.2.2:8080`
- HP fisik: ganti ke IP laptop/VM Anda (contoh `http://192.168.1.10:8080`)
