# Supabase and Xendit test deployment

The Flutter app retains the existing public Supabase project configuration.
No service-role key, Xendit secret or webhook token belongs in Flutter, web assets,
source control, or a browser request. No real project schema was modified during
this implementation.

## Current connection status (verified 2026-10-27)

Checked directly against the configured project `bnomvznpwasejddetmte`:

| Item | State |
| --- | --- |
| Supabase REST API and anon key | Working |
| Catalog data | 6 furniture products live (IDs 4-9); the 3 gadget demo rows are hidden |
| `jj_*` schema | Applied; RLS policies and checkout RPCs verified |
| Anonymous sign-ins | Enabled; guest session creation returns HTTP 200 |
| `create-invoice` | Deployed from this repo; verified with a real Xendit TEST invoice |
| `xendit-webhook` | Deployed with `verify_jwt = false`; GET returns 405, not 401 |
| `reconcile-orders` | Deployed; unauthenticated POST returns 401 |
| Xendit key | TEST key confirmed (invoice URL was `checkout-staging.xendit.co`) |
| `ALLOWED_ORIGINS` | `http://localhost:8080,http://127.0.0.1:8080` |

The earlier note about blocked network access is obsolete. The project is reachable
from this machine, and the standalone CLI is available at
`.tooling\supabase\supabase.exe` (v2.122.0). No service-role key, Xendit secret
or webhook token belongs in Flutter, web assets, source control, or a browser request.

## Deployment steps (completed 2026-10-27)

The steps below were executed successfully for `bnomvznpwasejddetmte`. Keep them
as the redeployment reference. For future deploys without Docker, use
`functions deploy --project-ref bnomvznpwasejddetmte --use-api`.

## Fastest path to a working TEST checkout

1. Log in and link the project (one-time; the CLI stores the token locally):

   ```powershell
   .\.tooling\supabase\supabase.exe login
   .\.tooling\supabase\supabase.exe link --project-ref bnomvznpwasejddetmte
   ```

2. Apply the schema. Either run `supabase db push` (the CLI asks for the database
   password from Project Settings > Database), or paste
   `supabase/furniture_setup.sql` into the SQL Editor. For first-time setup the
   SQL Editor route is simpler because it also inserts the six furniture rows.

3. Hide the old gadget rows and confirm the catalog:

   ```sql
   update public.products set published = false where id in (1, 2, 3);
   select id, name, price, stock, published from public.products order by id;
   ```

4. Enable Authentication > Sign In / Providers > Anonymous sign-ins.

5. Set the server-only secrets (never in Flutter):

   ```powershell
   .\.tooling\supabase\supabase.exe secrets set `
     XENDIT_SECRET_KEY=xnd_development_... `
     XENDIT_WEBHOOK_TOKEN=... `
     ALLOWED_ORIGINS=http://localhost:8080,https://YOUR-WEB-APP `
     RECONCILE_SECRET=RANDOM-LONG-VALUE
   ```

6. Deploy all three functions. `config.toml` already disables JWT verification for
   the webhook and scheduler, so this also fixes the current 401:

   ```powershell
   .\.tooling\supabase\supabase.exe functions deploy
   ```

7. In Xendit TEST mode, set the Invoice callback/webhook URL to
   `https://bnomvznpwasejddetmte.supabase.co/functions/v1/xendit-webhook`
   and enable GCash.

8. Create the admin user in Authentication > Users, copy its UUID, then run:

   ```sql
   insert into public.jj_admins (user_id) values ('THE-AUTH-USER-UUID')
   on conflict do nothing;
   ```

9. Run `flutter run -d chrome --web-port=8080` so the origin matches
   `ALLOWED_ORIGINS`, then complete one payment with the Xendit GCash simulator.

The detailed steps below remain the reference for the security model and the
required acceptance tests.

## Apply the backend
From an environment with Supabase CLI access to your project:

1. Review and apply supabase/migrations/202610270001_jjs_store.sql using
   supabase db push (after linking the existing project). It preserves product rows
   and adds metadata fields. It replaces product access policies with public
   published-catalog reads and admin-only updates.
2. The old public.orders table is locked against anon/authenticated access.
   Existing legacy orders are not copied into jj_orders because they have no
   established guest ownership. Migrate verified ownership separately if needed.
3. Enable anonymous sign-ins in Supabase Authentication. Browsing requires no auth;
   checkout, addresses and orders create an owned guest session automatically.
   Guest history is tied to that browser/device session.
4. Populate the actual products' stock, finishes, dimensions, descriptions, ratings
   and prices from your real inventory. NULL stock prevents checkout. No demo product
   rows are seeded. The optional section 8b and
   supabase/update_product_ratings_reviews.sql add sample ratings and three reviews
   per showroom product; edit or remove that content before production use. Supplied
   local photos are mapped by the six exact product names.
5. Create the administrator through Supabase Auth. In a trusted SQL session, add
   that existing auth user's UUID to public.jj_admins. Users cannot grant themselves
   admin access. Admin roles do not depend on editable user metadata.
6. Configure server-only Edge Function secrets:
   XENDIT_SECRET_KEY (xnd_development_... TEST key),
   XENDIT_WEBHOOK_TOKEN (Xendit's webhook verification token),
   ALLOWED_ORIGINS (comma-separated exact web origins, including local test origin),
   RECONCILE_SECRET (independent random scheduler secret).
   Supabase supplies SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY.
7. Deploy create-invoice, xendit-webhook and reconcile-orders. JWT verification is
   enabled for create-invoice and disabled for the separately authenticated webhook
   and scheduler in config.toml. Replace the existing create-invoice implementation
   only after applying its new schema.
8. In Xendit TEST mode, configure the Invoice callback URL:
   https://YOUR_PROJECT.supabase.co/functions/v1/xendit-webhook
   Enable GCash in the account. The function restricts invoices to PHP and GCASH.
9. Schedule a POST to reconcile-orders every minute from a server scheduler,
   authenticated with Authorization: Bearer RECONCILE_SECRET. It verifies provider
   state before releasing abandoned reservations. Do not put that secret in Flutter.
   For a Supabase-hosted schedule, run `supabase/schedule_reconcile.sql` after
   replacing its Vault secret placeholder with the same RECONCILE_SECRET value.

## Stock and reservation recovery

Checkout reserves stock when `jj_reserve_order` creates a PENDING order. If the
customer never pays, the reservation is released only when `reconcile-orders`
expires the Xendit invoice and calls `jj_finish_order`. This is why the every-minute
schedule above is required: without it, abandoned checkouts keep their units
reserved indefinitely.

To inspect reservations and restore the catalog, run
`supabase/restock_products.sql`. It lists PENDING orders, shows current stock, and
sets every published product to the chosen quantity. Change the `50` in that file
to the real available inventory before using it in production.

The 8% calculation reproduces the prototype. Confirm the business tax rule before
enabling live payments; this implementation deliberately rejects live Xendit keys.

## Offline handler checks

Run with Node 24:

```powershell
node --experimental-vm-modules --test supabase/tests/edge_functions.test.mjs
```

Latest run: 31 tests passed. The runner executes the TypeScript handler code
with test doubles for Supabase and Xendit, without network requests. It covers
session checks, CORS, malformed carts, server order totals, invoice retries,
provider rejection/timeouts, invoice identity/amount checks, callback verification,
database write failures and reconciliation during a racing payment.

The run found and fixed malformed checkout JSON/null payloads returning HTTP 503
instead of HTTP 400, null cart entries returning HTTP 503, and a missing provider
invoice ID being accepted. These checks do not execute PostgreSQL functions,
RLS policies, the real Supabase SDK or Xendit's sandbox. Those remain pending.

## Read-only remote inspection

Run `supabase/verify_backend.sql` in SQL Editor to inspect the installed tables,
required columns, RLS policies and function permissions. The script has not been
executed here. It does not replace isolation or payment acceptance tests.

## Required remote acceptance tests (not executed here)

- Anonymous public catalog read succeeds; no mandatory sign-in route is shown.
- Guest A cannot read guest B's orders/addresses, even with guessed UUIDs.
- Non-admin direct product writes and fulfillment RPC calls are rejected.
- Admin changes stock/price; the public catalog reflects those changes on refresh.
- Submit a tampered client price: invoice uses the database price (request prices
  are not consumed). Invalid quantities/finishes and insufficient stock fail.
- Concurrent checkouts for the last unit: exactly one reservation succeeds.
- Retry one request_id: one order, one stock deduction, at most one invoice POST.
- Complete GCash payment using the Xendit simulator; only a verified provider
  PAID/SETTLED state changes the order to PAID.
- Wrong webhook token and mismatched provider currency/amount/order are rejected.
- Replay webhook: no double stock deduction or release.
- Expire payment: webhook/reconciliation restores stock once.
- Simulate provider timeout, delayed callback and failed database writes; retry
  safely recovers the existing invoice, or reconciliation expires it.
- Verify release Android payment/deep-link behavior on an actual phone.

Read and run supabase/tests/checkout.sql against a LOCAL disposable Supabase
database after migration. Its fixtures are rolled back. Neither those SQL tests
nor remote test-mode payment tests have been executed in this workspace.

References consulted: [Supabase anonymous sessions](https://supabase.com/docs/guides/auth/auth-anonymous),
[Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security),
[Xendit invoice parameters](https://github.com/xendit/xendit-node/blob/master/docs/invoice/CreateInvoiceRequest.md),
[Xendit webhook verification](https://docs.xendit.co/docs/handling-webhooks).

