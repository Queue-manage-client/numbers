import type Stripe from "npm:stripe@^17.0.0";
import { stripe, STRIPE_WEBHOOK_SECRET } from "../_shared/stripe.ts";
import { createAdminClient } from "../_shared/supabase-admin.ts";

interface PlanLookupRow {
  code: string;
  stripe_price_id_monthly: string | null;
  stripe_price_id_yearly: string | null;
}

interface PlanLookupResult {
  code: string;
  cycle: "monthly" | "yearly";
}

async function lookupPlanByPriceId(
  admin: ReturnType<typeof createAdminClient>,
  priceId: string,
): Promise<PlanLookupResult | null> {
  const { data, error } = await admin
    .from("subscription_plans")
    .select("code, stripe_price_id_monthly, stripe_price_id_yearly")
    .or(
      `stripe_price_id_monthly.eq.${priceId},stripe_price_id_yearly.eq.${priceId}`,
    )
    .maybeSingle<PlanLookupRow>();

  if (error || !data) return null;
  if (data.stripe_price_id_monthly === priceId) {
    return { code: data.code, cycle: "monthly" };
  }
  if (data.stripe_price_id_yearly === priceId) {
    return { code: data.code, cycle: "yearly" };
  }
  return null;
}

async function syncSubscription(
  admin: ReturnType<typeof createAdminClient>,
  subscription: Stripe.Subscription,
): Promise<void> {
  const customerId = typeof subscription.customer === "string"
    ? subscription.customer
    : subscription.customer.id;

  const item = subscription.items.data[0];
  const priceId = item?.price.id ?? null;
  const plan = priceId ? await lookupPlanByPriceId(admin, priceId) : null;

  const update: Record<string, unknown> = {
    stripe_subscription_id: subscription.id,
    subscription_status: subscription.status,
    cancel_at_period_end: subscription.cancel_at_period_end,
    current_period_end: subscription.current_period_end
      ? new Date(subscription.current_period_end * 1000).toISOString()
      : null,
  };

  if (plan) {
    update.current_plan_code = plan.code;
    update.current_billing_cycle = plan.cycle;
  }

  // canceled / incomplete_expired は subscription_id を null に戻す
  if (
    subscription.status === "canceled" ||
    subscription.status === "incomplete_expired"
  ) {
    update.stripe_subscription_id = null;
  }

  const { error } = await admin
    .from("companies")
    .update(update)
    .eq("stripe_customer_id", customerId);

  if (error) {
    console.error("[stripe-webhook] failed to sync subscription", error);
    throw error;
  }
}

async function handleCheckoutCompleted(
  admin: ReturnType<typeof createAdminClient>,
  session: Stripe.Checkout.Session,
): Promise<void> {
  const companyId = session.client_reference_id;
  const customerId = typeof session.customer === "string"
    ? session.customer
    : session.customer?.id;

  if (!companyId || !customerId) return;

  // company に customer を確実に紐付け (create-checkout-session で先に保存しているが念のため)
  await admin
    .from("companies")
    .update({ stripe_customer_id: customerId })
    .eq("id", companyId);

  if (typeof session.subscription === "string") {
    const subscription = await stripe.subscriptions.retrieve(
      session.subscription,
    );
    await syncSubscription(admin, subscription);
  }
}

async function handlePaymentFailed(
  admin: ReturnType<typeof createAdminClient>,
  invoice: Stripe.Invoice,
): Promise<void> {
  const customerId = typeof invoice.customer === "string"
    ? invoice.customer
    : invoice.customer?.id;
  if (!customerId) return;

  await admin
    .from("companies")
    .update({ subscription_status: "past_due" })
    .eq("stripe_customer_id", customerId);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }
  if (!STRIPE_WEBHOOK_SECRET) {
    return new Response("Webhook secret missing", { status: 500 });
  }

  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return new Response("Missing signature", { status: 400 });
  }

  const body = await req.text();

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      STRIPE_WEBHOOK_SECRET,
    );
  } catch (err) {
    console.error("[stripe-webhook] signature verification failed", err);
    return new Response("Invalid signature", { status: 400 });
  }

  const admin = createAdminClient();

  // 冪等性: stripe_events に既に存在するなら 200 で即返す
  const { error: insertError } = await admin
    .from("stripe_events")
    .insert({ id: event.id, type: event.type, payload: event as unknown });

  if (insertError) {
    if (insertError.code === "23505") {
      return new Response("Already processed", { status: 200 });
    }
    console.error("[stripe-webhook] failed to record event", insertError);
    return new Response("Internal error", { status: 500 });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed":
        await handleCheckoutCompleted(
          admin,
          event.data.object as Stripe.Checkout.Session,
        );
        break;
      case "customer.subscription.created":
      case "customer.subscription.updated":
      case "customer.subscription.deleted":
        await syncSubscription(
          admin,
          event.data.object as Stripe.Subscription,
        );
        break;
      case "invoice.payment_failed":
      case "invoice.payment_action_required":
        await handlePaymentFailed(
          admin,
          event.data.object as Stripe.Invoice,
        );
        break;
      default:
        // 未対応イベントは無視 (記録のみ)
        break;
    }
  } catch (err) {
    console.error(`[stripe-webhook] handler error for ${event.type}`, err);
    return new Response("Handler error", { status: 500 });
  }

  return new Response("ok", { status: 200 });
});
