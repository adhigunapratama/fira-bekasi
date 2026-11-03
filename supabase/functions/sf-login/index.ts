import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const { employee_id, password } = await req.json();
    const sfId = String(employee_id ?? "").trim().toUpperCase();
    const pass = String(password ?? "");
    if (!sfId || !pass || sfId.length > 40 || pass.length > 256) {
      return json({ error: "ID SF atau password tidak sesuai." }, 400);
    }

    const url = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    if (!url || !anonKey || !serviceKey) {
      return json({ error: "Konfigurasi autentikasi server belum lengkap." }, 500);
    }

    // Service role hanya berada di server function, tidak pernah dikirim ke browser.
    const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
    const { data: profile, error: profileError } = await admin
      .from("profiles")
      .select("id, role, account_status")
      .ilike("employee_id", sfId)
      .maybeSingle();

    // Pesan dibuat generik agar endpoint tidak menjadi alat enumerasi ID/email.
    if (profileError || !profile || profile.role !== "sf" || profile.account_status !== "approved") {
      return json({ error: "ID SF atau password tidak sesuai, atau akun belum aktif." }, 401);
    }

    const { data: authUser, error: userError } = await admin.auth.admin.getUserById(profile.id);
    const email = authUser?.user?.email;
    if (userError || !email) {
      return json({ error: "ID SF atau password tidak sesuai, atau akun belum aktif." }, 401);
    }

    // Password tetap diverifikasi oleh Supabase Auth, bukan oleh database FRIDA.
    const publicClient = createClient(url, anonKey, { auth: { persistSession: false } });
    const { data: signedIn, error: signInError } = await publicClient.auth.signInWithPassword({
      email,
      password: pass,
    });
    if (signInError || !signedIn.session) {
      return json({ error: "ID SF atau password tidak sesuai, atau akun belum aktif." }, 401);
    }

    return json({
      access_token: signedIn.session.access_token,
      refresh_token: signedIn.session.refresh_token,
      token_type: signedIn.session.token_type,
      expires_in: signedIn.session.expires_in,
      expires_at: signedIn.session.expires_at,
    });
  } catch (_error) {
    return json({ error: "Permintaan login tidak dapat diproses." }, 400);
  }
});
