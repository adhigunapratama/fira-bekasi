FRIDA ANDROID v1.4 — PAKET PEMBUATAN APK
THCO KABUPATEN BEKASI
========================================

STATUS PAKET
- Ini adalah proyek pembungkus Android (Capacitor), bukan file APK jadi.
- Konten aplikasi berasal dari FRIDA v1.4 Connected Login ID SF yang telah diberikan.
- URL Supabase dan publishable key tetap seperti pada aplikasi web.
- Secret key tidak disertakan dan tidak boleh dimasukkan ke aplikasi Android.
- Aplikasi web/GitHub Pages yang sekarang tetap dapat digunakan terpisah.

KOMPONEN
- www/index.html
- www/assets/frida-logo.png
- package.json
- capacitor.config.ts
- PERSIAPKAN_ANDROID.bat

PERSYARATAN KOMPUTER WINDOWS
1. Node.js 22 atau lebih baru (ikuti versi yang disyaratkan Capacitor 8).
   https://nodejs.org/
2. Android Studio versi yang kompatibel dengan Capacitor 8.
   https://developer.android.com/studio
3. Android SDK melalui Android Studio > Tools > SDK Manager.
   Pasang Android SDK Platform dan Build Tools yang direkomendasikan Android Studio.
4. Koneksi internet untuk mengunduh dependency pertama kali.

LANGKAH A — SIAPKAN PROYEK
1. Ekstrak seluruh ZIP ke folder sederhana, misalnya C:\FRIDA_Android_v1.4
2. Instal Node.js dan Android Studio.
3. Restart Windows setelah instalasi bila diminta.
4. Klik dua kali PERSIAPKAN_ANDROID.bat.
5. Tunggu npm install, npx cap add android, dan npx cap sync android selesai.
6. Jika berhasil, folder android akan terbentuk.

LANGKAH B — IZIN GPS ANDROID
Sebelum build dan uji di HP, buka:
android/app/src/main/AndroidManifest.xml
Di dalam elemen <manifest> dan di luar <application>, pastikan ada:
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

Aplikasi saat ini menggunakan navigator.geolocation pada halaman web. Karena itu izin lokasi harus diuji di perangkat Android nyata. Jika prompt GPS tidak muncul atau GPS gagal, hentikan distribusi dan lakukan penyesuaian integrasi geolocation native terlebih dahulu. Jangan menganggap GPS sudah lolos hanya karena halaman dapat terbuka.

LANGKAH C — BUKA ANDROID STUDIO
1. Jalankan Android Studio.
2. Pilih Open.
3. Pilih folder android di dalam folder proyek ini.
4. Tunggu Gradle Sync selesai. Jika diminta memasang SDK/Build Tools, ikuti rekomendasi Android Studio.
5. Jalankan ke perangkat Android melalui USB debugging untuk uji awal.

LANGKAH D — BUAT APK DEBUG UNTUK UJI INTERNAL
Setelah proyek berhasil dibuka dan diuji:
1. Android Studio > Build > Build Bundle(s) / APK(s) > Build APK(s).
2. Tunggu proses selesai.
3. Android Studio akan menampilkan lokasi APK, biasanya:
   android/app/build/outputs/apk/debug/app-debug.apk
4. Pasang APK di HP uji terlebih dahulu.
5. Jangan bagikan ke 10 SF sebelum uji login, peta, GPS, navigasi eksternal, dan alur Supabase selesai.

APK RILIS
Untuk distribusi internal yang lebih rapi, buat signed APK melalui:
Build > Generate Signed Bundle / APK > APK.
Simpan keystore dan password di tempat aman. Jangan kirim keystore/password melalui chat.
Gunakan package id id.co.thco.frida secara konsisten untuk update versi selanjutnya.

CATATAN PENTING
- Build APK belum dilakukan dari lingkungan ini karena Android SDK/Gradle dan signing key harus tersedia pada komputer Windows pemilik aplikasi.
- Paket ini belum menjadi APK siap pasang.
- Peta Leaflet, tile peta, Supabase, dan rute memakai layanan HTTPS, sehingga perangkat memerlukan internet.
- Uji GPS di perangkat fisik. Pastikan pengguna memberi izin lokasi saat aplikasi meminta.
- Jangan mengunggah secret key ke GitHub atau ke APK.
