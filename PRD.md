# PRD — Sistem Ujian Offline-First (BYOD) dengan Anti-Koneksi Realistis

## 1) Ringkasan Produk
Platform ujian untuk sekolah dengan keterbatasan infrastruktur: tidak ada server sekolah, koneksi siswa pakai data seluler, dan kebutuhan berjalan stabil untuk ujian massal. Solusi utama adalah model **offline-first**: siswa mengerjakan ujian tanpa internet menggunakan aplikasi Android/iOS, lalu hasil dikumpulkan via file terenkripsi atau hotspot proktor (LAN lokal), sehingga tidak ada beban server puncak.

## 2) Tujuan
- Menjalankan ujian untuk 500–1000 peserta tanpa mengandalkan server sekolah.
- Mengurangi kecurangan berbasis Google dengan cara realistis untuk BYOD.
- Memudahkan guru membuat paket ujian dan memeriksa hasil.
- Menyediakan audit log agar pengawasan dan penegakan aturan bisa dilakukan.

## 3) Non-Tujuan
- Tidak menjanjikan “anti-cheat 100%” di BYOD (mis. HP kedua tetap sulit dicegah).
- Tidak membuat sistem proctoring video real-time (butuh infra besar dan mahal).

## 4) Persona & Kebutuhan
- Siswa: mengerjakan ujian lancar meski sinyal buruk, tidak kehilangan jawaban.
- Guru: membuat ujian cepat, randomisasi, koreksi esai, export nilai.
- Admin: kelola akun/kelas, reset, audit, export.
- Proktor: menjalankan prosedur sederhana untuk memastikan mode offline dan memantau pelanggaran.

## 5) Kebutuhan Fungsional
### 5.1 Siswa (Mobile Android/iOS)
- **Login**: Token offline untuk masuk ke aplikasi (bisa didapat saat online sebelumnya).
- **Download Ujian**: Mengunduh paket ujian (.exam) saat ada koneksi sebelum hari H.
- **Validasi Paket**: Cek tanda tangan digital dan integritas paket.
- **Mode Ujian (Offline Wajib)**:
  - **Start Gate**: Menolak mulai ujian jika koneksi internet aktif.
  - **Runtime Gate**: Pause/Lock ujian jika koneksi terdeteksi aktif saat pengerjaan + catat pelanggaran.
- **Pengerjaan**: Navigasi soal, autosave lokal (encrypted).
- **Submit (Finalisasi)**:
  - Mengunci jawaban menjadi file hasil (.ans) yang immutable (hash/signed).
  - Tidak bisa diubah setelah submit.
- **Upload Hasil (Online)**:
  - Setelah submit, aplikasi meminta user menyalakan internet.
  - Mengunggah file .ans ke server.
  - Mekanisme upload: Staggered (random delay), Retry, Resume (chunked/idempotent).
  - Menerima bukti upload (receipt) dari server.
- **Fallback**: Ekspor file .ans manual jika upload gagal total.

### 5.2 Guru (Web Admin)
- Manajemen kelas/siswa (import CSV).
- Bank soal: buat/edit, tag, tingkat kesulitan.
- Rakit ujian: pilih soal, randomisasi urutan soal/opsi, durasi, kebijakan koneksi, kebijakan pelanggaran, jadwal.
- Generate paket ujian (.exam) untuk dibagikan.
- Impor hasil siswa (file jawaban) untuk rekap.
- Scoring otomatis untuk objektif (PG/multi-select).
- Koreksi esai manual dengan rubrik.
- Export nilai dan rekap pelanggaran (CSV/XLSX).

### 5.3 Proktor/Monitoring (di Aplikasi Guru)
- Monitor progres pengumpulan file (berapa masuk).
- Lihat pelanggaran per siswa (koneksi online terdeteksi, exit app, idle lama).
- Filter/urutkan siswa bermasalah.

## 6) Kebutuhan Non-Fungsional
### 6.1 Reliabilitas
- Tidak boleh kehilangan jawaban saat sinyal jelek.
- Import paket dan pengerjaan harus tetap berjalan tanpa internet.
- Format file hasil harus tahan korupsi (checksum).

### 6.2 Keamanan & Integritas
- Paket ujian ditandatangani; aplikasi menolak paket tidak valid.
- Jawaban dienkripsi per siswa/per ujian untuk melindungi data.
- Audit log tidak bisa diedit tanpa terdeteksi (hash chain sederhana atau signature).
- Randomisasi per siswa untuk mengurangi kolusi.

### 6.3 Privasi
- Data minimal: identitas siswa, jawaban, log pelanggaran.
- Data disimpan lokal di perangkat guru kecuali diekspor.

### 6.4 Kinerja
- Karena mode offline, beban puncak server tidak relevan.
- Impor 1000 file hasil harus selesai dalam waktu wajar (target: < 10 menit di laptop menengah).

## 7) Kebijakan Anti-Koneksi (Anti-Google)
Konsep: “ujian wajib offline” + “pelanggaran tercatat dan berdampak”.

### 7.1 Kebijakan Default
- Start gate: tidak bisa mulai jika online.
- Runtime gate: jika online terdeteksi, ujian dipause dan tidak bisa lanjut sampai offline.
- Pelanggaran tercatat: timestamp, jenis koneksi, jumlah kejadian, durasi online.
- Guru menentukan konsekuensi: peringatan, pengurangan nilai, diskualifikasi, atau ulang.

### 7.2 Batasan OS
- Android BYOD: kiosk mode membantu mencegah buka aplikasi lain.
- iOS BYOD: Guided Access membantu, namun lebih terbatas; tetap perlu pengawasan proktor.

## 8) Format Paket Ujian & Hasil
### 8.1 Paket Ujian (.exam)
- Metadata: id ujian, durasi, aturan koneksi, kebijakan pelanggaran, versi soal.
- Konten soal: terenkripsi.
- Signature: untuk validasi keaslian.

### 8.2 Hasil Jawaban (.ans)
- Identitas minimum: siswa, ujian, attempt id.
- Jawaban: terenkripsi.
- Audit log: event + checksum/signature.

## 9) Risiko & Mitigasi
- HP kedua: mitigasi melalui desain soal (varian), pengawasan, audit log.
- iOS lockdown terbatas: mitigasi dengan Guided Access + aturan offline gate + audit.
- Distribusi paket sulit: mitigasi dengan distribusi jauh hari lewat chat atau mekanisme sebar berantai.
- Pengumpulan file kacau: mitigasi dengan format file sederhana, checklist proktor, dan aplikasi guru yang bisa batch-import.

## 10) Metode Sukses (Success Metrics)
- 99% siswa selesai tanpa kehilangan jawaban.
- < 1% file hasil gagal diimpor (dengan pesan error jelas).
- Guru bisa membuat paket ujian dalam < 30 menit untuk 40 soal.
- Rekap nilai objektif otomatis selesai < 5 menit untuk 1000 peserta.

## 11) MVP Scope
Wajib:
- Paket ujian, validasi signature, pengerjaan offline, autosave, export hasil.
- Aplikasi guru: bank soal sederhana, generate paket, impor hasil, scoring PG, koreksi esai, export nilai.
- Audit log pelanggaran koneksi dan keluar aplikasi.

Ditunda:
- WebSocket monitoring real-time massal.
- Import DOCX kompleks.
- Proctoring kamera.

