import { stripe } from "../_shared/stripe.ts";
import { createAdminClient, createUserClient } from "../_shared/supabase-admin.ts";
import { handlePreflight, jsonResponse } from "../_shared/cors.ts";

interface CompanyRow {
  id: string;
  stripe_customer_id: string | null;
}

Deno.serve(async (req) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method Not Allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Missing Authorization header" }, 401);
  }

  const userClient = createUserClient(authHeader);
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const admin = createAdminClient();

  const { data: profile, error: profileError } = await admin
    .from("profiles")
    .select("company_id")
    .eq("id", userData.user.id)
    .maybeSingle<{ company_id: string | null }>();

  if (profileError || !profile?.company_id) {
    return jsonResponse({ error: "Company not found for user" }, 404);
  }

  const { data: company, error: companyError } = await admin
    .from("companies")
    .select("id, stripe_customer_id")
    .eq("id", profile.company_id)
    .maybeSingle<CompanyRow>();

  if (companyError || !company) {
    return jsonResponse({ error: "Company not found" }, 404);
  }
  if (!company.stripe_customer_id) {
    return jsonResponse({ error: "No Stripe customer for this company" }, 400);
  }

  const returnUrl = Deno.env.get("WEB_RETURN_URL_PORTAL") ??
    "https://example.com/subscription/portal-return";

  const session = await stripe.billingPortal.sessions.create({
    customer: company.stripe_customer_id,
    return_url: returnUrl,
    locale: "ja",
  });

  return jsonResponse({ url: session.url }, 200);
});
