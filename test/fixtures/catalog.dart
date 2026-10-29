// Reference-shaped fixtures ONLY for tests. Never loaded by the application.
import 'package:jjs_furniture/models/product_model.dart';
import 'package:jjs_furniture/services/payment_service.dart';

final catalog = [
  Product(
    id: 1,
    name: 'Marble Dining Table',
    price: 52999,
    imageUrl: '',
    category: 'Dining',
    rating: 5.0,
    stock: 5,
    finishes: ['#FFFFFF', '#202020'],
    width: 180,
    depth: 90,
    height: 75,
    description: 'Elevate your dining space with the Marble Dining Table! Featuring an elegant marble finish and a sturdy, modern base, it brings luxury and sophistication to every meal. Perfect for family dinners, gatherings, and everyday dining, it adds timeless style to your home.',
    reviews: [
      ProductReview(
        name: 'Sofia Mendoza',
        rating: 5,
        comment: 'The marble finish looks even better in person. It instantly made our dining room feel more elegant.',
      ),
      ProductReview(
        name: 'Daniel Lim',
        rating: 5,
        comment: 'Sturdy, spacious, and easy to clean. We use it every day and it still looks brand new.',
      ),
      ProductReview(
        name: 'Camille Torres',
        rating: 5,
        comment: 'Perfect size for family dinners. The modern base is a beautiful touch and the table feels very solid.',
      ),
    ],
  ),
  Product(
    id: 2,
    name: 'Nordic Lounge Chair',
    price: 14999,
    imageUrl: '',
    category: 'Living Room',
    rating: 4.7,
    stock: 4,
    width: 74,
    depth: 78,
    height: 80,
    description: 'Add a touch of elegance to your home with the Nordic Lounge Chair! Featuring soft, comfortable upholstery, a stylish curved design, and sturdy wooden legs, it’s perfect for relaxing, reading, or enjoying your favorite moments. Transform any living space into a cozy and modern retreat.',
    reviews: [
      ProductReview(
        name: 'Liam Navarro',
        rating: 5,
        comment: 'The curved design is as comfortable as it looks. It has become my favorite reading chair.',
      ),
      ProductReview(
        name: 'Emma Villanueva',
        rating: 5,
        comment: 'The upholstery feels soft and the wooden legs give it a warm, Scandinavian look. We love it in our living room.',
      ),
      ProductReview(
        name: 'Noah Bautista',
        rating: 4,
        comment: 'Very comfortable and stylish. It was slightly firmer than expected at first, but it settled in nicely.',
      ),
    ],
  ),
  Product(
    id: 3,
    name: 'Linen Slipcover Sofa',
    price: 32999,
    imageUrl: '',
    category: 'Living Room',
    rating: 4.7,
    stock: 2,
    width: 220,
    depth: 95,
    height: 85,
    description: 'Bring comfort and timeless elegance to your living room with the Linen Slipcover Sofa! Featuring soft linen-style upholstery, plush cushions, and a cozy design, it’s perfect for relaxing with family or entertaining guests. Its neutral color effortlessly complements any interior, creating a warm and inviting space.',
    reviews: [
      ProductReview(
        name: 'Olivia Ramos',
        rating: 5,
        comment: 'The neutral fabric goes with everything and the cushions are wonderfully plush. Our living room feels so cozy now.',
      ),
      ProductReview(
        name: 'Ethan Dela Cruz',
        rating: 5,
        comment: 'Comfortable enough for movie nights and still looks elegant. Guests always ask where we got it.',
      ),
      ProductReview(
        name: 'Isabella Flores',
        rating: 4,
        comment: 'Beautiful sofa and very comfortable. The slipcover takes a little effort to adjust, but the overall look is worth it.',
      ),
    ],
  ),
  Product(
    id: 4,
    name: 'Scandi Oak Bed',
    price: 28999,
    imageUrl: '',
    category: 'Bedroom',
    rating: 4.7,
    stock: 3,
    width: 160,
    depth: 210,
    height: 100,
    description: 'Upgrade your bedroom with the Scandi Oak Bed! Featuring a beautiful natural oak finish, a sturdy wooden frame, and a timeless minimalist design, it brings warmth and elegance to any bedroom. Perfect for creating a cozy, relaxing space where comfort meets modern style.',
    reviews: [
      ProductReview(
        name: 'Lucas Hernandez',
        rating: 5,
        comment: 'The oak finish is warm and natural, and the frame feels very sturdy. Our bedroom finally has that calm, minimalist feel.',
      ),
      ProductReview(
        name: 'Mia Aquino',
        rating: 5,
        comment: 'Beautiful craftsmanship and easy to assemble. It looks much more expensive than it is.',
      ),
      ProductReview(
        name: 'Gabriel Castillo',
        rating: 4,
        comment: 'Great quality and a timeless design. The bed is very solid; just make sure you have help moving the frame.',
      ),
    ],
  ),
  Product(
    id: 5,
    name: 'Ergo Office Chair',
    price: 9999,
    imageUrl: '',
    category: 'Office',
    rating: 4.7,
    stock: 6,
    width: 68,
    depth: 70,
    height: 118,
    description: 'Upgrade your workspace with the Ergo Office Chair! Featuring a comfortable cushioned seat, supportive backrest, adjustable height, and sturdy rolling base, it combines comfort, functionality, and modern style. Perfect for home offices, study areas, and professional workspaces.',
    reviews: [
      ProductReview(
        name: 'Maria Santos',
        rating: 5,
        comment: 'The cushioned seat is genuinely comfortable for long workdays, and the adjustable height makes it easy to get the setup just right.',
      ),
      ProductReview(
        name: 'James Reyes',
        rating: 5,
        comment: 'Assembly was straightforward and the rolling base feels sturdy. My home office finally feels complete.',
      ),
      ProductReview(
        name: 'Angela Cruz',
        rating: 4,
        comment: 'Great support for my back and a clean, modern look. The armrests could be a little softer, but overall it is excellent value.',
      ),
    ],
  ),
  Product(
    id: 6,
    name: 'Walnut Nightstand',
    price: 6999,
    imageUrl: '',
    category: 'Bedroom',
    rating: 5.0,
    stock: 0,
    width: 55,
    depth: 45,
    height: 60,
    description: 'Add style and functionality to your bedroom with the Walnut Nightstand! Featuring a rich walnut finish, three spacious drawers, and a sleek, modern design, it keeps your bedside essentials organized while adding a touch of elegance to your space. Perfect for a neat and cozy bedroom.',
    reviews: [
      ProductReview(
        name: 'Ava Mercado',
        rating: 5,
        comment: 'The walnut finish is rich and elegant, and the three drawers are surprisingly spacious. Perfect next to our bed.',
      ),
      ProductReview(
        name: 'Marco Tan',
        rating: 5,
        comment: 'Sleek design, smooth drawers, and it arrived well packed. It keeps my bedside essentials neat.',
      ),
      ProductReview(
        name: 'Chloe Garcia',
        rating: 5,
        comment: 'A beautiful little piece that ties the bedroom together. The quality feels excellent for the price.',
      ),
    ],
  ),
];

class FixtureService extends PaymentService {
  bool fail = false;
  int fetchCount = 0;
  @override
  Future<List<Product>> fetchProducts() async {
    fetchCount++;
    if (fail) throw StateError('Offline');
    return catalog;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOrders() async => [];
  @override
  Future<List<Map<String, dynamic>>> fetchAddresses() async => [];
  @override
  Future<bool> isAdmin() async => false;
}
