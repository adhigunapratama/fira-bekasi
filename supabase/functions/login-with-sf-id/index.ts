import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function getKey(secretName: string): string | null {
  try {
    const raw = Deno.env.get(secretName);
    if (!raw) return null;
    const keys = JSON.parse(raw);
    return keys.default ?? null;
  } catch {
    console.error(`Gagal membaca konfigurasi ${secretName}`);
    return null;
  }
}

const keyOnlyFetch: typeof fetch = (input, init = {}) => {
  const headers = new Headers(init.headers);
  headers.delete("Authorization");
  return fetch(input, { ...init, headers });
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Metode tidak diizinkan." }, 405);
  }

  try {
    const url = Deno.env.get("SUPABASE_URL");
    const publishableKey = getKey("SUPABASE_PUBLISHABLE_KEYS");
    const secretKey = getKey("SUPABASE_SECRET_KEYS");

    if (!url || !publishableKey || !secretKey) {
      console.error("Konfigurasi Supabase tidak lengkap.");
      return json({ error: "Konfigurasi server belum lengkap." }, 500);
    }

    const body = await req.json();
    const employeeId = String(body.employee_id ?? "").trim().toUpperCase();
    const password = String(body.password ?? "");

    if (
      !employeeId ||
      !/^[A-Z0-9-]{2,40}$/.test(employeeId) ||
      !password ||
      password.length > 256
    ) {
      return json({ error: "ID SF atau password tidak valid." }, 400);
    }

    const clientOptions = {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
      },
      global: { fetch: keyOnlyFetch },
    };

    const admin = createClient(url, secretKey, clientOptions);
    const auth = createClient(url, publishableKey, clientOptions);

    const { data: profile, error: profileError } = await admin
      .from("profiles")
      .select("id, role, account_status")
      .ilike("employee_id", employeeId)
      .maybeSingle();

    if (profileError) {
      console.error("Profile lookup failed:", profileError.message);
      return json({ error: "Gagal memeriksa akun." }, 500);
    }

    if (!profile || profile.role !== "sf") {
      return json({ error: "ID SF atau password salah." }, 401);
    }

    if (profile.account_status !== "approved") {
      const messages: Record<string, string> = {
        pending: "Akun masih menunggu persetujuan Manager.",
        rejected: "Pendaftaran akun ditolak. Hubungi Manager.",
        disabled: "Akun sedang dinonaktifkan. Hubungi Manager.",
      };
      return json({
        error: messages[profile.account_status] ?? "Status akun tidak diizinkan.",
      }, 403);
    }

    const { data: userData, error: userError } =
      await admin.auth.admin.getUserById(profile.id);

    if (userError || !userData.user?.email) {
      return json({ error: "Data akun tidak ditemukan." }, 401);
    }

    const { data: login, error: loginError } =
      await auth.auth.signInWithPassword({
        email: userData.user.email,
        password,
      });

    if (loginError || !login.session) {
      return json({ error: "ID SF atau password salah." }, 401);
    }

    return json({
      user: login.user,
      session: login.session,
    });
  } catch (error) {
    console.error("Login function error:", error);
    return json({ error: "Terjadi kesalahan pada server." }, 500);
  }
});
