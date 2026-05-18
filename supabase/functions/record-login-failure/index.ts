import { createAdminClient } from "../_shared/supabase-admin.ts";
import { handlePreflight, jsonResponse } from "../_shared/cors.ts";

interface RequestBody {
  email: string;
}

const THRESHOLD = 10;
const WINDOW_MIN = 30;
const LOCK_MIN = 30;

Deno.serve(async (req) => {
  try {
    const preflight = handlePreflight(req);
    if (preflight) return preflight;
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method Not Allowed" }, 405);
    }

    let body: RequestBody;
    try {
      body = (await req.json()) as RequestBody;
    } catch {
      return jsonResponse({ error: "Invalid JSON" }, 400);
    }

    const email = body.email?.trim().toLowerCase();
    if (!email) {
      // 攻撃者にメールアドレス有無を漏らさないため常に 200 を返す
      return jsonResponse({ ok: true });
    }

    const admin = createAdminClient();

    // 1. email -> user_id 解決 (admin API)
    const { data: list, error: listErr } = await admin.auth.admin.listUsers({
      page: 1,
      perPage: 200,
    });
    if (listErr) {
      console.error("[record-login-failure] listUsers error", listErr);
      return jsonResponse({ ok: true });
    }
    const user = list.users.find((u) => u.email?.toLowerCase() === email);
    if (!user) {
      // 存在しないアカウント。レスポンスはユーザー有無を漏らさず 200
      return jsonResponse({ ok: true });
    }

    // 2. 失敗回数記録
    const { error: insertErr } = await admin
      .from("auth_failed_login_attempts")
      .insert({ user_id: user.id });
    if (insertErr) {
      console.error("[record-login-failure] insert error", insertErr);
    }

    // 3. 直近 WINDOW_MIN 分の失敗回数集計
    const since = new Date(Date.now() - WINDOW_MIN * 60 * 1000).toISOString();
    const { count, error: countErr } = await admin
      .from("auth_failed_login_attempts")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id)
      .gte("attempted_at", since);

    if (countErr) {
      console.error("[record-login-failure] count error", countErr);
      return jsonResponse({ ok: true });
    }

    // 4. 閾値超過なら banned_until をセット
    if ((count ?? 0) >= THRESHOLD) {
      const bannedUntil = new Date(
        Date.now() + LOCK_MIN * 60 * 1000,
      ).toISOString();
      const { error: banErr } = await admin.auth.admin.updateUserById(user.id, {
        ban_duration: `${LOCK_MIN * 60}s`,
      });
      if (banErr) {
        console.error("[record-login-failure] ban error", banErr);
      } else {
        console.log(
          `[record-login-failure] locked user ${user.id} until ${bannedUntil}`,
        );
      }
      return jsonResponse({ ok: true, locked: true });
    }

    return jsonResponse({ ok: true, locked: false });
  } catch (err) {
    console.error("[record-login-failure] unhandled", err);
    return jsonResponse({ ok: true });
  }
});
