import { createClient } from "npm:@supabase/supabase-js@2";
import { db, reply, cors, provider, validInvoice, findInvoice } from "../_shared/backend.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors(req) });
  if (req.method !== "POST") return reply(req, { error: "Method not allowed" }, 405);
  try {
    const token = req.headers.get("Authorization")?.replace(/^Bearer /i, "");
    if (!token) return reply(req, { error: "Guest session required" }, 401);
    const auth = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
      { auth: { persistSession: false } });
    const { data: { user }, error: authError } = await auth.auth.getUser(token);
    if (authError || !user) return reply(req, { error: "Invalid session" }, 401);
    const raw = await req.text();
    if (raw.length > 20000) return reply(req, { error: "Request too large" }, 413);
    let body;
    try {
      body = JSON.parse(raw);
    } catch {
      return reply(req, { error: "Invalid checkout JSON" }, 400);
    }
    if (!body || typeof body !== "object" || Array.isArray(body) ||
        typeof body.request_id !== "string" || !/^[a-zA-Z0-9-]{16,100}$/.test(body.request_id) ||
        !Array.isArray(body.items) || body.items.length < 1 || body.items.length > 30) {
      return reply(req, { error: "Invalid checkout" }, 400);
    }
    const c = body.customer;
    if (!c || ["name","email","phone","address"].some(k =>
      typeof c[k] !== "string" || !c[k].trim() || c[k].length > 1000) ||
      !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(c.email) || !/^\+?[0-9 ()-]{10,20}$/.test(c.phone)) {
      return reply(req, { error: "Invalid delivery details" }, 400);
    }
    if (body.items.some((i: Record<string, unknown>) =>
      !i || typeof i !== "object" || Array.isArray(i) ||
      !Number.isSafeInteger(i.product_id) || Number(i.product_id) <= 0 ||
      !Number.isInteger(i.quantity) || Number(i.quantity) < 1 || Number(i.quantity) > 99 ||
      typeof i.finish !== "string" || i.finish.length > 100)) {
      return reply(req, { error: "Invalid cart items" }, 400);
    }
    const admin = db();
    const { data: order, error } = await admin.rpc("jj_reserve_order", {
      p_user_id: user.id, p_request_id: body.request_id, p_items: body.items,
      p_customer: { name: c.name.trim(), email: c.email.trim(), phone: c.phone.trim(), address: c.address.trim() },
    });
    if (error) return reply(req, { error: "Products, stock, or checkout limits have changed. Review your cart." }, 409);
    if (order.status !== "PENDING") return reply(req, { error: "Order is already " + order.status }, 409);
    if (order.invoice_url) return reply(req, { invoice_url: order.invoice_url, external_id: order.id,
      total_cents: order.total_cents });
    const { data: claimed, error: claimError } = await admin.rpc("jj_claim_invoice", { p_order_id: order.id });
    if (claimError) throw claimError;
    let invoice;
    if (claimed) {
      // Exactly one caller POSTs an invoice. An uncertain timeout never issues a second POST.
      const seconds = Math.max(1, Math.floor((Date.parse(order.expires_at) - Date.now()) / 1000));
      const response = await provider("/v2/invoices", { method: "POST", body: JSON.stringify({
        external_id: order.id, amount: Number(order.total_cents) / 100, currency: "PHP",
        payer_email: order.customer.email, description: "JJ'S FURNITURE order " + order.id,
        invoice_duration: seconds, should_send_email: false,
      }) });
      if (!response.ok) {
        // Definite rejected requests can release stock; uncertain responses remain reserved for reconciliation.
        if (response.status >= 400 && response.status < 500 && response.status !== 408 && response.status !== 429) {
          await admin.rpc("jj_finish_order", { p_order_id: order.id, p_status: "FAILED",
            p_invoice_id: null, p_amount_cents: order.total_cents });
        }
        throw new Error("Provider rejected invoice");
      }
      invoice = await response.json();
    } else {
      invoice = await findInvoice(order.id);
      if (!invoice) return reply(req, { error: "Invoice is still processing. Retry shortly." }, 409);
    }
    if (!validInvoice(invoice, order)) throw new Error("Invoice mismatch");
    const url = new URL(invoice.invoice_url);
    if (url.protocol !== "https:" || !url.hostname.endsWith(".xendit.co")) throw new Error("Invalid checkout URL");
    const { error: saveError } = await admin.from("jj_orders").update({
      invoice_id: invoice.id, invoice_url: invoice.invoice_url,
    }).eq("id", order.id);
    if (saveError) throw saveError;
    return reply(req, { invoice_url: invoice.invoice_url, external_id: order.id, total_cents: order.total_cents });
  } catch {
    return reply(req, { error: "Checkout unavailable. Retry with the same request to recover your order." }, 503);
  }
});

