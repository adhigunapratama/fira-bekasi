export async function onRequest({ env }) {
  const kv = env.FRIDA_APK_KV;
  const headers = { "Cache-Control": "private, no-store", "Content-Type": "text/plain; charset=utf-8" };
  if (!kv) return new Response("Penyimpanan APK belum dikonfigurasi. Tambahkan binding FRIDA_APK_KV pada Cloudflare Pages.", { status: 503, headers });
  try {
    const apk = await kv.get("frida-latest.apk", { type: "arrayBuffer" });
    if (!apk) return new Response("APK FRIDA belum tersedia. Jalankan build Android terbaru terlebih dahulu.", { status: 404, headers });
    const storedVersion = await kv.get("frida-version.txt");
    const version = storedVersion && /^\\d+\\.\\d+\\.\\d+(?:[-+][A-Za-z0-9.-]+)?$/.test(storedVersion.trim())
      ? storedVersion.trim()
      : "latest";
    return new Response(apk, {
      headers: {
        "Content-Type": "application/vnd.android.package-archive",
        "Content-Disposition": `attachment; filename="FRIDA-${version}.apk"`,
        "Cache-Control": "private, no-store",
        "X-Content-Type-Options": "nosniff"
      }
    });
  } catch {
    return new Response("Gagal mengambil APK dari penyimpanan. Silakan coba lagi atau hubungi pengelola FRIDA.", { status: 500, headers });
  }
}
