class ProductReview {
  final String name;
  final int rating;
  final String comment;

  const ProductReview({
    required this.name,
    required this.rating,
    required this.comment,
  });

  factory ProductReview.fromMap(Map<String, dynamic> map) => ProductReview(
    name: map['name'] as String? ?? 'Customer',
    rating: (map['rating'] as num?)?.toInt() ?? 5,
    comment: map['comment'] as String? ?? '',
  );
}

class Product {
  final int id;
  final String name;
  final num price;
  final String imageUrl;
  final String category;
  final double? rating;
  final int? stock;
  final String description;
  final List<String> finishes;
  final List<ProductReview> reviews;
  final num? width;
  final num? depth;
  final num? height;

  static const suppliedImages = {
    'marble dining table': 'assets/products/marble_dining_table.jpg',
    'nordic lounge chair': 'assets/products/nordic_lounge_chair.jpg',
    'ergo office chair': 'assets/products/ergo_office_chair.jpg',
    'scandi oak bed': 'assets/products/scandi_oak_bed.jpg',
    'linen slipcover sofa': 'assets/products/linen_slipcover_sofa.jpg',
    'walnut nightstand': 'assets/products/walnut_nightstand.jpg',
  };
  String? get asset {
    final normalizedName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    final namedImage = suppliedImages[normalizedName];
    if (namedImage != null) return namedImage;

    // Also recognize the supplied photo when the product has been renamed.
    final uri = Uri.tryParse(imageUrl.trim());
    if (uri == null || uri.pathSegments.isEmpty) return null;
    final fileName = uri.pathSegments.last.toLowerCase();
    for (final path in suppliedImages.values) {
      if (path.split('/').last == fileName) return path;
    }
    return null;
  }

  bool get available => stock != null && stock! > 0;
  int get priceCents => (price * 100).round();

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.category = '',
    this.rating,
    this.stock,
    this.description = '',
    this.finishes = const [],
    this.reviews = const [],
    this.width,
    this.depth,
    this.height,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    final rawReviews = map['reviews'];
    return Product(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String,
      price: map['price'] as num,
      imageUrl: map['image_url'] as String? ?? '',
      category: map['category'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble(),
      stock: (map['stock'] as num?)?.toInt(),
      description: map['description'] as String? ?? '',
      finishes: List<String>.from(map['finishes'] as List? ?? const []),
      reviews: rawReviews is List
          ? rawReviews
                .whereType<Map>()
                .map(
                  (review) =>
                      ProductReview.fromMap(Map<String, dynamic>.from(review)),
                )
                .where((review) => review.comment.isNotEmpty)
                .toList()
          : const [],
      width: map['width_cm'] as num?,
      depth: map['depth_cm'] as num?,
      height: map['height_cm'] as num?,
    );
  }
}
