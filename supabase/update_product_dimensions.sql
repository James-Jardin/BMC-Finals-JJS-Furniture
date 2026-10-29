-- Set Width / Depth / Height for the showroom products.
-- Includes the six original pieces plus the Pengpai desk and Wooden Family Table Set.
-- Safe to run repeatedly: products are matched by name.
-- Edit the numeric values below to match the real measurements before production.

begin;

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
  ('walnut nightstand', 55::numeric, 45::numeric, 60::numeric),
  ('pengpai wooden office desk', 200::numeric, 100::numeric, 76::numeric),
  ('wooden family table set', 180::numeric, 100::numeric, 76::numeric)
) as v(product_name, width_cm, depth_cm, height_cm)
where lower(trim(p.name)) = v.product_name;

commit;

-- Confirm the values used by the product details screen.
select id, name, width_cm, depth_cm, height_cm
from public.products
where lower(trim(name)) in (
  'marble dining table',
  'nordic lounge chair',
  'linen slipcover sofa',
  'scandi oak bed',
  'ergo office chair',
  'walnut nightstand',
  'pengpai wooden office desk',
  'wooden family table set'
)
order by id;
