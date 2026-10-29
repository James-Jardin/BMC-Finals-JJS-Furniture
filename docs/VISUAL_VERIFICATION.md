# Visual and functional verification

Status: five reference screens implemented and directly compared. Full acceptance
is still OPEN pending backend deployment/payment tests and actual Android capture.

## Reference inspection

Inspected all five original PDF pages and all six supplied product photographs
before application edits. The PDF is five MOBILE captures at 414 x 896; there
is no desktop reference. Original PDF and its full-page renders are preserved
under reference/. Desktop behavior is an adaptation, not a claim about an
unseen prototype page.

## Executed checks

| Check | Result |
| --- | --- |
| Flutter analysis, lib and test | PASS: no issues |
| Flutter tests | PASS: latest local run passed 20 tests, including product photo, rating, review and per-product dimension regression checks |
| Product photograph check | Original six-photo comparison passed; the Marble Dining Table asset was restored to its supplied real photo after a temporary Scandi Oak Bed substitution |
| Flutter Web release build | PASS (final source, --no-wasm-dry-run) |
| Flutter Web profile build | PASS; used for iterative comparisons; final captures repeated with release build |
| Chrome screenshots | 19 captures: five screens plus a second details state at three viewports, and a scrolled reviews view at 414 |
| Browser runtime exceptions | None reported in browser-results.json |
| Direct PDF / Flutter comparisons | Completed for all five pages; repeated after corrections |
| 360 x 800 layout | All five screens checked in browser and widget tests |
| 414 x 896 layout | All five screens checked in browser and widget tests |
| 1440 x 1000 layout | All five screens checked in browser and widget tests |
| Mobile enlarged text, 1.3 scale | PASS in widget tests |
| Edge Function offline handler checks | PASS: 31 Node 24 tests using Supabase/Xendit test doubles; not a Deno typecheck or remote integration test |
| Supabase SQL / RLS / reservation tests | Written in supabase/tests/checkout.sql; NOT EXECUTED |
| Live catalog / schema inspection | BLOCKED: API probe rejected with WinError 10013 |
| Test-mode GCash payment/webhook | NOT EXECUTED: deployment and server secrets required |
| Android debug APK | BLOCKED: required Flutter ARM engine artifacts are not cached; network downloads are denied |
| Actual Android device screenshots | NOT EXECUTED: adb cannot create its .android directory under managed permissions |

The production application never loads the screenshot fixtures. The browser
runner intercepts catalog requests with isolated test data so the captured cart,
wishlist and dashboard match the PDF session. Prices/ratings/stock not fully
visible in the PDF are fixture values only for the screenshots. Sample product
ratings and customer reviews are seeded separately by the catalog SQL scripts.

## Screen-by-screen comparison results

| Page | Reference features checked | Corrections and remaining differences |
| --- | --- | --- |
| 1 Shop | Header/logo/cart badge; search; horizontal categories; sale banner; saved count; two-column grid; image crops; heart/plus; active Shop navigation | Corrected search and button heights, category density, banner spacing and grid position. Brown/copper/cream palette matches measured tokens. Some card/text/icon metrics differ by a few pixels; low-contrast category text is darker for readability. |
| 2 Details | Full-width original photo; overlay controls; name/price; stars/category/right-aligned stock; finishes; quantity; dimensions; description; fixed cart footer | Corrected title price allocation, stock alignment, panel spacing and footer size. Total is kept on one readable line instead of reproducing the PDF clipping. Dimension tiles use readable dark text; photo compression/antialiasing differs from raster PDF. |
| 3 Cart | Count/Clear; original item photo; finish/unit price; steppers; line total; flexible body; white subtotal/tax/total panel; checkout; active Cart navigation | Corrected footer/button/navigation heights to align the white summary with the reference. Reference amount 52999 + 4239.92 = 57238.92 verified in integer cents. Item panel and font metrics have small differences. |
| 4 Dashboard | Store overview/subtitle; four cards; icons/values/notes; category bars/counts; Top rated; active Dashboard navigation | Corrected card width/height, category row spacing, section spacing and active icon. Values derive from catalog/cart, not constants. Some value baselines/weights differ slightly. Unspecified offscreen Top rated rows use the shared card style. |
| 5 Account | Account header; guest panel; avatar; cart summary; grouped Orders/Wishlist/Addresses; separators/chevrons; active Account navigation | Corrected guest height, menu row heights and navigation. Menu grouping now closely aligns. Admin access is below the reference viewport. Icons and exact font appearance differ slightly. |

The bundled catalog uses the supplied photos, including the real Marble Dining
Table photo. Matching products load
the supplied local photo first, so an old or slow database image URL cannot hide
it. Matching tolerates case, spacing, hyphens and underscores, and recognizes
the six photo filenames when products are renamed. Other products use database
image URLs. A local photo that fails to load falls back to the database URL.
No generated or unrelated photographs were introduced.

Desktop uses the same colors, header, bottom navigation and controls, with four
product columns at 1440 and a side-by-side details layout. A desktop composition
cannot be compared to a PDF page because none was supplied.

## Artifacts and reproduction

- screenshots/414x896-{shop,details,details-reviews,details-cart,cart,dashboard,account}.png
- screenshots/360x800-*.png
- screenshots/1440x1000-*.png
- screenshots/browser-results.json (fixture flag, viewports, runtime errors)
- comparisons/{shop,details,cart,dashboard,account}.png (PDF left, Flutter right)
- comparisons/palette-check.json

Run:
1. flutter pub get
2. flutter analyze
3. flutter test
4. flutter build web --profile --no-wasm-dry-run
5. node tool/visual_check.mjs
6. python tool/compare_screenshots.py

The browser tool uses local Chrome and Node 24's built-in WebSocket, HTTP server
and CDP, with no npm installation. Python comparison requires Pillow. Captures
use a separate hidden browser profile under ignored .tooling/.

Android builds were attempted with workspace-local SDK, Pub and Gradle caches.
The final offline Gradle attempt compiled Flutter tasks but failed resolving
io.flutter:armeabi_v7a_debug and arm64_v8a_debug engine dependencies. The online
attempt could not reach Google's Maven repository (permission denied: getsockopt).
An APK was not produced. These are host dependency/network blockers, not a claim
that an Android build or device test passed.

For actual Android, run flutter run -d YOUR_DEVICE after fixing host SDK/cache
permissions. Capture the same navigation states with:
adb exec-out screencap -p > screenshot.png
Use a binary-safe shell/redirection for PNG capture. Compare the app content
excluding system bars, using the same 414 x 896-equivalent logical viewport when
practical. Android system insets and GCash app switching require device testing.

## Backend completion

Read BACKEND_SETUP.md for the migration, anonymous auth setting, admin assignment,
Edge Function secrets/deployment, webhook and reconciliation schedule. Stock,
dimensions and finishes must come from real inventory records; missing stock
deliberately disables Add to Cart. The optional ratings/reviews script contains
sample content and should be replaced with real customer feedback before
production. Legacy unowned orders are locked down, not exposed to new guests.
Until that deployment and the remote acceptance tests pass, secure
payments/admin behavior is implemented locally but not verified against the live
project.


Product-image follow-up: supabase/setup_product_images.sql creates the public
image bucket, links existing matching product rows, and checks uploaded files.
The photos must also be uploaded through Supabase Storage. The updated image
widget passed static analysis; remote image retrieval was not tested here.
