import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jjs_furniture/models/product_model.dart';
import 'package:jjs_furniture/widgets/shop_widgets.dart';

Product product(String name, {String imageUrl = ''}) =>
    Product(id: 1, name: name, price: 100, imageUrl: imageUrl);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all six supplied photos are bundled and decode successfully', () async {
    expect(Product.suppliedImages, hasLength(6));
    for (final path in Product.suppliedImages.values) {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0), reason: path);
      expect(frame.image.height, greaterThan(0), reason: path);
      frame.image.dispose();
      codec.dispose();
    }
  });

  test('supplied photos match spacing, case and filename variations', () {
    expect(
      product('  MARBLE   Dining-Table  ').asset,
      'assets/products/marble_dining_table.jpg',
    );
    expect(
      product('Nordic_Lounge_Chair').asset,
      'assets/products/nordic_lounge_chair.jpg',
    );
    expect(
      product(
        'Renamed chair',
        imageUrl:
            'https://example.com/product-images/ergo_office_chair.jpg?v=2',
      ).asset,
      'assets/products/ergo_office_chair.jpg',
    );
    expect(product('Other furniture').asset, isNull);
  });

  testWidgets('rating stars reflect the numeric rating', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RatingStars(4.7))),
    );

    expect(find.byIcon(Icons.star), findsNWidgets(4));
    expect(find.byIcon(Icons.star_half), findsOneWidget);
    expect(find.text('4.7'), findsOneWidget);
  });

  testWidgets('supplied photo displays before an unrelated database URL', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 200,
          height: 200,
          child: ProductPhoto(
            product(
              'Marble Dining Table',
              imageUrl: 'https://example.com/old-keyboard-photo.jpg',
            ),
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/products/marble_dining_table.jpg',
    );
    expect(tester.takeException(), isNull);
  });
}
