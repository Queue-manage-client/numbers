import { createUserClient } from "../_shared/supabase-admin.ts";
import { handlePreflight, jsonResponse } from "../_shared/cors.ts";
import { sendEmailViaResend } from "../_shared/resend.ts";

function extractClientIp(req: Request): string {
  const xff = req.headers.get("x-forwarded-for");
  if (xff) {
    const first = xff.split(",")[0]?.trim();
    if (first) return first;
  }
  return req.headers.get("x-real-ip")?.trim() ?? "unknown";
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

    const ip = extractClientIp(req);
    const userAgent = req.headers.get("user-agent") ?? "不明";
    const now = new Date().toLocaleString("ja-JP", { timeZone: "Asia/Tokyo" });

    const from = Deno.env.get("LOGIN_NOTIFICATION_FROM") ??
      "no-reply@example.com";
    const appName = Deno.env.get("APP_NAME") ?? "Numbers";

    await sendEmailViaResend({
      from,
      to: userData.user.email,
      subject: `[${appName}] アカウントへのログインがありました`,
      html: `
        <p>${escapeHtml(appName)} アカウントへのログインを検知しました。</p>
        <ul>
          <li>日時 (JST): ${escapeHtml(now)}</li>
          <li>IP アドレス: ${escapeHtml(ip)}</li>
          <li>端末情報: ${escapeHtml(userAgent)}</li>
        </ul>
        <p>心当たりがない場合は、ただちにパスワードを変更し、サポートまでご連絡ください。</p>
      `,
    });

    return jsonResponse({ ok: true });
  } catch (err) {
    console.error("[send-login-notification] error", err);
    return jsonResponse({
      error: err instanceof Error ? err.message : String(err),
    }, 500);
  }
});
