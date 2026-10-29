import { db, provider, findInvoice, applyInvoice } from "../_shared/backend.ts";

Deno.serve(async (req: Request) => {
  const secret = Deno.env.get("RECONCILE_SECRET");
  if (req.method !== "POST" || !secret || req.headers.get("Authorization") !== "Bearer " + secret) {
    return new Response("Unauthorized", { status: 401 });
  }
  try {
    const admin = db();
    const { data: orders, error } = await admin.from("jj_orders").select("*")
      .eq("status", "PENDING").lt("expires_at", new Date().toISOString()).limit(100);
    if (error) throw error;
    let processed = 0;
    for (const order of orders ?? []) {
      let invoice;
      if (order.invoice_id) {
        const response = await provider("/v2/invoices/" + encodeURIComponent(order.invoice_id));
        if (!response.ok) throw new Error("Provider unavailable");
        invoice = await response.json();
      } else {
        invoice = await findInvoice(order.id);
      }
      if (invoice?.status === "PENDING") {
        const expired = await provider("/invoices/" + encodeURIComponent(invoice.id) + "/expire!",
          { method: "POST" });
        if (!expired.ok) throw new Error("Provider expiration unavailable");
        // Refetch to avoid racing a successful payment.
        const verified = await provider("/v2/invoices/" + encodeURIComponent(invoice.id));
        if (!verified.ok) throw new Error("Provider unavailable");
        invoice = await verified.json();
      }
      if (invoice) await applyInvoice(invoice, order);
      else {
        const { error: finishError } = await admin.rpc("jj_finish_order", {
          p_order_id: order.id, p_status: "EXPIRED",
          p_invoice_id: null, p_amount_cents: order.total_cents,
        });
        if (finishError) throw finishError;
      }
      processed++;
    }
    return Response.json({ processed });
  } catch {
    return new Response("Reconciliation incomplete; retry", { status: 503 });
  }
});

