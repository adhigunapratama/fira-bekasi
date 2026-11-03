FRIDA v1.3 — Logo Resmi & Login Tanpa Konfirmasi Email

ISI PAKET
- index.html: aplikasi berdasarkan FRIDA v1.2 Account Security.
- assets/frida-logo.png: logo asli yang dikirim pengguna, tidak digambar ulang.

PERUBAHAN
1. Kartu login menggunakan logo FRIDA asli.
2. Pemeriksaan email_confirmed_at di aplikasi dihilangkan.
3. Pesan registrasi menjelaskan akun menunggu persetujuan Manager.
4. Pemeriksaan profiles.account_status = 'approved' tetap dipertahankan.
5. Fitur v1.2 seperti Profil Saya, ganti password, dan lupa password dipertahankan.

LANGKAH WAJIB DI SUPABASE SEBELUM UJI REGISTRASI BARU
1. Buka Supabase Dashboard → Authentication → Sign In / Providers (atau Providers) → Email.
2. Nonaktifkan opsi Confirm email.
3. Simpan perubahan.

CATATAN KEAMANAN
- Pengaturan Confirm email berlaku global untuk provider Email pada proyek Supabase.
- Email tetap dipakai sebagai identitas login, tetapi bukan lagi faktor aktivasi.
- Akses aplikasi tetap dikunci oleh profiles.account_status = 'approved'.
- Jangan pernah memasukkan service_role key ke index.html atau GitHub Pages.
- Role dan status harus tetap dikendalikan database/RLS, bukan form publik.

CARA DEPLOY
Unggah seluruh isi ZIP ke root repository GitHub Pages dengan struktur:
  index.html
  assets/frida-logo.png

UJI SETELAH DEPLOY
1. Buka aplikasi dengan hard refresh / hapus cache.
2. Registrasikan SF dummy menggunakan email baru.
3. Pastikan profil baru berstatus pending.
4. Coba login sebelum disetujui: akun harus tertahan dan tidak dapat membuka peta.
5. Setujui akun dari Manajemen sebagai Manager.
6. Login lagi: harus bisa masuk sebagai Sales Force tanpa konfirmasi email.
7. Uji akun Gugun (tesgugun@gmail.com) dan akun SF testing yang sudah ada.

AKUN LAMA YANG BELUM TERKONFIRMASI
Setelah Confirm email dinonaktifkan, uji akun Gugun. Perilaku akun lama yang sebelumnya belum terkonfirmasi tetap perlu diverifikasi pada proyek ini. Jika Supabase Auth masih menolak akun lama, jangan ubah role/status; hentikan dan lakukan penanganan admin yang aman.

BATAS PENGUJIAN
Paket ini diperiksa untuk konsistensi patch dan struktur file. Pengujian browser langsung terhadap Supabase produksi belum dilakukan. Uji bertahap sebelum dipakai operasional.
