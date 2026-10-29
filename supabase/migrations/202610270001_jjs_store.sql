-- No demo products, prices, stock counts, or users are inserted.
-- Existing products are retained. Existing legacy orders are locked down;
-- they need a separate ownership migration before they can be shown to guests.
begin;

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
create policy jj_public_catalog on public.products for select to anon, authenticated
  using (published or public.jj_is_admin());
create policy jj_admin_product_update on public.products for update to authenticated
  using (public.jj_is_admin()) with check (public.jj_is_admin());

do $$ begin
  if to_regclass('public.orders') is not null then
    alter table public.orders enable row level security;
    revoke all on public.orders from anon, authenticated;
  end if;
end $$;

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
commit;

