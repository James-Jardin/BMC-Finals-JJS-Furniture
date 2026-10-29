-- Read-only deployment inspection. Run in Supabase SQL Editor.
-- Missing objects appear as false. Inspect policies/grants in the later results.
-- This does not verify Edge Function deployment, secrets or payment processing.
begin read only;

-- 1. Required tables and row level security.
with expected(table_name) as (
  values ('products'), ('jj_admins'), ('jj_orders'),
         ('jj_order_items'), ('jj_addresses')
)
select e.table_name,
       c.oid is not null as table_exists,
       coalesce(c.relrowsecurity, false) as rls_enabled
from expected e
left join pg_namespace n on n.nspname = 'public'
left join pg_class c on c.relnamespace = n.oid
  and c.relname = e.table_name and c.relkind in ('r', 'p')
order by e.table_name;

-- 2. Columns needed in addition to the original products/orders example.
with expected(table_name, column_name) as (
  values ('products', 'category'), ('products', 'description'),
         ('products', 'stock'), ('products', 'finishes'),
         ('products', 'published'), ('products', 'rating'),
         ('products', 'reviews'), ('products', 'width_cm'), ('products', 'depth_cm'),
         ('products', 'height_cm'), ('jj_orders', 'user_id'),
         ('jj_orders', 'request_id'), ('jj_orders', 'total_cents'),
         ('jj_orders', 'invoice_started'), ('jj_orders', 'expires_at'),
         ('jj_order_items', 'order_id'), ('jj_order_items', 'product_id'),
         ('jj_addresses', 'user_id')
)
select e.table_name, e.column_name, c.column_name is not null as column_exists
from expected e
left join information_schema.columns c on c.table_schema = 'public'
  and c.table_name = e.table_name and c.column_name = e.column_name
order by e.table_name, e.column_name;

-- 3. Checkout functions and their execution permissions.
-- reserve/claim/finish should allow service_role, with anon/authenticated false.
-- is_admin permits anon/authenticated; fulfill permits authenticated only.
with expected(signature) as (
  values ('public.jj_is_admin()'),
         ('public.jj_reserve_order(uuid,text,jsonb,jsonb)'),
         ('public.jj_claim_invoice(uuid)'),
         ('public.jj_finish_order(uuid,text,text,bigint)'),
         ('public.jj_fulfill_order(uuid)')
)
select e.signature, p.oid is not null as function_exists,
       p.prosecdef as security_definer,
       has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
       has_function_privilege('service_role', p.oid, 'EXECUTE') as service_execute
from expected e
left join pg_proc p on p.oid = to_regprocedure(e.signature)
order by e.signature;

-- 4. Inspect the actual policies and table grants for accidental public access.
-- Owned order/address policies should use auth.uid(); admin access uses jj_is_admin().
select tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('products','orders','jj_admins','jj_orders','jj_order_items','jj_addresses')
order by tablename, policyname;

select table_name, grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in ('products','orders','jj_admins','jj_orders','jj_order_items','jj_addresses')
  and grantee in ('PUBLIC','anon','authenticated','service_role')
order by table_name, grantee, privilege_type;

commit;
