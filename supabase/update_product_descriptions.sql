-- Set the product descriptions for the matching showroom products.
-- Run in the Supabase SQL Editor if another database still has the placeholders.

begin;

update public.products as p
set description = v.description
from (values
  ('nordic lounge chair',
   'Add a touch of elegance to your home with the Nordic Lounge Chair! Featuring soft, comfortable upholstery, a stylish curved design, and sturdy wooden legs, it’s perfect for relaxing, reading, or enjoying your favorite moments. Transform any living space into a cozy and modern retreat.'),
  ('linen slipcover sofa',
   'Bring comfort and timeless elegance to your living room with the Linen Slipcover Sofa! Featuring soft linen-style upholstery, plush cushions, and a cozy design, it’s perfect for relaxing with family or entertaining guests. Its neutral color effortlessly complements any interior, creating a warm and inviting space.'),
  ('ergo office chair',
   'Upgrade your workspace with the Ergo Office Chair! Featuring a comfortable cushioned seat, supportive backrest, adjustable height, and sturdy rolling base, it combines comfort, functionality, and modern style. Perfect for home offices, study areas, and professional workspaces.'),
  ('scandi oak bed',
   'Upgrade your bedroom with the Scandi Oak Bed! Featuring a beautiful natural oak finish, a sturdy wooden frame, and a timeless minimalist design, it brings warmth and elegance to any bedroom. Perfect for creating a cozy, relaxing space where comfort meets modern style.'),
  ('walnut nightstand',
   'Add style and functionality to your bedroom with the Walnut Nightstand! Featuring a rich walnut finish, three spacious drawers, and a sleek, modern design, it keeps your bedside essentials organized while adding a touch of elegance to your space. Perfect for a neat and cozy bedroom.'),
  ('marble dining table',
   'Elevate your dining space with the Marble Dining Table! Featuring an elegant marble finish and a sturdy, modern base, it brings luxury and sophistication to every meal. Perfect for family dinners, gatherings, and everyday dining, it adds timeless style to your home.')
) as v(product_name, description)
where lower(trim(p.name)) = v.product_name
returning p.id, p.name, p.description;

commit;
