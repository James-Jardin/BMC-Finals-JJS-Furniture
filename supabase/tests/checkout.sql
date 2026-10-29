-- Run only in a disposable LOCAL Supabase instance, after migrations.
-- All test records and inventory changes roll back.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(10);

insert into auth.users(id, email) values ('10000000-0000-0000-0000-000000000001','fixture@example.invalid');
create temporary table fixture_product(id bigint);
with p as (
 insert into public.products(name,price,stock,finishes,published)
 values ('CHECKOUT TEST ONLY',52999,2,array['#FFFFFF'],true) returning id
) insert into fixture_product select id from p;
create temporary table fixture_order(data jsonb);
insert into fixture_order select public.jj_reserve_order(
 '10000000-0000-0000-0000-000000000001',
 'fixture-request-0001',
 jsonb_build_array(jsonb_build_object('product_id',(select id from fixture_product),
   'quantity',2,'finish','#FFFFFF')),
 '{"name":"Fixture","email":"fixture@example.invalid","phone":"09123456789","address":"Fixture"}'
);
select is((select (data->>'subtotal_cents')::bigint from fixture_order),10599800::bigint,'server uses database price');
select is((select (data->>'tax_cents')::bigint from fixture_order),847984::bigint,'tax uses integer rounding');
select is((select stock from public.products where id=(select id from fixture_product)),0,'reservation subtracts inventory');
select is((public.jj_reserve_order(
 '10000000-0000-0000-0000-000000000001','fixture-request-0001',
 jsonb_build_array(jsonb_build_object('product_id',(select id from fixture_product),'quantity',2,'finish','#FFFFFF')),
 '{}')->>'id'),(select data->>'id' from fixture_order),'retry returns original order');
select is((select stock from public.products where id=(select id from fixture_product)),0,'retry does not subtract twice');
select throws_ok(format(
 'select public.jj_reserve_order(%L,%L,%L::jsonb,%L::jsonb)',
 '10000000-0000-0000-0000-000000000001','fixture-request-0002',
 jsonb_build_array(jsonb_build_object('product_id',(select id from fixture_product),'quantity',1,'finish','#FFFFFF'))::text,
 '{}'),'P0001','Insufficient stock','oversell is rejected');
select public.jj_finish_order((select (data->>'id')::uuid from fixture_order),'EXPIRED',null,
 (select (data->>'total_cents')::bigint from fixture_order));
select is((select stock from public.products where id=(select id from fixture_product)),2,'expiry restores stock');
select public.jj_finish_order((select (data->>'id')::uuid from fixture_order),'EXPIRED',null,
 (select (data->>'total_cents')::bigint from fixture_order));
select is((select stock from public.products where id=(select id from fixture_product)),2,'callback replay does not restore twice');
set local role authenticated;
select throws_ok('select public.jj_fulfill_order(''00000000-0000-0000-0000-000000000001'')',
 'P0001','Forbidden','non-admin cannot fulfill');
select is((select count(*)::integer from public.jj_orders),0,'session without ownership sees no orders');
reset role;
select * from finish();
rollback;

