export async function onRequest({ env }) {
  const bucket = env.FRIDA_APK_BUCKET;
  if (!bucket) return new Response("Unduhan APK belum dikonfigurasi. Hubungkan bucket R2 FRIDA_APK_BUCKET pada pengaturan Pages.", { status: 503, headers: { "Cache-Control": "no-store", "Content-Type": "text/plain; charset=utf-8" } });
  try {
    const object = await bucket.get("frida-latest.apk");
    if (!object) return new Response("APK FRIDA belum tersedia. Jalankan build Android terbaru terlebih dahulu.", { status: 404, headers: { "Cache-Control": "no-store", "Content-Type": "text/plain; charset=utf-8" } });
    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set("Content-Type", "application/vnd.android.package-archive");
    headers.set("Content-Disposition", 'attachment; filename="FRIDA-latest.apk"');
    headers.set("Cache-Control", "private, no-store");
    headers.set("X-Content-Type-Options", "nosniff");
    if (object.httpEtag) headers.set("ETag", object.httpEtag);
    return new Response(object.body, { headers });
  } catch {
    return new Response("Gagal mengambil APK dari penyimpanan. Silakan coba lagi atau hubungi pengelola FRIDA.", { status: 500, headers: { "Cache-Control": "no-store", "Content-Type": "text/plain; charset=utf-8" } });
  }
}
