# ALPEN — Aplikasi Layanan Pensiun

Flutter app dengan alur splash, login, pendaftaran, reset kata sandi (OTP),
onboarding data diri/keluarga, serta dashboard terpisah untuk user dan admin.

## Menjalankan

URI MongoDB untuk aplikasi pribadi ini telah tertanam di aplikasi, sehingga
cukup jalankan:

```powershell
flutter run
```

Untuk menampilkan OTP hanya saat pengembangan, tambahkan
`--dart-define=SHOW_OTP=true`. Untuk pengiriman email, tambahkan
`SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, dan `SMTP_SENDER`
sebagai `--dart-define`. Dalam produksi kode OTP disimpan dalam koleksi
`password_otps` dengan masa berlaku 10 menit. Jangan mengirim email langsung
dari APK produksi karena kredensial pengirim akan mudah diekstrak; sebaiknya
pindahkan pengiriman OTP ke layanan backend tepercaya.

Koleksi MongoDB yang digunakan:

- `users`: akun, role (`user`/`admin`), hash kata sandi, profil dan keluarga.
- `password_otps`: hash kode reset kata sandi yang memiliki waktu kedaluwarsa.

APK debug hasil verifikasi tersedia di
`build/app/outputs/flutter-apk/app-debug.apk`.
