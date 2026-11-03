FRIDA v1.4 — PAKET REVISI
THCO KABUPATEN BEKASI
==============================================

ISI PAKET
- index.html                         Aplikasi web FRIDA v1.4
- assets/frida-logo.png              Logo resmi FRIDA
- supabase/migrations/001_frida_v14.sql
                                      Migrasi SQL Supabase
- supabase/functions/sf-login/index.ts
                                      Edge Function login dengan ID SF
- supabase/config.toml               Konfigurasi Edge Function
- index_v1.3_backup.html             Salinan sumber v1.3 untuk pembanding

FITUR YANG DIREVISI DI APLIKASI
1. Form login menerima Email atau ID SF.
2. Registrasi mewajibkan Nama, ID SF, Email, dan Password.
3. ID SF dinormalisasi ke huruf kapital; nomor HP opsional tetapi divalidasi bila diisi.
4. Profil dengan status pending, rejected, dan disabled mendapat tampilan pesan berbeda dan tidak masuk ke peta.
5. Menu Manajemen menampilkan daftar persetujuan dengan tombol Setujui dan Tolak.
6. Menu Manajemen menampilkan daftar SF non-pending, termasuk email dan status akun.
7. Manager/Super Admin dapat menonaktifkan SF yang approved dan mengaktifkan kembali SF yang disabled.
8. Pengambilan ODP memakai pagination 1.000 baris per permintaan agar dapat melewati batas 1.000 baris PostgREST.
9. Pencarian koordinat menerima format latitude, longitude; pemisah koma/titik koma/spasi dan tanda kurung opsional.
10. Logo resmi tetap diambil dari assets/frida-logo.png.

PENTING SEBELUM APLIKASI DIPUBLIKASIKAN
Paket ini belum terhubung ke Supabase produksi dan belum diuji langsung di browser/perangkat. Lakukan langkah database dan Edge Function di bawah terlebih dahulu. Login Email tetap dapat dipakai tanpa Edge Function; login ID SF baru berfungsi setelah Edge Function berhasil di-deploy.

LANGKAH 1 — AUDIT DUPLIKASI ID SF
Di Supabase Dashboard > SQL Editor, jalankan query ini terlebih dahulu:

SELECT upper(btrim(p.employee_id)) AS id_sf,
       count(*) AS jumlah_akun,
       string_agg(u.email, ', ' ORDER BY u.email) AS daftar_email
FROM public.profiles p
LEFT JOIN auth.users u ON u.id = p.id
WHERE p.employee_id IS NOT NULL AND btrim(p.employee_id) <> ''
GROUP BY upper(btrim(p.employee_id))
HAVING count(*) > 1;

Jika hasilnya kosong, lanjut ke Langkah 2.
Jika ada hasil, tentukan akun mana yang benar dan perbaiki ID SF akun dummy/duplikat terlebih dahulu. Jangan menghapus atau mengganti ID akun asli tanpa memastikan pemiliknya.

LANGKAH 2 — JALANKAN MIGRASI SQL
- Buka file supabase/migrations/001_frida_v14.sql.
- Salin seluruh isinya ke Supabase Dashboard > SQL Editor.
- Jalankan setelah duplikasi ID SF sudah dibereskan.
- Migrasi membuat unique index employee_id, fungsi daftar email SF khusus Manager/Super Admin, dan memperbarui urutan stabil RPC radius untuk pagination.

LANGKAH 3 — DEPLOY EDGE FUNCTION sf-login
Edge Function diperlukan agar login ID SF dapat mencari akun dan memverifikasi password tanpa membuka alamat email akun ke browser.

A. Buat/deploy function dengan nama: sf-login
B. Gunakan kode dari: supabase/functions/sf-login/index.ts
C. Pastikan function memakai konfigurasi verify_jwt = false dari supabase/config.toml karena fungsi ini dipanggil sebelum pengguna login.
D. Tambahkan Secrets/Environment Variables pada Supabase Edge Functions:
   SUPABASE_URL
   SUPABASE_ANON_KEY
   SUPABASE_SERVICE_ROLE_KEY

CATATAN KEAMANAN:
- SUPABASE_SERVICE_ROLE_KEY hanya boleh disimpan sebagai Secret di sisi server/Edge Function.
- Jangan pernah menaruh service_role key di index.html, GitHub, atau browser.
- Jangan mengganti publishable/anon key aplikasi dengan service_role key.

LANGKAH 4 — PASANG APLIKASI DI GITHUB PAGES
- Buat backup file index.html dan folder assets yang sedang live.
- Upload index.html dari paket v1.4 ke root repository.
- Pastikan assets/frida-logo.png tetap berada di folder assets.
- Folder supabase tidak perlu diunggah ke root GitHub Pages; folder itu berisi source dan konfigurasi backend.
- Setelah upload, tunggu deployment GitHub Pages selesai lalu buka aplikasi dan lakukan hard refresh.

LANGKAH 5 — URUTAN PENGUJIAN SETELAH DEPLOY
1. Login Manager dengan email.
2. Login Super Admin dengan email.
3. Login SF dengan ID SF dan password.
4. Login SF dengan email dan password.
5. Registrasi dengan ID SF kosong — harus ditolak.
6. Registrasi dengan ID SF yang sudah dipakai — harus ditolak.
7. Registrasi dengan nomor HP tidak valid — harus ditolak; nomor HP kosong tetap boleh.
8. Manager menyetujui pendaftaran SF.
9. Manager menolak pendaftaran SF; akun harus tidak bisa masuk ke peta.
10. Manager menonaktifkan SF approved; akun harus tidak bisa masuk ke peta.
11. Manager mengaktifkan kembali akun disabled.
12. Radius 5 km dengan jumlah ODP di atas 1.000; cek total dan komposisi status.
13. Pencarian koordinat contoh: -6.23397, 107.08147 (gunakan titik yang diketahui berada di Kabupaten Bekasi).
14. Pastikan rute, GPS, peta, detail ODP, dan lupa password tetap berfungsi.

HASIL PEMERIKSAAN STATIS PAKET
- JavaScript inline diperiksa dengan Node.js --check dan tidak ditemukan kesalahan sintaks.
- Ini bukan pengganti uji browser dan uji integrasi Supabase. Seluruh langkah pengujian setelah deployment tetap wajib dilakukan.

==============================================
FRIDA v1.4 — DRAFT REVISI SIAP DIUJI
