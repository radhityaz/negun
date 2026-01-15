# Matriks Penilaian — Keamanan vs Biaya vs Kompleksitas (Sistem Ujian BYOD)

Dokumen ini membantu memilih pendekatan yang paling masuk akal untuk sekolah tanpa server/infrastruktur.

## 1) Kriteria & Bobot
Skor 1–5 (1 buruk, 5 bagus). Total = Σ(bobot × skor).

| Kriteria | Bobot | Definisi ringkas |
|---|---:|---|
| Biaya operasional bulanan | 25% | 5 = nol, 1 = mahal/berulang |
| Kelayakan tanpa infrastruktur sekolah | 20% | 5 = bisa jalan tanpa server/Wi‑Fi sekolah |
| Integritas ujian (anti-Google realistis) | 20% | 5 = mitigasi kuat di BYOD, 1 = lemah |
| Reliabilitas di jaringan seluler buruk | 15% | 5 = tetap jalan, 1 = sering gagal |
| Kompleksitas implementasi | 10% | 5 = sederhana, 1 = rumit |
| Kompleksitas operasional (hari-H) | 10% | 5 = mudah dijalankan, 1 = rawan kacau |

## 2) Matriks Opsi Arsitektur
### 2.1 Opsi A — Offline Exam Package + Pengumpulan File (tanpa server)
| Kriteria | Bobot | Skor | Nilai |
|---|---:|---:|---:|
| Biaya operasional bulanan | 25% | 5 | 1.25 |
| Kelayakan tanpa infrastruktur sekolah | 20% | 5 | 1.00 |
| Integritas ujian (anti-Google realistis) | 20% | 3 | 0.60 |
| Reliabilitas di jaringan seluler buruk | 15% | 5 | 0.75 |
| Kompleksitas implementasi | 10% | 3 | 0.30 |
| Kompleksitas operasional (hari-H) | 10% | 3 | 0.30 |
| **Total** |  |  | **4.20 / 5** |

Catatan:
- Integritas tidak sempurna (HP kedua), tapi bisa ditingkatkan dengan kiosk (Android), guided access (iOS), randomisasi, dan aturan offline gate.
- Operasional butuh SOP pengumpulan file dan import massal.

### 2.2 Opsi B — Hotspot Proktor sebagai “Collector” Lokal (tanpa internet)
| Kriteria | Bobot | Skor | Nilai |
|---|---:|---:|---:|
| Biaya operasional bulanan | 25% | 5 | 1.25 |
| Kelayakan tanpa infrastruktur sekolah | 20% | 4 | 0.80 |
| Integritas ujian (anti-Google realistis) | 20% | 3 | 0.60 |
| Reliabilitas di jaringan seluler buruk | 15% | 4 | 0.60 |
| Kompleksitas implementasi | 10% | 2 | 0.20 |
| Kompleksitas operasional (hari-H) | 10% | 2 | 0.20 |
| **Total** |  |  | **3.65 / 5** |

Catatan:
- Tidak butuh internet, tapi butuh manajemen hotspot/SSID dan kemungkinan keterbatasan jumlah klien per hotspot.
- Implementasi “collector” dan protokol submit lokal menambah kompleksitas.

### 2.3 Opsi C — Server On-Prem + Tunnel (jika sekolah punya internet untuk server)
| Kriteria | Bobot | Skor | Nilai |
|---|---:|---:|---:|
| Biaya operasional bulanan | 25% | 4 | 1.00 |
| Kelayakan tanpa infrastruktur sekolah | 20% | 2 | 0.40 |
| Integritas ujian (anti-Google realistis) | 20% | 4 | 0.80 |
| Reliabilitas di jaringan seluler buruk | 15% | 3 | 0.45 |
| Kompleksitas implementasi | 10% | 3 | 0.30 |
| Kompleksitas operasional (hari-H) | 10% | 3 | 0.30 |
| **Total** |  |  | **3.25 / 5** |

Catatan:
- Butuh internet sekolah stabil untuk server; ini sering jadi bottleneck.
- Integritas bisa lebih kuat karena ada monitoring terpusat, tetapi tetap BYOD.

## 3) Matriks Klien (Mobile) untuk BYOD
### 3.1 Flutter vs React Native vs PWA
Kriteria fokus: offline storage, konsistensi UI, akses kemampuan OS (kiosk/guided access flow), dan performa.

| Opsi | Biaya | Offline | Akses OS | Kompleksitas | Rekomendasi |
|---|---:|---:|---:|---:|---|
| Flutter | 5 | 5 | 4 | 3 | **Utama** (1 codebase, offline kuat) |
| React Native | 5 | 4 | 3 | 3 | Alternatif (tergantung tim) |
| PWA/Web | 5 | 2 | 1 | 4 | Hanya fallback (lockdown lemah) |

## 4) Matriks Backend (Jika Kelak Butuh Sinkronisasi Terpusat)
| Opsi | Performa | Kecepatan delivery | Kemudahan hiring | Catatan |
|---|---:|---:|---:|---|
| Go | 4 | 5 | 4 | Cocok untuk backend sederhana dan cepat jadi |
| Rust | 5 | 3 | 2 | Performa tinggi, tapi delivery lebih berat |

## 5) Keputusan Default yang Disarankan
- Arsitektur: **Opsi A (Offline package + pengumpulan file)** sebagai baseline.
- Client: **Flutter**.
- Backend: opsional; jika perlu, mulai dari **Go + Postgres**.

