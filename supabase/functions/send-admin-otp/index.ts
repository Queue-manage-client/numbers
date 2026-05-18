import { createAdminClient, createUserClient } from "../_shared/supabase-admin.ts";
import { handlePreflight, jsonResponse } from "../_shared/cors.ts";
import { sendEmailViaResend } from "../_shared/resend.ts";

const OTP_LENGTH = 6;
const OTP_TTL_MIN = 10;

function generateOtp(): string {
  const buf = new Uint8Array(4);
  crypto.getRandomValues(buf);
  const num = (buf[0] << 24 | buf[1] << 16 | buf[2] << 8 | buf[3]) >>> 0;
  return (num % 10 ** OTP_LENGTH).toString().padStart(OTP_LENGTH, "0");
}

async function sha256Hex(text: string): Promise<string> {
  const data = new TextEncoder().encode(text);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function escapeHtml(s: string): string {
  return s
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
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

    const userClient = createUserClient(authHeader);
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData?.user?.email) {
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

    const code = generateOtp();
    const codeHash = await sha256Hex(code);
    const expiresAt = new Date(Date.now() + OTP_TTL_MIN * 60 * 1000)
      .toISOString();

    // 既存の未使用コードを削除 (1 ユーザー 1 アクティブコード)
    await admin
      .from("admin_login_otp_codes")
      .delete()
      .eq("user_id", userData.user.id);

    const { error: insertErr } = await admin
      .from("admin_login_otp_codes")
      .insert({
        user_id: userData.user.id,
        code_hash: codeHash,
        expires_at: expiresAt,
      });
    if (insertErr) {
      console.error("[send-admin-otp] insert error", insertErr);
      return jsonResponse({ error: "Failed to create OTP" }, 500);
    }

    const from = Deno.env.get("LOGIN_NOTIFICATION_FROM") ??
      "no-reply@example.com";
    const appName = Deno.env.get("APP_NAME") ?? "Numbers";

    await sendEmailViaResend({
      from,
      to: userData.user.email,
      subject: `[${appName}] 管理画面ログイン認証コード`,
      html: `
        <p>${escapeHtml(appName)} 管理画面のログイン認証コードです。</p>
        <p style="font-size:32px;font-weight:bold;letter-spacing:8px;font-family:monospace">${code}</p>
        <p>このコードは <strong>${OTP_TTL_MIN} 分間</strong> 有効です。</p>
        <p>心当たりがない場合は、ただちにパスワードを変更してください。</p>
      `,
    });

    return jsonResponse({ ok: true, expires_at: expiresAt });
  } catch (err) {
    console.error("[send-admin-otp] unhandled", err);
    return jsonResponse({
      error: err instanceof Error ? err.message : String(err),
    }, 500);
  }
});
