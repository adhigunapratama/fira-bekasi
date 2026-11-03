FRIDA v1.2 — Account Security

Fitur:
1. Profil Saya tersedia untuk seluruh role (Super Admin, Manager, SF).
2. Menampilkan nama, email, dan role.
3. Ganti Password: memverifikasi password saat ini dengan sign-in ulang, memeriksa konfirmasi, lalu menggunakan Supabase Auth updateUser.
4. Lupa Password: mengirim email pemulihan melalui Supabase Auth.
5. Tautan email diarahkan kembali ke URL GitHub Pages aplikasi dengan parameter ?reset=1.
6. Pengguna membuat password baru dan sesi pemulihan ditutup setelah berhasil.

PENTING — KONFIGURASI SUPABASE SEBELUM UJI:
Di Supabase Dashboard > Authentication > URL Configuration:
- Pastikan Site URL mengarah ke URL GitHub Pages FRIDA.
- Tambahkan URL berikut ke Redirect URLs:
  https://adhigunapratama.github.io/fira-bekasi/?reset=1
  https://adhigunapratama.github.io/fira-bekasi/
Jika URL aplikasi GitHub Pages berubah, perbarui Redirect URLs sesuai URL aktif.

Deploy:
1. Backup index.html di GitHub.
2. Upload index.html dari paket ini ke root repository, menggantikan versi sebelumnya.
3. Commit changes dan tunggu GitHub Pages selesai deploy.
4. Tes Ganti Password dengan akun uji terlebih dahulu.
5. Tes Lupa Password menggunakan email yang bisa diakses dan periksa Inbox/Spam.

Catatan:
- Tidak ada password yang ditampilkan atau disimpan oleh aplikasi.
- Pengiriman email reset bergantung pada konfigurasi SMTP/email Supabase dan kuota email proyek.
- Jangan menguji reset pertama kali dengan akun Super Admin utama; gunakan akun dummy dahulu.
