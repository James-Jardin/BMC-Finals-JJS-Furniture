import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';
import '../services/payment_service.dart';

class CartLine {
  final Product product;
  final String finish;
  int quantity;
  CartLine(this.product, this.finish, this.quantity);
  String get key => '${product.id}:$finish';
  int get totalCents => product.priceCents * quantity;
}

class ShopController extends ChangeNotifier {
  final PaymentService service;
  final SharedPreferences? preferences;
  ShopController({required this.service, this.preferences});
  List<Product> products = [];
  final List<CartLine> cart = [];
  final Set<int> saved = {};
  bool loading = true;
  String? error;
  String query = '';
  String category = 'All';
  bool inStockOnly = false;
  bool savedOnly = false;
  String sort = 'Featured';
  bool _restored = false;

  List<String> get categories => [
    'All',
    ...{
      ...[
        'Bedroom',
        'Dining',
        'Living Room',
        'Office',
      ].where((c) => products.any((p) => p.category == c)),
      ...products.map((p) => p.category).where((c) => c.isNotEmpty),
    },
  ];
  List<Product> get filtered {
    final words = query.toLowerCase().trim().split(RegExp(r'\s+'));
    final list = products.where((p) {
      final searchable = ('${p.name} ${p.category} ${p.description}')
          .toLowerCase();
      return words.every(searchable.contains) &&
          (category == 'All' || p.category == category) &&
          (!inStockOnly || p.available) &&
          (!savedOnly || saved.contains(p.id));
    }).toList();
    switch (sort) {
      case 'Price: low to high':
        list.sort((a, b) => a.price.compareTo(b.price));
      case 'Price: high to low':
        list.sort((a, b) => b.price.compareTo(a.price));
      case 'Top rated':
        list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    }
    return list;
  }

  int get count => cart.fold(0, (n, l) => n + l.quantity);
  int get subtotalCents => cart.fold(0, (n, l) => n + l.totalCents);
  int get taxCents => (subtotalCents * 8 + 50) ~/ 100;
  int get totalCents => subtotalCents + taxCents;
  void updateFilters({
    String? search,
    String? collection,
    bool? stockOnly,
    bool? wishlistOnly,
    String? order,
  }) {
    query = search ?? query;
    category = collection ?? category;
    inStockOnly = stockOnly ?? inStockOnly;
    savedOnly = wishlistOnly ?? savedOnly;
    sort = order ?? sort;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await service.fetchProducts();
      if (!_restored) {
        _restore();
        _restored = true;
      }
      final refreshed = <CartLine>[];
      for (final line in cart) {
        final p = products.where((p) => p.id == line.product.id).firstOrNull;
        if (p != null &&
            p.available &&
            (p.finishes.isEmpty || p.finishes.contains(line.finish))) {
          final used = refreshed
              .where((l) => l.product.id == p.id)
              .fold(0, (n, l) => n + l.quantity);
          final remaining = p.stock! - used;
          if (remaining > 0) {
            refreshed.add(
              CartLine(p, line.finish, line.quantity.clamp(1, remaining)),
            );
          }
        }
      }
      cart
        ..clear()
        ..addAll(refreshed);
    } catch (_) {
      error =
          'We could not load the catalog. Check your connection and try again.';
    }
    loading = false;
    notifyListeners();
  }

  int quantityFor(Product p) =>
      cart.where((l) => l.product.id == p.id).fold(0, (n, l) => n + l.quantity);
  bool add(Product p, {int quantity = 1, String? finish}) {
    if (quantity < 1 || !p.available || quantityFor(p) + quantity > p.stock!) {
      return false;
    }
    final selected = finish ?? p.finishes.firstOrNull ?? '';
    if (p.finishes.isNotEmpty && !p.finishes.contains(selected)) return false;
    final line = cart
        .where((l) => l.product.id == p.id && l.finish == selected)
        .firstOrNull;
    if (line == null) {
      cart.add(CartLine(p, selected, quantity));
    } else {
      line.quantity += quantity;
    }
    _changed();
    return true;
  }

  void setQuantity(CartLine line, int quantity) {
    if (!cart.contains(line)) return;
    if (quantity <= 0) {
      cart.remove(line);
    } else if (line.product.stock != null &&
        quantityFor(line.product) - line.quantity + quantity <=
            line.product.stock!) {
      line.quantity = quantity;
    }
    _changed();
  }

  bool removeLine(CartLine line) {
    if (!cart.remove(line)) return false;
    _changed();
    return true;
  }

  void clearCart() {
    cart.clear();
    _changed();
  }

  void toggleSaved(Product p) {
    if (!saved.add(p.id)) saved.remove(p.id);
    _changed();
  }

  void _changed() {
    preferences?.setString(
      'jj_cart',
      jsonEncode(
        cart
            .map(
              (l) => {
                'id': l.product.id,
                'finish': l.finish,
                'quantity': l.quantity,
              },
            )
            .toList(),
      ),
    );
    preferences?.setStringList('jj_saved', saved.map((id) => '$id').toList());
    notifyListeners();
  }

  void _restore() {
    saved.addAll(
      (preferences?.getStringList('jj_saved') ?? [])
          .map(int.tryParse)
          .whereType<int>(),
    );
    try {
      final rows =
          jsonDecode(preferences?.getString('jj_cart') ?? '[]') as List;
      for (final row in rows) {
        final p = products.where((p) => p.id == row['id']).firstOrNull;
        final qty = row['quantity'];
        if (p != null && qty is int && qty > 0 && p.available) {
          add(
            p,
            quantity: qty.clamp(1, p.stock!),
            finish: row['finish'] as String?,
          );
        }
      }
    } catch (_) {
      /* Invalid local state is discarded; checkout validates again. */
    }
  }
}
