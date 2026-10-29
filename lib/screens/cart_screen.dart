import 'package:flutter/material.dart';

import '../state/shop_controller.dart';
import '../theme/jj_theme.dart';
import '../widgets/shop_widgets.dart';
import 'checkout_screen.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatelessWidget {
  final ShopController shop;
  final VoidCallback onShop;
  const CartScreen({super.key, required this.shop, required this.onShop});
  @override
  Widget build(BuildContext context) => ContentWidth(
    maxWidth: 860,
    child: Column(
      children: [
        Expanded(
          child: shop.cart.isEmpty
              ? ShopMessage(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Your cart is empty',
                  description: 'Find a piece that feels like home.',
                  actionLabel: 'Explore the shop',
                  action: onShop,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  itemCount: shop.cart.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final line = shop.cart[i];
                    final p = line.product;
                    return BrownPanel(
                      padding: const EdgeInsets.all(12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final small = constraints.maxWidth < 330;
                          final lineTotal = Text(
                            JJ.money(line.totalCents / 100),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: JJ.text,
                              fontSize: 14,
                            ),
                          );
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                      product: p,
                                      shop: shop,
                                    ),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(14),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SizedBox(
                                    width: small ? 64 : 76,
                                    height: 76,
                                    child: ProductPhoto(p),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: JJ.text,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      JJ.money(p.price) +
                                          (line.finish.isEmpty
                                              ? ''
                                              : ' · ${line.finish}'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: JJ.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        QuantityControl(
                                          quantity: line.quantity,
                                          minus: () => shop.setQuantity(
                                            line,
                                            line.quantity - 1,
                                          ),
                                          plus:
                                              p.available &&
                                                  shop.quantityFor(p) < p.stock!
                                              ? () => shop.setQuantity(
                                                  line,
                                                  line.quantity + 1,
                                                )
                                              : null,
                                        ),
                                        if (small) lineTotal,
                                        TextButton.icon(
                                          onPressed: () =>
                                              _removeLine(context, line),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 17,
                                          ),
                                          label: const Text('Remove'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: JJ.danger,
                                            minimumSize: const Size(0, 36),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!small)
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: lineTotal,
                                ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        if (shop.cart.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: JJ.cream,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .26),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Color(0xFF2B211B),
                fontSize: 15,
                fontFamily: 'Roboto',
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  amount('Subtotal', shop.subtotalCents),
                  const SizedBox(height: 9),
                  amount('Tax (8%)', shop.taxCents),
                  const Divider(
                    color: Color(0xFFD8CFC4),
                    thickness: 1,
                    height: 24,
                  ),
                  amount('Total', shop.totalCents, bold: true),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(shop: shop),
                        ),
                      ),
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: const Text('Checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
  void _removeLine(BuildContext context, CartLine line) {
    final messenger = ScaffoldMessenger.of(context);
    final product = line.product;
    final finish = line.finish;
    final quantity = line.quantity;
    if (!shop.removeLine(line)) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${product.name} removed from cart'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              shop.add(product, quantity: quantity, finish: finish),
        ),
      ),
    );
  }

  Widget amount(String label, int cents, {bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: bold ? 17 : 15,
          color: bold ? const Color(0xFF2B211B) : const Color(0xFF70625A),
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      Text(
        JJ.money(cents / 100),
        style: TextStyle(
          fontSize: bold ? 18 : 15,
          color: const Color(0xFF2B211B),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    ],
  );
}
