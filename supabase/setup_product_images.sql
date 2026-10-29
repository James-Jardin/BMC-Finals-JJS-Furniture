-- Run in the SQL Editor of your existing Supabase project.
-- Then upload the six JPEGs from assets/products to the ROOT of product-images.
-- This changes image URLs only; it does not insert products or change prices.

begin;

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

alter table public.products
  add column if not exists image_url text not null default '';

with image_map(product_name, file_name) as (
  values
    ('Marble Dining Table',  'marble_dining_table.jpg'),
    ('Nordic Lounge Chair', 'nordic_lounge_chair.jpg'),
    ('Ergo Office Chair',   'ergo_office_chair.jpg'),
    ('Scandi Oak Bed',      'scandi_oak_bed.jpg'),
    ('Linen Slipcover Sofa','linen_slipcover_sofa.jpg'),
    ('Walnut Nightstand',   'walnut_nightstand.jpg')
)
update public.products as p
set image_url =
  'https://bnomvznpwasejddetmte.supabase.co/storage/v1/object/public/product-images/'
  || m.file_name
from image_map as m
where lower(trim(p.name)) = lower(m.product_name);

commit;

-- Run again after uploading to check each product and uploaded file.
with image_map(product_name, file_name) as (
  values
    ('Marble Dining Table',  'marble_dining_table.jpg'),
    ('Nordic Lounge Chair', 'nordic_lounge_chair.jpg'),
    ('Ergo Office Chair',   'ergo_office_chair.jpg'),
    ('Scandi Oak Bed',      'scandi_oak_bed.jpg'),
    ('Linen Slipcover Sofa','linen_slipcover_sofa.jpg'),
    ('Walnut Nightstand',   'walnut_nightstand.jpg')
)
select
  m.product_name,
  p.id is not null as product_found,
  p.image_url,
  exists (
    select 1 from storage.objects as o
    where o.bucket_id = 'product-images' and o.name = m.file_name
  ) as image_uploaded
from image_map as m
left join public.products as p
  on lower(trim(p.name)) = lower(m.product_name)
order by m.product_name;

