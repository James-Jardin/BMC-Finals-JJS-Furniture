import 'package:flutter/material.dart';

import '../state/shop_controller.dart';
import '../theme/jj_theme.dart';
import '../widgets/shop_widgets.dart';
import 'orders_screen.dart';
import 'addresses_screen.dart';

class AccountScreen extends StatelessWidget {
  final ShopController shop;
  final VoidCallback onCart;
  final VoidCallback onWishlist;
  const AccountScreen({
    super.key,
    required this.shop,
    required this.onCart,
    required this.onWishlist,
  });
  @override
  Widget build(BuildContext context) => ContentWidth(
    maxWidth: 760,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        BrownPanel(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: JJ.brandGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .16),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: JJ.copper.withValues(alpha: .25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'F',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Furniture lover',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: JJ.text,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        StatusPill(
                          label: 'Guest session',
                          icon: Icons.person_outline_rounded,
                          foreground: JJ.muted,
                          background: Color(0x1AD7C4B5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniStat(
                    label: 'Saved',
                    value: '${shop.saved.length}',
                    icon: Icons.favorite_border_rounded,
                  ),
                  const _VerticalRule(),
                  _MiniStat(
                    label: 'In cart',
                    value: '${shop.count}',
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const _VerticalRule(),
                  _MiniStat(
                    label: 'Cart total',
                    value: JJ.money(shop.totalCents / 100),
                    icon: Icons.payments_outlined,
                    accent: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BrownPanel(
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(JJ.radius),
            onTap: onCart,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: JJ.cardRaised,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: JJ.line),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: JJ.copper,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${shop.count} item(s) in cart',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: JJ.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ready whenever you are',
                          style: TextStyle(fontSize: 12, color: JJ.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    JJ.money(shop.totalCents / 100),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: JJ.copper,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: JJ.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        BrownPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              entry(
                context,
                Icons.receipt_long_outlined,
                'Orders',
                'Track past purchases',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrdersScreen(service: shop.service),
                  ),
                ),
              ),
              const Divider(indent: 68, endIndent: 16),
              entry(
                context,
                Icons.favorite_border_rounded,
                'Wishlist',
                'Your saved pieces',
                onWishlist,
                trailingText: '${shop.saved.length}',
              ),
              const Divider(indent: 68, endIndent: 16),
              entry(
                context,
                Icons.location_on_outlined,
                'Addresses',
                'Delivery locations',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddressesScreen(service: shop.service),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Guest browsing · Secure checkout with Xendit',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: JJ.outline),
        ),
      ],
    ),
  );
  Widget entry(
    BuildContext context,
    IconData icon,
    String title,
    String? subtitle,
    VoidCallback tap, {
    String? trailingText,
  }) => InkWell(
    onTap: tap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: JJ.cardRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JJ.line),
            ),
            child: Icon(icon, size: 20, color: JJ.copper),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: JJ.cream,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12.5, color: JJ.muted),
                  ),
                ],
              ],
            ),
          ),
          if (trailingText != null)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: JJ.cardRaised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: JJ.line),
              ),
              child: Text(
                trailingText,
                style: const TextStyle(
                  fontSize: 11,
                  color: JJ.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Icon(Icons.chevron_right_rounded, color: JJ.muted, size: 20),
        ],
      ),
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool accent;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = false,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: accent ? JJ.copper : JJ.muted),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: JJ.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: accent ? JJ.copper : JJ.cream,
            ),
          ),
        ),
      ],
    ),
  );
}

class _VerticalRule extends StatelessWidget {
  const _VerticalRule();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: JJ.line);
}
