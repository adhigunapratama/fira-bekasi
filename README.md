# FIRA Web App v0.5 — Supabase-connected starter

## Konfigurasi
Project URL dan Publishable Key sudah dipasang pada `index.html` berdasarkan nilai yang diberikan pemilik project. Publishable key memang untuk frontend; jangan pernah menambahkan secret/service_role key ke file ini.

## Jalankan lokal
Dari folder ini:
`python -m http.server 8000`
Buka `http://localhost:8000`.

## Fitur yang sudah disambungkan
- Registrasi SF (profil otomatis `pending` dari trigger database).
- Login email/password.
- Akun pending ditahan dari akses peta sampai Manager menyetujui.
- Panel persetujuan Manager/Super Admin.
- Catat sesi login/logout.
- Ambil ODP dari RPC `odps_within_radius` sesuai pusat dan radius, tidak mengunduh seluruh 29 ribu record.
- Marker sesuai STATUS 2: Black, Green, Yellow, Orange, Red.
- Profil ODP dasar dan tombol navigasi Google Maps.
- Footer: Developed by THCO Kabupaten Bekasi — 2026.

## Sebelum uji
1. Pastikan SQL foundation v0.4 sudah dijalankan.
2. Di Supabase Authentication > URL Configuration, tambahkan URL hosting lokal/produksi ke Site URL dan Redirect URLs sesuai lokasi deploy.
3. Untuk testing email, konfirmasi email dapat tetap aktif; pengguna perlu mengonfirmasi email sebelum login.
4. Buat akun pertama, lalu jalankan query promosi Super Admin dari SQL setup (ganti email sendiri).
5. Jangan gunakan service_role/secret key di browser.

## Batasan versi 0.5
- Pemilihan titik manual belum divalidasi dengan polygon resmi Kabupaten Bekasi.
- Routing jalan kaki belum terhubung; tombol membuka navigasi Google Maps.
- Belum ada layer batas kecamatan.
- Panel approval saat ini menyediakan persetujuan; penolakan/nonaktifkan dapat dilakukan melalui RPC yang sudah disediakan dan akan dibuatkan UI lanjutan.
- Audit login/logout hanya mencatat logout bila browser dapat mengirim update; penutupan tab paksa dapat meninggalkan sesi terbuka. Untuk produksi perlu heartbeat/session-close server-side.
- Leaflet memakai tile OpenStreetMap publik; patuhi kebijakan penggunaan tile dan siapkan provider tile yang sesuai untuk skala produksi.


## v0.6 — Perbaikan titik pusat dan visual radius
- Pemilihan titik manual sekarang menampilkan marker pusat yang terpisah dari marker ODP.
- Lingkaran radius merah transparan ditampilkan dan diperbarui saat slider digeser.
- Layer titik pusat/lingkaran tidak terhapus ketika marker ODP dimuat ulang.
- Tombol Cari ODP memberi pesan jika titik pusat belum ditentukan.
- Radius pencarian tetap memakai jarak garis lurus melalui RPC Supabase.

Catatan: validasi agar titik manual benar-benar berada di dalam batas administratif Kabupaten Bekasi belum termasuk patch ini; perlu data polygon batas kabupaten yang resmi. Jangan gunakan titik manual di luar Bekasi sampai validasi batas tersebut ditambahkan.

### Cara memperbarui
1. Hentikan server lokal dengan Ctrl+C pada Command Prompt.
2. Ganti file `index.html` lama dengan `index.html` dari paket ini.
3. Jalankan kembali `python -m http.server 8000`.
4. Buka `http://localhost:8000` dan lakukan hard refresh dengan Ctrl+Shift+R.

## v0.7 — Validasi batas Kabupaten Bekasi
- Memuat polygon batas kabupaten dari layanan geospasial BIG (layer batas kabupaten/kota, Provinsi Jawa Barat).
- Menggambar garis batas Kabupaten Bekasi pada peta.
- Titik manual dan GPS hanya diterima bila berada di dalam polygon Kabupaten Bekasi.
- Jika layanan batas gagal dimuat atau polygon tidak ditemukan, pemilihan titik dikunci (fail-closed), sehingga FIRA tidak diam-diam menerima titik di luar wilayah.
- GPS otomatis diminta setelah polygon batas berhasil dimuat.

Catatan pengujian: paket ini sudah diperiksa sintaks JavaScript-nya, tetapi koneksi langsung ke layanan BIG perlu diuji dari browser/laptop pengguna. Jika layanan BIG tidak dapat diakses dari jaringan/browser, aplikasi akan menolak pemilihan titik dan menampilkan pesan kegagalan; jangan menonaktifkan validasi untuk mengakalinya.
