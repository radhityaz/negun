# Backlog MVP — Sistem Ujian Offline-First (BYOD)

Backlog ini diturunkan dari [PRD.md](./PRD.md) dan [MATRICS_PENILAIAN.md](./MATRICS_PENILAIAN.md). Target MVP: ujian bisa dipakai sungguhan tanpa server sekolah.

## Definisi “Selesai” (MVP)
- Guru bisa membuat paket ujian yang valid dan membagikannya.
- Siswa bisa mengerjakan ujian offline tanpa kehilangan jawaban.
- Hasil ujian bisa dikumpulkan sebagai file terenkripsi dan diimpor massal oleh guru.
- Nilai PG otomatis keluar; esai bisa dikoreksi manual; nilai bisa diekspor.
- Pelanggaran koneksi/keluar aplikasi tercatat dan bisa direkap.

## P0 — Wajib Agar Bisa Ujian
### Mobile Siswa (Android+iOS)
- Impor paket ujian (.exam) dan validasi tanda tangan
- Render soal (PG, multi-select, isian singkat, esai)
- Autosave lokal dan resume attempt
- Gate koneksi: blok start jika online (mode wajib offline)
- Deteksi koneksi berkala saat ujian + aksi pause/lock + catat pelanggaran
- Ekspor hasil (.ans) terenkripsi + share file
- Identitas siswa (login ringan atau kode ujian + token)

### Aplikasi Guru (Desktop ringan atau Web lokal di laptop)
- Manajemen siswa/kelas (import CSV)
- Bank soal minimal (buat/edit/hapus, tag opsional)
- Rakit ujian + aturan: durasi, randomisasi, kebijakan koneksi/pelanggaran
- Generate paket ujian (.exam) + signature
- Import hasil (.ans) single dan batch
- Scoring otomatis PG/multi-select + bobot
- UI koreksi esai + rubrik sederhana
- Export nilai (CSV)
- Rekap pelanggaran (CSV)

### Kriptografi & Format File
- Definisi format .exam dan .ans (versi, checksum)
- Signature paket ujian (public key embedded di app siswa)
- Enkripsi hasil jawaban (kunci per ujian atau per siswa)
- Deteksi file korup dan pesan error yang jelas

## P1 — Sangat Disarankan untuk Hari-H Lebih Rapi
- Randomisasi varian soal per siswa (bukan hanya urutan)
- Pembatasan navigasi (per section) dan timer per section
- Mode “kunci jawaban setelah pindah halaman” (opsional)
- “Checklist proktor” di aplikasi guru (airplane mode, guided access)
- UI monitoring pengumpulan: berapa file masuk, siapa belum
- Validasi duplikasi hasil (attempt id unik)

## P2 — Fase Berikutnya (Opsional)
- Mekanisme pengumpulan via hotspot proktor (collector LAN lokal)
- Sinkronisasi terpusat ke backend (jika suatu saat ada server/VPS)
- Bank soal import (DOCX/Google Docs) dan editor yang lebih nyaman
- Analitik: pola pelanggaran, deteksi anomali sederhana
- Dukungan aksesibilitas (TTS) jika dibutuhkan

## Risiko Teknis yang Harus Dipantau di MVP
- iOS BYOD: keterbatasan lockdown; perlu SOP guided access + audit
- Enkripsi/signature: implementasi harus benar dan mudah dipulihkan jika kunci bocor
- Pengumpulan file: SOP dan UX harus sederhana agar tidak kacau saat 1000 siswa

