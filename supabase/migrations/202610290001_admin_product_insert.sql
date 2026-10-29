-- Let signed-in administrators add products from the in-app Admin screen.
-- Safe to run on a database that already applied 202610270001_jjs_store.sql.
begin;

grant insert on public.products to authenticated;
grant usage, select on sequence public.products_id_seq to authenticated;

drop policy if exists jj_admin_product_insert on public.products;
create policy jj_admin_product_insert on public.products
  for insert to authenticated
  with check (public.jj_is_admin());

commit;
