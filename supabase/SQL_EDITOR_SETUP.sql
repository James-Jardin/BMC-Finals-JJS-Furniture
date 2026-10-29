-- JJ'S FURNITURE: EDITABLE SUPABASE SQL SETUP
-- Run in Supabase SQL Editor as the database owner.
-- FIRST-TIME SETUP ONLY: use this file INSTEAD OF running
-- migrations/202610270001_jjs_store.sql separately. They define the same schema.
-- If that migration is already installed, run ONLY sections 8 and 8b to add
-- sample products, ratings and customer reviews.
-- Edit section 8 before running: all prices, stock, descriptions and finishes
-- there are illustrative sample values, not verified business inventory.
-- Existing matching products are retained without changing their prices or stock;
-- section 8b refreshes their ratings and sample reviews.
-- Product names match the bundled Flutter photos; an empty image_url uses them.
-- Orders are readable by their owner/admin. Payment writes use server functions.

begin;

-- 1. Products: catalog fields used by the Flutter app
create table if not exists public.products (
  id bigserial primary key,
  name text not null,
  price numeric(12,2) not null check (price >= 0),
  image_url text not null default ''
);
alter table public.products
  add column if not exists category text not null default '',
  add column if not exists description text not null default '',
  add column if not exists rating numeric(2,1) check (rating between 0 and 5),
  add column if not exists reviews jsonb not null default '[]'::jsonb,
  add column if not exists stock integer check (stock >= 0),
  add column if not exists width_cm numeric check (width_cm > 0),
  add column if not exists depth_cm numeric check (depth_cm > 0),
  add column if not exists height_cm numeric check (height_cm > 0),
  add column if not exists finishes text[] not null default '{}',
  add column if not exists published boolean not null default true;

-- Categories visible in the supplied reference, applied only to matching rows.
update public.products set category = case lower(trim(name))
  when 'marble dining table' then 'Dining'
  when 'nordic lounge chair' then 'Living Room'
  when 'ergo office chair' then 'Office'
  when 'scandi oak bed' then 'Bedroom'
  when 'linen slipcover sofa' then 'Living Room'
  when 'walnut nightstand' then 'Bedroom'
end where category = '' and lower(trim(name)) in (
  'marble dining table','nordic lounge chair','ergo office chair',
  'scandi oak bed','linen slipcover sofa','walnut nightstand');

-- 2. Administrator membership and permission helper
create table public.jj_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.jj_admins enable row level security;
revoke all on public.jj_admins from anon, authenticated;
create function public.jj_is_admin() returns boolean
language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.jj_admins where user_id = auth.uid()); $$;
revoke all on function public.jj_is_admin() from public;
grant execute on function public.jj_is_admin() to anon, authenticated;

-- 3. Product row level security: public catalog reads and admin writes
alter table public.products enable row level security;
-- Replace permissive policies, so an old policy cannot bypass the new rules.
do $$ declare p record; begin
  for p in select policyname from pg_policies where schemaname='public' and tablename='products'
  loop execute format('drop policy %I on public.products', p.policyname); end loop;
end $$;
revoke all on public.products from anon, authenticated;
grant select on public.products to anon, authenticated;
grant update(name,price,image_url,category,description,rating,stock,
  width_cm,depth_cm,height_cm,finishes,published,reviews) on public.products to authenticated;
grant insert on public.products to authenticated;
grant usage, select on sequence public.products_id_seq to authenticated;
create policy jj_public_catalog on public.products for select to anon, authenticated
  using (published or public.jj_is_admin());
create policy jj_admin_product_update on public.products for update to authenticated
  using (public.jj_is_admin()) with check (public.jj_is_admin());
create policy jj_admin_product_insert on public.products for insert to authenticated
  with check (public.jj_is_admin());

do $$ begin
  if to_regclass('public.orders') is not null then
    alter table public.orders enable row level security;
    revoke all on public.orders from anon, authenticated;
  end if;
end $$;

-- 4. Orders, order items and saved customer addresses
-- Money in orders/items is stored in centavos; product.price is in pesos.
create table public.jj_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  request_id text not null check (length(request_id) between 16 and 100),
  status text not null default 'PENDING' check (status in ('PENDING','PAID','EXPIRED','FAILED')),
  fulfillment_status text not null default 'UNFULFILLED' check (fulfillment_status in ('UNFULFILLED','FULFILLED')),
  subtotal_cents bigint not null check (subtotal_cents >= 0),
  tax_cents bigint not null check (tax_cents >= 0),
  total_cents bigint not null check (total_cents = subtotal_cents + tax_cents),
  customer jsonb not null,
  invoice_id text unique,
  invoice_url text,
  invoice_started boolean not null default false,
  expires_at timestamptz not null default now() + interval '15 minutes',
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  unique(user_id, request_id)
);
create index jj_orders_owner on public.jj_orders(user_id, created_at desc);
create index jj_orders_pending on public.jj_orders(expires_at) where status = 'PENDING';
create table public.jj_order_items (
  id bigserial primary key,
  order_id uuid not null references public.jj_orders(id),
  product_id bigint not null references public.products(id),
  product_name text not null,
  finish text not null,
  quantity integer not null check (quantity between 1 and 99),
  unit_price_cents bigint not null check (unit_price_cents >= 0)
);
create index jj_order_items_order on public.jj_order_items(order_id);
create table public.jj_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(name) between 1 and 200),
  address text not null check (length(address) between 1 and 1000),
  phone text not null check (length(phone) between 1 and 30),
  created_at timestamptz not null default now()
);
-- 5. Order/address row level security
alter table public.jj_orders enable row level security;
alter table public.jj_order_items enable row level security;
alter table public.jj_addresses enable row level security;
revoke all on public.jj_orders, public.jj_order_items, public.jj_addresses from anon, authenticated;
grant select on public.jj_orders, public.jj_order_items to authenticated;
grant select, insert, delete on public.jj_addresses to authenticated;
create policy jj_orders_read on public.jj_orders for select to authenticated
  using (user_id = auth.uid() or public.jj_is_admin());
create policy jj_items_read on public.jj_order_items for select to authenticated
  using (exists(select 1 from public.jj_orders o where o.id=order_id
    and (o.user_id=auth.uid() or public.jj_is_admin())));
create policy jj_addresses_owned on public.jj_addresses for all to authenticated
  using (user_id=auth.uid()) with check (user_id=auth.uid());

-- 6. Server checkout: reserve stock, calculate totals and record payment state
create function public.jj_reserve_order(
  p_user_id uuid, p_request_id text, p_items jsonb, p_customer jsonb
) returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  existing public.jj_orders;
  order_id uuid;
  item jsonb;
  product public.products;
  subtotal bigint := 0;
  tax bigint;
  qty integer;
  finish_value text;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text || p_request_id, 0));
  select * into existing from public.jj_orders
    where user_id=p_user_id and request_id=p_request_id;
  if found then return to_jsonb(existing); end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) not between 1 and 30 then
    raise exception 'Invalid cart';
  end if;
  if (select count(*) from public.jj_orders where user_id=p_user_id
      and created_at > now()-interval '1 hour') >= 10 then
    raise exception 'Checkout rate limit reached';
  end if;
  -- Lock products consistently before checking aggregate quantities across finishes.
  perform id from public.products where id in (
    select (x->>'product_id')::bigint from jsonb_array_elements(p_items) x
  ) order by id for update;
  for item in select value from jsonb_array_elements(p_items) loop
    qty := (item->>'quantity')::integer;
    if qty is null or qty not between 1 and 99 then raise exception 'Invalid quantity'; end if;
    select * into product from public.products where id=(item->>'product_id')::bigint;
    if not found or not product.published or product.stock is null then raise exception 'Product unavailable'; end if;
    if product.stock < (select sum((x->>'quantity')::integer)
      from jsonb_array_elements(p_items) x where x->>'product_id'=item->>'product_id') then
      raise exception 'Insufficient stock';
    end if;
    if product.price is null or product.price < 0 then raise exception 'Invalid price'; end if;
    finish_value := coalesce(item->>'finish','');
    if (cardinality(product.finishes)>0 and not finish_value=any(product.finishes))
       or (cardinality(product.finishes)=0 and finish_value<>'') then
      raise exception 'Invalid finish';
    end if;
    subtotal := subtotal + round(product.price*100)::bigint * qty;
  end loop;
  if subtotal <= 0 or subtotal > 100000000 then raise exception 'Invalid checkout total'; end if;
  -- Reference prototype tax. Change here and in client display if business policy changes.
  tax := (subtotal*8+50)/100;
  insert into public.jj_orders(user_id,request_id,subtotal_cents,tax_cents,total_cents,customer)
    values(p_user_id,p_request_id,subtotal,tax,subtotal+tax,p_customer) returning id into order_id;
  for item in select value from jsonb_array_elements(p_items) loop
    select * into product from public.products where id=(item->>'product_id')::bigint;
    qty := (item->>'quantity')::integer;
    insert into public.jj_order_items(order_id,product_id,product_name,finish,quantity,unit_price_cents)
      values(order_id,product.id,product.name,coalesce(item->>'finish',''),qty,round(product.price*100));
    update public.products set stock=stock-qty where id=product.id;
  end loop;
  select * into existing from public.jj_orders where id=order_id;
  return to_jsonb(existing);
end $$;

create function public.jj_claim_invoice(p_order_id uuid) returns boolean
language plpgsql security definer set search_path = '' as $$
begin
  update public.jj_orders set invoice_started=true
    where id=p_order_id and status='PENDING' and not invoice_started;
  return found;
end $$;

create function public.jj_finish_order(
  p_order_id uuid, p_status text, p_invoice_id text, p_amount_cents bigint
) returns void language plpgsql security definer set search_path = ''
as $$
declare o public.jj_orders;
begin
  select * into o from public.jj_orders where id=p_order_id for update;
  if not found then raise exception 'Unknown order'; end if;
  if p_status not in ('PAID','EXPIRED','FAILED') then raise exception 'Invalid status'; end if;
  if p_amount_cents <> o.total_cents then raise exception 'Amount mismatch'; end if;
  if o.invoice_id is not null and o.invoice_id is distinct from p_invoice_id then
    raise exception 'Invoice mismatch';
  end if;
  if p_status='PAID' and p_invoice_id is null then raise exception 'Missing invoice'; end if;
  if o.status=p_status then return; end if;
  if o.status<>'PENDING' then raise exception 'Conflicting payment transition'; end if;
  if p_status in ('EXPIRED','FAILED') then
    update public.products p set stock=p.stock+q.quantity from (
      select product_id,sum(quantity)::integer quantity from public.jj_order_items
      where order_id=o.id group by product_id
    ) q where p.id=q.product_id;
  end if;
  update public.jj_orders set status=p_status, invoice_id=coalesce(invoice_id,p_invoice_id),
    paid_at=case when p_status='PAID' then now() else null end where id=o.id;
end $$;

-- 7. Admin fulfillment and function permissions
create function public.jj_fulfill_order(p_order_id uuid) returns void
language plpgsql security definer set search_path = ''
as $$ begin
  if not public.jj_is_admin() then raise exception 'Forbidden'; end if;
  update public.jj_orders set fulfillment_status='FULFILLED'
    where id=p_order_id and status='PAID';
  if not found then raise exception 'Only paid orders can be fulfilled'; end if;
end $$;
revoke all on function public.jj_reserve_order(uuid,text,jsonb,jsonb),
  public.jj_claim_invoice(uuid), public.jj_finish_order(uuid,text,text,bigint),
  public.jj_fulfill_order(uuid) from public, anon, authenticated;
grant execute on function public.jj_reserve_order(uuid,text,jsonb,jsonb),
  public.jj_claim_invoice(uuid), public.jj_finish_order(uuid,text,text,bigint) to service_role;
grant execute on function public.jj_fulfill_order(uuid) to authenticated;

-- 8. EDIT HERE: sample furniture products (optional)
-- Remove this section if you want an empty catalog.
-- Change price (PHP), stock, category, description and finishes as needed.
-- Finishes are color hex strings used by the app's color selector.
-- Keep these names to use the supplied local photos, or provide an HTTPS image_url.
-- Re-running this section skips matching names; it does NOT revise existing rows.
with sample_products(name, price, image_url, category, description, stock, finishes) as (
  values
    ('Marble Dining Table', 18500.00, '', 'Dining',
     'Elevate your dining space with the Marble Dining Table! Featuring an elegant marble finish and a sturdy, modern base, it brings luxury and sophistication to every meal. Perfect for family dinners, gatherings, and everyday dining, it adds timeless style to your home.',
     5, array['#FFFFFF', '#8B5E3C']::text[]),
    ('Nordic Lounge Chair', 6500.00, '', 'Living Room',
     'Add a touch of elegance to your home with the Nordic Lounge Chair! Featuring soft, comfortable upholstery, a stylish curved design, and sturdy wooden legs, it’s perfect for relaxing, reading, or enjoying your favorite moments. Transform any living space into a cozy and modern retreat.',
     10, array['#D7C4A5', '#8B5E3C']::text[]),
    ('Ergo Office Chair', 4800.00, '', 'Office',
     'Upgrade your workspace with the Ergo Office Chair! Featuring a comfortable cushioned seat, supportive backrest, adjustable height, and sturdy rolling base, it combines comfort, functionality, and modern style. Perfect for home offices, study areas, and professional workspaces.',
     8, array['#333333', '#808080']::text[]),
    ('Scandi Oak Bed', 22000.00, '', 'Bedroom',
     'Upgrade your bedroom with the Scandi Oak Bed! Featuring a beautiful natural oak finish, a sturdy wooden frame, and a timeless minimalist design, it brings warmth and elegance to any bedroom. Perfect for creating a cozy, relaxing space where comfort meets modern style.',
     4, array['#C19A6B', '#8B5E3C']::text[]),
    ('Linen Slipcover Sofa', 15900.00, '', 'Living Room',
     'Bring comfort and timeless elegance to your living room with the Linen Slipcover Sofa! Featuring soft linen-style upholstery, plush cushions, and a cozy design, it’s perfect for relaxing with family or entertaining guests. Its neutral color effortlessly complements any interior, creating a warm and inviting space.',
     6, array['#F5F5DC', '#808080']::text[]),
    ('Walnut Nightstand', 3500.00, '', 'Bedroom',
     'Add style and functionality to your bedroom with the Walnut Nightstand! Featuring a rich walnut finish, three spacious drawers, and a sleek, modern design, it keeps your bedside essentials organized while adding a touch of elegance to your space. Perfect for a neat and cozy bedroom.',
     12, array['#5C4033', '#C19A6B']::text[])
)
insert into public.products
  (name, price, image_url, category, description, stock, finishes, published)
select s.name, s.price, s.image_url, s.category, s.description,
       s.stock, s.finishes, true
from sample_products as s
where not exists (
  select 1 from public.products as p
  where lower(trim(p.name)) = lower(trim(s.name))
);

-- 8b. Ratings and reviews for the six showroom products.
-- This updates the matching rows above and is safe to run again.
alter table public.products
  add column if not exists reviews jsonb not null default '[]'::jsonb;

grant update(reviews) on public.products to authenticated;

update public.products as p
set rating = v.rating,
    reviews = v.reviews
from (values
  ('marble dining table', 5.0, $json$[
    {"name":"Sofia Mendoza","rating":5,"comment":"The marble finish looks even better in person. It instantly made our dining room feel more elegant."},
    {"name":"Daniel Lim","rating":5,"comment":"Sturdy, spacious, and easy to clean. We use it every day and it still looks brand new."},
    {"name":"Camille Torres","rating":5,"comment":"Perfect size for family dinners. The modern base is a beautiful touch and the table feels very solid."}
  ]$json$::jsonb),
  ('nordic lounge chair', 4.7, $json$[
    {"name":"Liam Navarro","rating":5,"comment":"The curved design is as comfortable as it looks. It has become my favorite reading chair."},
    {"name":"Emma Villanueva","rating":5,"comment":"The upholstery feels soft and the wooden legs give it a warm, Scandinavian look. We love it in our living room."},
    {"name":"Noah Bautista","rating":4,"comment":"Very comfortable and stylish. It was slightly firmer than expected at first, but it settled in nicely."}
  ]$json$::jsonb),
  ('linen slipcover sofa', 4.7, $json$[
    {"name":"Olivia Ramos","rating":5,"comment":"The neutral fabric goes with everything and the cushions are wonderfully plush. Our living room feels so cozy now."},
    {"name":"Ethan Dela Cruz","rating":5,"comment":"Comfortable enough for movie nights and still looks elegant. Guests always ask where we got it."},
    {"name":"Isabella Flores","rating":4,"comment":"Beautiful sofa and very comfortable. The slipcover takes a little effort to adjust, but the overall look is worth it."}
  ]$json$::jsonb),
  ('scandi oak bed', 4.7, $json$[
    {"name":"Lucas Hernandez","rating":5,"comment":"The oak finish is warm and natural, and the frame feels very sturdy. Our bedroom finally has that calm, minimalist feel."},
    {"name":"Mia Aquino","rating":5,"comment":"Beautiful craftsmanship and easy to assemble. It looks much more expensive than it is."},
    {"name":"Gabriel Castillo","rating":4,"comment":"Great quality and a timeless design. The bed is very solid; just make sure you have help moving the frame."}
  ]$json$::jsonb),
  ('ergo office chair', 4.7, $json$[
    {"name":"Maria Santos","rating":5,"comment":"The cushioned seat is genuinely comfortable for long workdays, and the adjustable height makes it easy to get the setup just right."},
    {"name":"James Reyes","rating":5,"comment":"Assembly was straightforward and the rolling base feels sturdy. My home office finally feels complete."},
    {"name":"Angela Cruz","rating":4,"comment":"Great support for my back and a clean, modern look. The armrests could be a little softer, but overall it is excellent value."}
  ]$json$::jsonb),
  ('walnut nightstand', 5.0, $json$[
    {"name":"Ava Mercado","rating":5,"comment":"The walnut finish is rich and elegant, and the three drawers are surprisingly spacious. Perfect next to our bed."},
    {"name":"Marco Tan","rating":5,"comment":"Sleek design, smooth drawers, and it arrived well packed. It keeps my bedside essentials neat."},
    {"name":"Chloe Garcia","rating":5,"comment":"A beautiful little piece that ties the bedroom together. The quality feels excellent for the price."}
  ]$json$::jsonb)
) as v(product_name, rating, reviews)
where lower(trim(p.name)) = v.product_name;

-- 8c. Dimensions for the six showroom products.
-- Safe to run again; matching rows are updated by product name.
update public.products as p
set width_cm = v.width_cm,
    depth_cm = v.depth_cm,
    height_cm = v.height_cm
from (values
  ('marble dining table', 180::numeric, 90::numeric, 75::numeric),
  ('nordic lounge chair', 74::numeric, 78::numeric, 80::numeric),
  ('linen slipcover sofa', 220::numeric, 95::numeric, 85::numeric),
  ('scandi oak bed', 160::numeric, 210::numeric, 100::numeric),
  ('ergo office chair', 68::numeric, 70::numeric, 118::numeric),
  ('walnut nightstand', 55::numeric, 45::numeric, 60::numeric)
) as v(product_name, width_cm, depth_cm, height_cm)
where lower(trim(p.name)) = v.product_name;

commit;

-- 9. OPTIONAL: revise an existing product (uncomment and use its actual ID)
-- First inspect IDs with: select id, name, price, stock from public.products;
-- update public.products
-- set price = 17500.00,
--     stock = 10,
--     description = 'Your updated description',
--     width_cm = 160,
--     depth_cm = 90,
--     height_cm = 75
-- where id = 1;

-- OPTIONAL: grant admin access to an existing Supabase Auth user.
-- Replace the UUID with the user's ID from Authentication > Users.
-- insert into public.jj_admins (user_id)
-- values ('YOUR-AUTH-USER-UUID'::uuid)
-- on conflict (user_id) do nothing;

-- View the catalog after setup.
select id, name, price, category, stock, image_url, published
from public.products
order by id;

-- 10. Hide the three old gadget demo rows from this project.
-- Safe to run even if they are already hidden or do not exist.
update public.products
set published = false
where lower(trim(name)) in (
  'mechanical gaming keyboard',
  'wireless ergonomic mouse',
  'usb-c hub multiport adapter'
);

-- 11. Final verification: furniture rows should be visible, gadgets hidden.
select id, name, price, category, stock, published
from public.products
order by id;
