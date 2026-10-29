import 'package:flutter_test/flutter_test.dart';
import 'package:jjs_furniture/models/product_model.dart';

void main() {
  test('parses embedded product reviews', () {
    final product = Product.fromMap({
      'id': 1,
      'name': 'Marble Dining Table',
      'price': 100,
      'rating': 4.7,
      'reviews': [
        {'name': 'Sofia Mendoza', 'rating': 5, 'comment': 'Beautiful table.'},
        {'name': 'Daniel Lim', 'rating': 4, 'comment': 'Very sturdy.'},
      ],
    });

    expect(product.reviews, hasLength(2));
    expect(product.reviews.first.name, 'Sofia Mendoza');
    expect(product.reviews.first.rating, 5);
    expect(product.reviews.last.comment, 'Very sturdy.');
  });

  test('handles products without reviews', () {
    final product = Product.fromMap({'id': 2, 'name': 'Chair', 'price': 50});

    expect(product.reviews, isEmpty);
  });
}
