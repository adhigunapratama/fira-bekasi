const COOKIE = "frida_portal_session";
const SESSION_SECONDS = 8 * 60 * 60;
const LOGO = "https://raw.githubusercontent.com/adhigunapratama/fira-bekasi/main/assets/frida-logo.png";

function b64url(bytes) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}
function fromB64url(value) {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((value.length + 3) % 4);
  return Uint8Array.from(atob(base64), c => c.charCodeAt(0));
}
async function hmacKey(secret, usages) {
  return crypto.subtle.importKey("raw", new TextEncoder().encode(secret), {name:"HMAC",hash:"SHA-256"}, false, usages);
}
function getCookie(request) {
  const item = (request.headers.get("Cookie") || "").split(";").map(x=>x.trim()).find(x=>x.startsWith(COOKIE+"="));
  return item ? decodeURIComponent(item.slice(COOKIE.length+1)) : "";
}
function headers(extra={}) {
  return {"Cache-Control":"no-store, no-cache, must-revalidate","Pragma":"no-cache",...extra};
}
function loginPage(error="") {
  return new Response(`<!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#111318"><title>FRIDA | Akses Internal</title><style>*{box-sizing:border-box}body{margin:0;min-height:100vh;display:grid;place-items:center;padding:22px;background:radial-gradient(ellipse at 80% 10%,#4a1820,transparent 38%),#101116;color:#f5f6f8;font:15px system-ui,sans-serif}.card{width:min(100%,410px);padding:34px;border:1px solid #ffffff18;border-radius:22px;background:#191b23;box-shadow:0 25px 80px #0008;text-align:center}.logo{width:76px;height:76px;object-fit:contain;margin-bottom:12px}.tag{font-size:10px;letter-spacing:.18em;color:#ff7782;font-weight:700}.card h1{font-size:28px;margin:8px 0}.card p{color:#aeb2bd;font-size:13px;line-height:1.6;margin:0 0 24px}label{display:block;text-align:left;font-size:12px;color:#c9cbd2;margin-bottom:8px}input{width:100%;padding:14px 15px;border-radius:11px;border:1px solid #ffffff22;background:#101218;color:white;font-size:16px;outline:none}input:focus{border-color:#e32636}button{width:100%;margin-top:14px;padding:14px;border:0;border-radius:11px;background:#e32636;color:white;font-weight:700;font-size:14px;cursor:pointer}.error{color:#ff8d97!important;margin:12px 0 0!important}.foot{font-size:10px;color:#777d89;margin-top:24px}</style></head><body><main class="card"><img class="logo" src="${LOGO}" alt="FRIDA"><div class="tag">INTERNAL DOWNLOAD PORTAL</div><h1>Selamat datang di FRIDA</h1><p>Portal internal Fiber Routing & Intelligence Data Assistant.<br>Masukkan password tim untuk melanjutkan.</p><form method="post" action="/__auth/login"><label for="password">Password akses</label><input id="password" name="password" type="password" autocomplete="current-password" required autofocus><button type="submit">Masuk ke FRIDA →</button></form>${error ? `<p class="error">${error}</p>` : ""}<div class="foot">THCO Kabupaten Bekasi · Akses khusus internal</div></main></body></html>`, {status:200,headers:headers({"Content-Type":"text/html; charset=utf-8"})});
}
export async function onRequest({request,env,next}) {
  const url = new URL(request.url);
  if (!env.FRIDA_PASSWORD || !env.SESSION_SECRET) {
    return new Response("Portal belum dikonfigurasi. Tambahkan FRIDA_PASSWORD dan SESSION_SECRET di Cloudflare Pages > Settings > Variables and Secrets.",{status:503,headers:headers({"Content-Type":"text/plain; charset=utf-8"})});
  }
  if (url.pathname === "/__auth/login" && request.method === "POST") {
    const form = await request.formData();
    const supplied = new TextEncoder().encode(String(form.get("password") || ""));
    const expected = new TextEncoder().encode(env.FRIDA_PASSWORD);
    let mismatch = supplied.length ^ expected.length;
    for (let i=0;i<Math.max(supplied.length,expected.length);i++) mismatch |= (supplied[i]||0) ^ (expected[i]||0);
    if (mismatch !== 0) return loginPage("Password tidak sesuai. Silakan coba lagi.");
    const expiry = String(Math.floor(Date.now()/1000)+SESSION_SECONDS);
    const key = await hmacKey(env.SESSION_SECRET,["sign"]);
    const signature = b64url(new Uint8Array(await crypto.subtle.sign("HMAC",key,new TextEncoder().encode(expiry))));
    return new Response(null,{status:303,headers:headers({"Location":"/","Set-Cookie":COOKIE+"="+expiry+"."+signature+"; Max-Age="+SESSION_SECONDS+"; Path=/; HttpOnly; Secure; SameSite=Lax"})});
  }
  if (url.pathname === "/__auth/logout" && request.method === "POST") {
    return new Response(null,{status:303,headers:headers({"Location":"/","Set-Cookie":COOKIE+"=; Max-Age=0; Path=/; HttpOnly; Secure; SameSite=Lax"})});
  }
  const token = getCookie(request).split(".");
  let valid = false;
  if (token.length === 2 && Number(token[0]) > Math.floor(Date.now()/1000)) {
    try {
      const key = await hmacKey(env.SESSION_SECRET,["verify"]);
      valid = await crypto.subtle.verify("HMAC",key,fromB64url(token[1]),new TextEncoder().encode(token[0]));
    } catch { valid = false; }
  }
  if (!valid) return loginPage();
  return next();
}