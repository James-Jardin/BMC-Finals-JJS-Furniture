# JJ's Furniture

Existing Flutter project adapted to the five-page JJ's Furniture PDF.
The app opens directly into the public Shop. Supabase supplies catalog/inventory
and owned orders; Xendit hosted GCash checkout is created by server functions.

- [Reference audit and screen plan](docs/PROTOTYPE_PLAN.md)
- [Visual comparison and verification status](docs/VISUAL_VERIFICATION.md)
- [Supabase and Xendit setup](docs/BACKEND_SETUP.md)
- Offline checkout/webhook tests: `node --experimental-vm-modules --test supabase/tests/edge_functions.test.mjs`
- Read-only Supabase schema inspection: `supabase/verify_backend.sql`
- [Editable SQL setup with optional sample furniture](supabase/furniture_setup.sql):
  for first-time setup, run this instead of the migration; revise section 8 for
  sample products or section 9 for an existing product. If the migration is
  already installed, run only the sample insert or the update you need.
- [Showroom product dimensions](supabase/update_product_dimensions.sql): sets
  width, depth and height for the six sample furniture products.
- [Restock inventory](supabase/restock_products.sql): restores stock for every
  published product and lists pending orders that may still hold reservations.
- [Schedule reservation cleanup](supabase/schedule_reconcile.sql): installs the
  every-minute pg_cron job that releases abandoned checkout reservations.
- Original PDF and all five rendered pages: docs/reference/
- Captures at 414x896, 360x800, 1440x1000: docs/screenshots/
- Post-polish browser previews: docs/preview-polish/
- Direct PDF / Flutter pairs: docs/comparisons/

Run flutter pub get, then flutter run -d chrome or flutter run for Android.
Run flutter analyze and flutter test before building.
The supplied photographs and Roboto fonts are bundled for both platforms.
The six matching furniture products display the supplied photos first, even
when their database image URLs are outdated. Product matching tolerates case,
spacing, hyphens and underscores; matching photo filenames also work for renamed
products. Other products continue to use their database image URLs.
The Marble Dining Table displays the supplied
`D:\final BMC\img\marble dining table.jpg` photo. Its existing asset filename is
kept so the image also works with the running development app.

Browser captures use tool/visual_check.mjs (Node 24 and local Chrome, no npm
dependencies). First build with flutter build web --profile --no-wasm-dry-run.
The runner serves build/web on 127.0.0.1:8765, launches a separate hidden headless
Chrome profile, and injects TEST fixtures at the Supabase network boundary.
Run python tool/compare_screenshots.py (Pillow) to pair captures with the PDF.

The production app has no demo-data fallback. Deploy the migration/functions
and populate inventory metadata before testing secure checkout. Remote payment
verification and actual-device Android screenshots remain separate acceptance
checks; see the verification report for executed results.

