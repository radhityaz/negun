## Jawaban Intinya
Kalau benar-benar offline, justru tujuannya supaya **nggak bisa Google**. Tapi di BYOD, kita **nggak bisa 100% menjamin** anak tidak pakai cara lain (mis. HP kedua). Yang bisa kita lakukan adalah kombinasi **lockdown di aplikasi + aturan operasional + desain soal**.

## Mekanisme Teknis di Aplikasi (Anti-Google yang Bisa Dibuat)
### 1) Mode Ujian Wajib Tanpa Internet
- Aplikasi **menolak mulai ujian** kalau masih ada koneksi (Wi‑Fi/data aktif).
- Saat ujian berjalan, aplikasi melakukan **cek koneksi berkala**:
  - Jika koneksi terdeteksi: ujian **dipause/lock**, tampilkan instruksi “matikan data”, dan catat pelanggaran di log.
  - Setelah offline lagi, ujian bisa lanjut (atau tetap terkunci sesuai aturan guru).

### 2) Lockdown Per OS (Best Effort)
- **Android**: kiosk/lock task + blok switch app (paling efektif di BYOD).
- **iOS**: Guided Access flow + deteksi background/foreground + log pelanggaran (lebih lemah).

### 3) Audit Log untuk Pengawasan
- Catat: keluar aplikasi, koneksi terdeteksi, jumlah pause, waktu idle, submit.
- Guru punya dashboard/rekap pelanggaran untuk tindak lanjut.

## Mitigasi Operasional (Yang Murah Tapi Efektif)
- Proktor mewajibkan: **airplane mode** sebelum mulai (kamera cek cepat).
- Tempat duduk berjauhan, randomisasi soal/opsi per siswa.
- Aturan tegas: kalau log menunjukkan koneksi aktif X kali → diskualifikasi/ulang.

## Mitigasi Desain Soal (Mengurangi Keuntungan Googling)
- Bank soal besar + random per siswa.
- Soal berbasis kasus, bukan definisi.
- Angka/parameter diacak (varian per siswa).
- Waktu ketat per section, bukan hanya total.

## Pilihan Arsitektur Offline Tetap Sama
- Paket ujian terenkripsi/ditandatangani.
- Pengerjaan offline.
- Pengumpulan via file terenkripsi atau hotspot proktor.

## Deliverable Dokumen yang Akan Dibuat
1. PRD: mode offline + aturan anti-koneksi + batasan iOS BYOD
2. Matriks penilaian: tingkat keamanan vs biaya/kompleksitas (Android kuat, iOS terbatas)
3. Backlog MVP: fitur minimum untuk ujian offline yang bisa dipakai

## Langkah Berikutnya Setelah Disetujui
- Aku tulis PRD + matriks penilaian jadi dokumen, lalu breakdown backlog MVP untuk mulai implementasi.