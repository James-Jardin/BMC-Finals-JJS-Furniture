import { createClient } from "npm:@supabase/supabase-js@2";

export const db = () => createClient(
  Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);
export function cors(req: Request): HeadersInit {
  const origin = req.headers.get("origin") ?? "";
  const allowed = (Deno.env.get("ALLOWED_ORIGINS") ?? "").split(",").map(s => s.trim());
  // Flutter web picks a random localhost port on each run, so allow local dev origins.
  const localDev = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
  return {
    ...(allowed.includes(origin) || localDev ? { "Access-Control-Allow-Origin": origin } : {}),
    "Vary": "Origin",
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Content-Type": "application/json",
  };
}
export function reply(req: Request, data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: cors(req) });
}
export function xenditHeaders() {
  const key = Deno.env.get("XENDIT_SECRET_KEY") ?? "";
  // This implementation deliberately fails closed with live credentials.
  if (!key.startsWith("xnd_development_")) throw new Error("Xendit TEST key required");
  return { Authorization: "Basic " + btoa(key + ":"), "Content-Type": "application/json" };
}
export async function provider(path: string, init: RequestInit = {}) {
  return await fetch("https://api.xendit.co" + path, {
    ...init, headers: { ...xenditHeaders(), ...init.headers },
    signal: AbortSignal.timeout(20000),
  });
}
export function validInvoice(invoice: Record<string, unknown>, order: Record<string, unknown>) {
  return !!invoice && typeof invoice.id === "string" && /^[a-zA-Z0-9_-]+$/.test(invoice.id) &&
    invoice.external_id === order.id && invoice.currency === "PHP" &&
    Math.round(Number(invoice.amount) * 100) === Number(order.total_cents) &&
    (!order.invoice_id || invoice.id === order.invoice_id);
}
export async function applyInvoice(invoice: Record<string, unknown>, order: Record<string, unknown>) {
  if (!validInvoice(invoice, order)) throw new Error("Provider invoice mismatch");
  const status = invoice.status === "SETTLED" ? "PAID" : invoice.status;
  if (status !== "PAID" && status !== "EXPIRED") return;
  const { error } = await db().rpc("jj_finish_order", {
    p_order_id: order.id, p_status: status,
    p_invoice_id: invoice.id, p_amount_cents: order.total_cents,
  });
  if (error) throw error;
}
export async function findInvoice(orderId: string) {
  const response = await provider("/v2/invoices?external_id=" + encodeURIComponent(orderId));
  if (!response.ok) throw new Error("Provider lookup unavailable");
  const rows = await response.json();
  if (!Array.isArray(rows)) throw new Error("Invalid provider lookup");
  const matches = rows.filter((r: Record<string, unknown>) => r.external_id === orderId);
  if (matches.length > 1) throw new Error("Duplicate provider invoices need reconciliation");
  return matches[0] ?? null;
}

