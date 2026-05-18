import { createAdminClient, createUserClient } from "../_shared/supabase-admin.ts";
import { handlePreflight, jsonResponse } from "../_shared/cors.ts";

const MAX_ATTEMPTS = 5;
const SESSION_TTL_HOURS = 8;

async function sha256Hex(text: string): Promise<string> {
  const data = new TextEncoder().encode(text);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

interface RequestBody {
  code: string;
}

Deno.serve(async (req) => {
  try {
    const preflight = handlePreflight(req);
    if (preflight) return preflight;
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method Not Allowed" }, 405);
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing Authorization" }, 401);
    }

    let body: RequestBody;
    try {
      body = (await req.json()) as RequestBody;
    } catch {
      return jsonResponse({ error: "Invalid JSON" }, 400);
    }
    const code = body.code?.trim();
    if (!code || code.length < 4) {
      return jsonResponse({ error: "Invalid code" }, 400);
    }

    const userClient = createUserClient(authHeader);
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData?.user) {
      return jsonResponse({ error: "Invalid session" }, 401);
    }

    const admin = createAdminClient();
    const { data: profile } = await admin
      .from("profiles")
      .select("role")
      .eq("id", userData.user.id)
      .maybeSingle();
    if (profile?.role !== "admin") {
      return jsonResponse({ error: "Not admin" }, 403);
    }

    const { data: row, error: fetchErr } = await admin
      .from("admin_login_otp_codes")
      .select("id, code_hash, attempts, expires_at")
      .eq("user_id", userData.user.id)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (fetchErr || !row) {
      return jsonResponse({ error: "No active OTP. Request a new code." }, 400);
    }

    if (new Date(row.expires_at).getTime() < Date.now()) {
      await admin.from("admin_login_otp_codes").delete().eq("id", row.id);
      return jsonResponse({ error: "OTP expired. Request a new code." }, 400);
    }

    if (row.attempts >= MAX_ATTEMPTS) {
      await admin.from("admin_login_otp_codes").delete().eq("id", row.id);
      return jsonResponse({
        error: "Too many failed attempts. Request a new code.",
      }, 429);
    }

    const codeHash = await sha256Hex(code);
    if (codeHash !== row.code_hash) {
      await admin
        .from("admin_login_otp_codes")
        .update({ attempts: row.attempts + 1 })
        .eq("id", row.id);
      return jsonResponse({ error: "Invalid code" }, 400);
    }

    // 成功: OTP コード削除 + セッション検証フラグを upsert
    await admin.from("admin_login_otp_codes").delete().eq("id", row.id);

    const expiresAt = new Date(
      Date.now() + SESSION_TTL_HOURS * 60 * 60 * 1000,
    ).toISOString();
    const { error: upsertErr } = await admin
      .from("admin_session_verifications")
      .upsert({
        user_id: userData.user.id,
        verified_at: new Date().toISOString(),
        expires_at: expiresAt,
      });
    if (upsertErr) {
      console.error("[verify-admin-otp] upsert error", upsertErr);
      return jsonResponse({ error: "Failed to record verification" }, 500);
    }

    return jsonResponse({ ok: true, expires_at: expiresAt });
  } catch (err) {
    console.error("[verify-admin-otp] unhandled", err);
    return jsonResponse({
      error: err instanceof Error ? err.message : String(err),
    }, 500);
  }
});
