-- Add product ratings and three customer reviews for each showroom product.
-- Includes the six original pieces plus the Pengpai desk and Wooden Family Table Set.
-- Run in the Supabase SQL Editor, or with:
--   .\.tooling\supabase\supabase.exe db query --linked -f supabase/update_product_ratings_reviews.sql

begin;

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
  ]$json$::jsonb),
  ('pengpai wooden office desk', 4.8, $json$[
    {"name":"Ramon Villanueva","rating":5,"comment":"The desk is spacious and the wood finish feels premium. There is plenty of room for my monitor, laptop, and paperwork."},
    {"name":"Bea Salvador","rating":5,"comment":"Very sturdy and well made. The built-in storage and cable access keep my home office neat and organized."},
    {"name":"Miguel Fernandez","rating":4,"comment":"Assembly took some time, but the result is worth it. It looks professional and feels like it will last for years."}
  ]$json$::jsonb),
  ('wooden family table set', 5.0, $json$[
    {"name":"Andrea Lim","rating":5,"comment":"The dark wood finish looks elegant, and the table is spacious enough for our whole family. The chairs are comfortable and feel very sturdy."},
    {"name":"Paolo Reyes","rating":5,"comment":"We have used this set every day for months and it still looks beautiful. It is easy to wipe clean, and the upholstered chairs are a nice touch."},
    {"name":"Hannah Cruz","rating":5,"comment":"It arrived well packed and was straightforward to assemble. The set makes our dining room feel warm and complete."}
  ]$json$::jsonb)
) as v(product_name, rating, reviews)
where lower(trim(p.name)) = v.product_name;

commit;
