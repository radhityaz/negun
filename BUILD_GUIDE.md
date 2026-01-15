# Panduan Build Aplikasi (APK & IPA)

Karena environment saat ini tidak memiliki Flutter SDK terinstall, Anda perlu melakukan build di mesin lokal Anda (laptop developer).

## 1. Persiapan Build (Sekali Saja)
Pastikan Flutter SDK sudah terinstall dan `flutter doctor` aman.

### Android
```bash
flutter config --enable-android
```
Pastikan Anda punya Keystore untuk signing (jika untuk rilis Google Play), atau gunakan default debug/profile key untuk tes internal.

### iOS (Butuh macOS)
```bash
flutter config --enable-ios
```
Pastikan Xcode terinstall.

## 2. Build Android APK
Jalankan perintah ini di terminal folder `mobile/`:

```bash
cd mobile
flutter build apk --release
```

Hasil file APK ada di:
`mobile/build/app/outputs/flutter-apk/app-release.apk`

-> **File inilah yang Anda bagikan ke siswa (via WA/ShareIt).**

## 3. Build iOS IPA (Untuk Sideloading / AltStore)
Solusi terbaik untuk distribusi iOS gratis (valid 7 hari, cukup untuk masa ujian) adalah menggunakan **Sideloading**.

### A. Build IPA Unsigned
Di Mac (wajib macOS), jalankan:
```bash
cd mobile
flutter build ios --release --no-codesign
```
Lalu bungkus `Runner.app` menjadi IPA:
```bash
mkdir Payload
mv build/ios/iphoneos/Runner.app Payload
zip -r ExamApp_Unsigned.ipa Payload
```

### B. Cara Install ke iPhone Siswa (Metode AltStore)
Metode ini memanfaatkan Apple ID gratis siswa untuk menandatangani aplikasi secara mandiri (Self-Signing).

**Persiapan Sekolah:**
1. Siapkan 1 Laptop (Windows/Mac) sebagai "Station Install".
2. Install **AltServer** di laptop tersebut (Download di [altstore.io](https://altstore.io)).

**Proses Install (H-1 Ujian):**
1. Siswa membawa iPhone + Kabel Data ke Station Install.
2. Colok iPhone ke Laptop.
3. Jalankan AltServer -> "Install AltStore" -> Pilih HP Siswa.
4. Login pakai Apple ID Siswa (aman, langsung ke Apple).
5. AltStore muncul di HP Siswa.
6. Copy file `ExamApp_Unsigned.ipa` ke HP Siswa (AirDrop/WA).
7. Buka AltStore di HP -> My Apps -> Klik (+) -> Pilih `ExamApp_Unsigned.ipa`.
8. **SELESAI**. Aplikasi terinstall native dan valid selama 7 hari.

**Catatan:**
- Setelah 7 hari, aplikasi tidak bisa dibuka (Expire).
- Jika ujian > 7 hari, siswa harus "Refresh" app di AltStore (butuh koneksi ke Laptop Station lagi).
- Ini solusi paling robust tanpa biaya $99.
