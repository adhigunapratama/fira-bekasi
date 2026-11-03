FRIDA v1.1 — Smart Map & Management Navigation

Paket ini berisi index.html.

Perubahan:
- Branding FRIDA: Fiber Routing & Intelligence Data Assistant.
- Navigasi Peta ODP dan Manajemen dipisah.
- Menu Manajemen hanya ditampilkan bagi role manager dan super_admin.
- Panel persetujuan SF dipindahkan dari halaman peta ke halaman Manajemen.
- Radius default 500 meter, minimum 100 meter, maksimum 5 KM.
- Filter STATUS 2 multi-select; default semua warna aktif.
- Marker ODP menggunakan Leaflet MarkerCluster.
- Total ODP dan ringkasan per STATUS 2 dihitung dari hasil RPC radius yang sama.
- Login memeriksa email_confirmed_at sebelum mengizinkan akses.

Catatan:
- Paket mengasumsikan RPC odps_within_radius menerima status_filter berupa text[] atau null.
- Jika role Manager belum benar di database, menu Manajemen tidak akan muncul untuk akun tersebut.
- Jangan menetapkan role melalui form pendaftaran publik. Penetapan Manager harus dilakukan lewat jalur admin/database yang terlindungi.
- MarkerCluster memerlukan koneksi internet ke CDN unpkg.
- Simpan backup index.html lama sebelum deploy; uji dahulu, lalu hard refresh Ctrl+Shift+R.
