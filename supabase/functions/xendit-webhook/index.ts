import { db, provider, applyInvoice } from "../_shared/backend.ts";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  const expected = Deno.env.get("XENDIT_WEBHOOK_TOKEN");
  const supplied = req.headers.get("x-callback-token");
  if (!expected || !supplied) return new Response("Unauthorized", { status: 401 });
  // Fixed-time comparison of token digests, with no token logs.
  const encoder = new TextEncoder();
  const [a, b] = await Promise.all([expected, supplied].map(s =>
    crypto.subtle.digest("SHA-256", encoder.encode(s))));
  const aa = new Uint8Array(a), bb = new Uint8Array(b);
  let difference = 0;
  for (let i=0; i<aa.length; i++) difference |= aa[i] ^ bb[i];
  if (difference !== 0) return new Response("Unauthorized", { status: 401 });
  try {
    const payload = await req.json();
    if (typeof payload.id !== "string" || !/^[a-zA-Z0-9_-]+$/.test(payload.id) ||
        typeof payload.external_id !== "string") return new Response("Invalid payload", { status: 400 });
    const { data: order, error } = await db().from("jj_orders").select("*")
      .eq("id", payload.external_id).single();
    if (error || !order) return new Response("Unknown order", { status: 404 });
    // Refetch authoritative provider state instead of trusting callback amount/status.
    const response = await provider("/v2/invoices/" + encodeURIComponent(payload.id));
    if (!response.ok) throw new Error("Provider verification unavailable");
    await applyInvoice(await response.json(), order);
    return new Response("OK", { status: 200 });
  } catch {
    // Non-2xx causes Xendit to retry; do not acknowledge an unrecorded payment.
    return new Response("Verification unavailable", { status: 503 });
  }
});

