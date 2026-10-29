-- JJ's Furniture: restore inventory after products reached zero stock.
-- Run this in the Supabase Dashboard -> SQL Editor, or with:
--   .\.tooling\supabase\supabase.exe db query --linked --file supabase\restock_products.sql
--
-- The app reads stock directly from public.products. A product with stock = 0
-- is shown as "Out of stock" and cannot be added to the cart.

-- 1. Inspect the current catalog.
select id, name, stock, published
from public.products
order by id;

-- 1b. Inspect orders that may still be holding reserved stock.
-- Any PENDING order whose expires_at is in the past may still be holding units
-- until reconcile-orders runs. See docs/BACKEND_SETUP.md and
-- supabase/schedule_reconcile.sql.
select id, status, total_cents, created_at, expires_at
from public.jj_orders
where status = 'PENDING'
order by created_at desc;

-- 2. Restock every published product.
-- Change 50 to the quantity you want to make available.
begin;
update public.products
set stock = 50
where published;
commit;

-- Alternative: set individual quantities instead of one value.
-- update public.products as p
-- set stock = v.stock
-- from (values
--   ('marble dining table', 5),
--   ('nordic lounge chair', 10),
--   ('ergo office chair', 8),
--   ('scandi oak bed', 4),
--   ('linen slipcover sofa', 6),
--   ('walnut nightstand', 12)
-- ) as v(product_name, stock)
-- where lower(trim(p.name)) = v.product_name;

-- 3. Verify the new values.
select id, name, stock, published
from public.products
order by id;
