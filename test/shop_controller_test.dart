import 'package:flutter_test/flutter_test.dart';
import 'package:jjs_furniture/state/shop_controller.dart';

import 'fixtures/catalog.dart';

void main() {
  late FixtureService service;
  late ShopController shop;
  setUp(() async {
    service = FixtureService();
    shop = ShopController(service: service);
    await shop.load();
  });
  tearDown(() => shop.dispose());
  test('search combines all words and category filters', () {
    shop.updateFilters(search: 'oak', collection: 'Bedroom');
    expect(shop.filtered.map((p) => p.name), ['Scandi Oak Bed']);
    shop.updateFilters(search: 'chair', collection: 'All');
    expect(shop.filtered.length, 2);
    shop.updateFilters(collection: 'Office');
    expect(shop.filtered.single.name, 'Ergo Office Chair');
  });
  test('wishlist and sorting change the catalog view', () {
    shop.toggleSaved(catalog[1]);
    shop.updateFilters(wishlistOnly: true);
    expect(shop.filtered.single.id, 2);
    shop.updateFilters(
      wishlistOnly: false,
      order: 'Price: low to high',
      stockOnly: true,
    );
    expect(shop.filtered.first.name, 'Ergo Office Chair');
    expect(shop.filtered.length, 5);
  });
  test(
    'cart amounts match the PDF and quantity updates recalculate in cents',
    () {
      expect(shop.add(catalog.first), true);
      expect(shop.subtotalCents, 5299900);
      expect(shop.taxCents, 423992);
      expect(shop.totalCents, 5723892);
      shop.setQuantity(shop.cart.single, 2);
      expect(shop.totalCents, 11447784);
      shop.setQuantity(shop.cart.single, 0);
      expect(shop.count, 0);
      expect(shop.totalCents, 0);
    },
  );
  test('stock limits aggregate different finishes', () {
    expect(shop.add(catalog.first, quantity: 3, finish: '#FFFFFF'), true);
    expect(shop.add(catalog.first, quantity: 3, finish: '#202020'), false);
    expect(shop.add(catalog.first, quantity: 2, finish: '#202020'), true);
    expect(shop.count, 5);
    shop.setQuantity(shop.cart.last, 3);
    expect(shop.count, 5);
    expect(shop.add(catalog.last), false);
    expect(shop.add(catalog.first, quantity: -1), false);
  });
  test('invalid finish cannot be added', () {
    expect(shop.add(catalog.first, finish: '#FF0000'), false);
  });
  test('loading failure shows an error without demo fallback', () async {
    service.fail = true;
    final emptyShop = ShopController(service: service);
    await emptyShop.load();
    expect(emptyShop.products, isEmpty);
    expect(emptyShop.error, isNotNull);
    expect(emptyShop.loading, false);
    emptyShop.dispose();
  });
}
