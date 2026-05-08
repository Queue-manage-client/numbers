import { stripe } from "../_shared/stripe.ts";
import { createAdminClient, createUserClient } from "../_shared/supabase-admin.ts";
import { corsHeaders, handlePreflight, jsonResponse } from "../_shared/cors.ts";

interface RequestBody {
  plan_code: string;
  billing_cycle: "monthly" | "yearly";
}

interface CompanyRow {
  id: string;
  stripe_customer_id: string | null;
  approval_status: string;
  eligible_plan_codes: string[];
  name: string | null;
}

interface PlanRow {
  code: string;
  stripe_price_id_monthly: string | null;
  stripe_price_id_yearly: string | null;
}

Deno.serve(async (req) => {
  try {
    return await handleRequest(req);
  } catch (err) {
    console.error("[create-checkout-session] unhandled error", err);
    return jsonResponse({
      error: err instanceof Error ? err.message : String(err),
      stack: err instanceof Error ? err.stack : undefined,
    }, 500);
  }
});

async function handleRequest(req: Request): Promise<Response> {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method Not Allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Missing Authorization header" }, 401);
  }

  let body: RequestBody;
  try {
    body = (await req.json()) as RequestBody;
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const { plan_code, billing_cycle } = body;
  if (!plan_code || !["monthly", "yearly"].includes(billing_cycle)) {
    return jsonResponse({ error: "Invalid plan_code or billing_cycle" }, 400);
  }

  const userClient = createUserClient(authHeader);
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const admin = createAdminClient();

  // profiles.company_id 経由で対象企業を取得
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
    .select("id, stripe_customer_id, approval_status, eligible_plan_codes, name")
    .eq("id", profile.company_id)
    .maybeSingle<CompanyRow>();

  if (companyError || !company) {
    return jsonResponse({ error: "Company not found" }, 404);
  }

  if (company.approval_status !== "approved") {
    return jsonResponse({ error: "Company is not approved yet" }, 403);
  }

  if (!company.eligible_plan_codes?.includes(plan_code)) {
    return jsonResponse({ error: "Plan not eligible for this company" }, 403);
  }

  const { data: plan, error: planError } = await admin
    .from("subscription_plans")
    .select("code, stripe_price_id_monthly, stripe_price_id_yearly")
    .eq("code", plan_code)
    .maybeSingle<PlanRow>();

  if (planError || !plan) {
    return jsonResponse({ error: "Plan not found" }, 404);
  }

  const priceId = billing_cycle === "monthly"
    ? plan.stripe_price_id_monthly
    : plan.stripe_price_id_yearly;
  if (!priceId) {
    return jsonResponse({ error: "Stripe price not configured for plan" }, 500);
  }

  // Stripe Customer 未作成なら作成
  let customerId = company.stripe_customer_id;
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: userData.user.email ?? undefined,
      name: company.name ?? undefined,
      metadata: { company_id: company.id, user_id: userData.user.id },
    });
    customerId = customer.id;
    await admin
      .from("companies")
      .update({ stripe_customer_id: customerId })
      .eq("id", company.id);
  }

  const successUrl = Deno.env.get("WEB_RETURN_URL_SUCCESS") ??
    "https://example.com/subscription/success";
  const cancelUrl = Deno.env.get("WEB_RETURN_URL_CANCEL") ??
    "https://example.com/subscription/cancel";

  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer: customerId,
    client_reference_id: company.id,
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: successUrl,
    cancel_url: cancelUrl,
    locale: "ja",
    billing_address_collection: "required",
    tax_id_collection: { enabled: true },
    customer_update: {
      name: "auto",
      address: "auto",
    },
    subscription_data: {
      metadata: { company_id: company.id },
    },
  });

  if (!session.url) {
    return jsonResponse({ error: "Failed to create Checkout session" }, 500);
  }

  return jsonResponse({ url: session.url }, 200);
}
