export async function onRequest({ env }) {
  const kv = env.FRIDA_APK_KV;
  if (!kv) return new Response("Penyimpanan APK belum dikonfigurasi. Tambahkan binding FRIDA_APK_KV pada Cloudflare Pages.", { status: 503, headers: { "Cache-Control": "no-store", "Content-Type": "text/plain; charset=utf-8" } });
  try {
    const apk = await kv.get("frida-latest.apk", { type: "arrayBuffer" });
    if (!apk) return new Response("APK FRIDA belum tersedia. Jalankan build Android terbaru terlebih dahulu.", { status: 404, headers: { "Cache-Control": "no-store", "Content-Type": "text/plain; charset=utf-8" } });
    return new Response(apk, { headers: { "Content-Type": "application/vnd.android.package-archive", "Content-Disposition": 'attachment; filename="FRIDA-latest.apk"', "Cache-Control": "private, no-store", "X-Content-Type-Options": "nosniff" } });
  } catch {
    return new Response("Gagal mengambil APK dari penyimpanan. Silakan coba lagi atau hubungi pengelola FRIDA.", { status: 500, headers: { "Cache-Control": "no-store", "Content-Type": "text/plain; charset=utf-8" } });
  }
}
