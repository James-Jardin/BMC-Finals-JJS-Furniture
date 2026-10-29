# JJ's Furniture: reference audit and implementation plan

Source: reference/JJS-FURNITURE.pdf. Five pages, each 414 x 896 PDF units,
rendered at 518 x 1120. All pages and all six supplied photos were visually
inspected BEFORE application edits. PDF screenshots are raster images; exact
font identification is not possible.

## Measured tokens
Background #131117; card #211913; header #19110C; navigation #261D17;
selected navigation #5C4130; copper #C67C4E; primary button #FFB68C;
cream #FAF8F3. Secondary text approximately #D7C4B5; headings approximately
#E8E1EC. Roboto-like sans serif, page/section titles 24, product names 14-16,
body 14-16, secondary 12-14. Cards radius approximately 16, photos radius 20,
primary buttons capsule, cart steppers outlined rounded squares.

## Screen-by-screen plan and existing-code differences
1. Shop (page 1): 60-high brand header, sofa logo and cart badge. Search x14/y69
   approximately 324x59, filter at right. Horizontal category chips at y142.
   Sale banner x14/y200, 383x160, gradient brown with title, subtitle, Shop now,
   sofa outline. Featured at y395, saved count right. Grid starts y450; two
   columns approximately 177 wide with 22 gap. Square images, category pills,
   heart disks, ratings, copper prices, circular plus. Bottom navigation 78 high.
   Existing: indigo Campus Store app bar, list tiles, 56-square photos, Buy Now.
   All prototype sections missing.
2. Details (page 2): full-width image approximately 354 high, overlay back/heart/
   share. Name/price y379; rating/category/stock y420. Finish swatches, quantity
   capsule. Dimensions panel x24/y567 approximately 367x136 with three cream tiles.
   Description y734. Fixed total and Add to Cart footer y789, 107 high.
   Existing: no details screen.
3. Cart (page 3): Your Cart count header and Clear. Item x20/y80, 372x104, 68-square
   image, name/unit price/finish, steppers and line total. Flexible empty space.
   Fixed WHITE summary above navigation, subtotal, Tax (8%), divider, total,
   peach Checkout. Sample 52999 + 4239.92 = 57238.92. Existing: no cart.
4. Dashboard (page 4): Store overview and Live from catalog + cart state. Two-by-two
   cards approximately 179x172, gap 22: Cart revenue, Products/out of stock,
   Avg rating, Categories. Category bars: Living Room 2, Bedroom 2, Dining 1,
   Office 1 in captured sample. Top rated heading and partially visible first row.
   Existing: no dashboard.
5. Account (page 5): guest panel x20/y82, 371x105, F avatar, Furniture lover,
   Browsing as guest. Cart summary x20/y208, 371x59. Menu x20/y288: Orders/
   Track past purchases, Wishlist/Your saved pieces, Addresses; dividers/chevrons.
   Existing: generic order list only.

Implement shared theme/state/navigation, then Shop, Details, Cart, Dashboard,
Account; connect secure backend and capture all five screens for comparison.
Keep real catalog reads. Map supplied photos to exact product names.

## Explicit uncertainties / adaptations
- NO DESKTOP reference exists. Desktop uses the same header, bottom navigation,
  colors/components, additional grid columns and side-by-side product details.
- Exact font, offscreen descriptions/top-rated content, filters, checkout, admin,
  addresses, wishlist and order screens are unspecified extensions.
- Keep total amounts readable; do not reproduce the reference's clipped details
  total. Allow wrapping and scrolling on narrower screens.
- Database owns prices, stock, ratings, dimensions, finishes. Missing metadata is
  not replaced by invented ratings, stock or dimensions.
- Prototype 8% tax must be calculated server-side. Confirm business applicability
  before live payments.
- Sample wishlist/cart counts are captured state, not real-user defaults.

## Backend audit
No existing migrations or Edge Function source. Original invoice sends client
product_name/amount; original orders query selects all orders without ownership.
RLS cannot be verified from Flutter. Product model initially only id/name/price/
image_url. Add reviewable migrations, public catalog reads, owned guest sessions,
server prices/tax, atomic stock reservation, verified webhooks, protected admins.
Deployment needs Supabase management access and server-side Xendit TEST secrets.

## Verification
Compare Flutter at 414x896 against normalized reference pages; additionally check
360x800, 1440x1000 and actual Android when runnable. Test fixture catalog data is
restricted to automated tests; production never falls back to demo data.
Record actual screenshots, execution failures and remaining differences in
VISUAL_VERIFICATION.md. Compilation alone is not visual acceptance.

