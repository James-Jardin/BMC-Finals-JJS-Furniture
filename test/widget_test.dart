import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jjs_furniture/main.dart';
import 'package:jjs_furniture/state/shop_controller.dart';

import 'fixtures/catalog.dart';

Future<ShopController> start(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  final shop = ShopController(service: FixtureService());
  await shop.load();
  await tester.pumpWidget(JjsFurnitureApp(shop: shop));
  await tester.pumpAndSettle();
  return shop;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/roboto-medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/roboto-bold.ttf'));
    await fonts.load();
  });

  testWidgets('public shop opens directly and search filters products', (
    tester,
  ) async {
    final shop = await start(tester, const Size(414, 896));
    expect(find.text("JJ'S FURNITURE"), findsOneWidget);
    expect(find.text('Featured (6)'), findsOneWidget);
    expect(find.text('Administrator sign-in'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('product-search')), 'oak');
    await tester.pumpAndSettle();
    expect(find.text('Featured (1)'), findsOneWidget);
    expect(find.text('Scandi Oak Bed'), findsOneWidget);
    expect(find.text('Marble Dining Table'), findsNothing);
    shop.dispose();
  });
  testWidgets('each product shows its own width, depth and height', (
    tester,
  ) async {
    final shop = await start(tester, const Size(414, 896));
    await tester.tap(find.byKey(const ValueKey('product-1')));
    await tester.pumpAndSettle();
    expect(find.text('Dimensions'), findsOneWidget);
    expect(find.text('180 cm'), findsOneWidget);
    expect(find.text('90 cm'), findsOneWidget);
    expect(find.text('75 cm'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to shop'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('product-2')));
    await tester.tap(find.byKey(const ValueKey('product-2')));
    await tester.pumpAndSettle();
    expect(find.text('74 cm'), findsOneWidget);
    expect(find.text('78 cm'), findsOneWidget);
    expect(find.text('80 cm'), findsOneWidget);
    shop.dispose();
  });
  testWidgets(
    'product card opens details, add-to-cart updates cart and summary',
    (tester) async {
      final shop = await start(tester, const Size(414, 896));
      await tester.tap(find.byKey(const ValueKey('product-1')));
      await tester.pumpAndSettle();
      expect(find.text('Dimensions'), findsOneWidget);
      expect(find.text('Customer Reviews'), findsOneWidget);
      expect(find.text('Sofia Mendoza'), findsOneWidget);
      await tester.tap(find.text('Add 1 to Cart'));
      await tester.pumpAndSettle();
      expect(shop.count, 1);
      await tester.tap(find.byTooltip('Back to shop'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-Cart')));
      await tester.pumpAndSettle();
      expect(find.text('Your Cart (1)'), findsOneWidget);
      expect(find.text('Tax (8%)'), findsOneWidget);
      expect(find.text('₱57238.92'), findsOneWidget);
      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.pumpAndSettle();
      expect(shop.count, 2);
      expect(find.text('₱114477.84'), findsOneWidget);
      shop.dispose();
    },
  );
  for (final size in [
    const Size(360, 800),
    const Size(414, 896),
    const Size(1440, 1000),
  ]) {
    testWidgets('all reference tabs and details fit $size', (tester) async {
      final shop = await start(tester, size);
      shop.add(catalog.first);
      await tester.pumpAndSettle();
      for (final tab in ['Dashboard', 'Cart', 'Account', 'Shop']) {
        await tester.tap(find.byKey(ValueKey('nav-$tab')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
      await tester.tap(find.byKey(const ValueKey('product-1')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      shop.dispose();
    });
  }
  testWidgets('checkout validates guest details without starting payment', (
    tester,
  ) async {
    final shop = await start(tester, const Size(414, 896));
    shop.add(catalog.first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-Cart')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue to payment'));
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsNWidgets(4));
    shop.dispose();
  });
  testWidgets('increased text size remains usable on mobile', (tester) async {
    final shop = await start(tester, const Size(360, 800), textScale: 1.3);
    expect(tester.takeException(), isNull);
    for (final tab in ['Dashboard', 'Account']) {
      await tester.tap(find.byKey(ValueKey('nav-$tab')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    shop.dispose();
  });
}
