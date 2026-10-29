import 'package:flutter/material.dart';

import '../state/shop_controller.dart';
import '../theme/jj_theme.dart';
import '../widgets/shop_widgets.dart';
import 'product_list_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'dashboard_screen.dart';
import 'account_screen.dart';

class ShopShell extends StatefulWidget {
  final ShopController shop;
  final int? initialProductId;
  const ShopShell({super.key, required this.shop, this.initialProductId});
  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  int index = 0;
  bool openedLink = false;
  void select(int value) => setState(() => index = value);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.shop,
    builder: (context, _) {
      final shop = widget.shop;
      if (!openedLink && !shop.loading && widget.initialProductId != null) {
        openedLink = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final product = shop.products
              .where((p) => p.id == widget.initialProductId)
              .firstOrNull;
          if (product != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProductDetailScreen(shop: shop, product: product),
              ),
            );
          } else {
            shopNotice(
              context,
              'This product is not available in the catalog.',
            );
          }
        });
      }
      final pageTitle = switch (index) {
        1 => 'Dashboard',
        2 => 'Your Cart (${shop.count})',
        3 => 'Account',
        _ => "JJ'S FURNITURE",
      };
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: index == 0 ? 68 : 56,
          titleSpacing: index == 0 ? 16 : 18,
          title: index == 0
              ? Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: JJ.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: JJ.copper.withValues(alpha: .24),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.weekend, color: Colors.white, size: 22),
                          SizedBox(height: 1),
                          Text(
                            "JJ'S",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "JJ'S FURNITURE",
                              style: TextStyle(
                                fontSize: 22,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'FURNITURE ATELIER',
                            style: TextStyle(
                              fontSize: 8.5,
                              height: 1.2,
                              color: JJ.copper,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Text(pageTitle),
          actions: [
            if (index == 0)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: IconButton(
                  tooltip: 'Open cart',
                  onPressed: () => select(2),
                  style: IconButton.styleFrom(
                    backgroundColor: JJ.cardRaised,
                    side: const BorderSide(color: JJ.line),
                  ),
                  icon: Badge.count(
                    count: shop.count,
                    isLabelVisible: shop.count > 0,
                    backgroundColor: JJ.peach,
                    textColor: JJ.header,
                    child: const Icon(Icons.shopping_bag_outlined, size: 21),
                  ),
                ),
              ),
            if (index == 2)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: shop.cart.isEmpty ? null : shop.clearCart,
                  style: TextButton.styleFrom(
                    foregroundColor: JJ.muted,
                    disabledForegroundColor: JJ.muted.withValues(alpha: .4),
                  ),
                  child: const Text('Clear'),
                ),
              ),
          ],
        ),
        body: switch (index) {
          0 => ProductListScreen(shop: shop),
          1 => DashboardScreen(shop: shop),
          2 => CartScreen(shop: shop, onShop: () => select(0)),
          _ => AccountScreen(
            shop: shop,
            onCart: () => select(2),
            onWishlist: () {
              shop.updateFilters(
                wishlistOnly: true,
                collection: 'All',
                search: '',
              );
              select(0);
            },
          ),
        },
        bottomNavigationBar: _BottomNav(
          index: index,
          cartCount: shop.count,
          onSelect: select,
        ),
      );
    },
  );
}

class _BottomNav extends StatelessWidget {
  final int index;
  final int cartCount;
  final ValueChanged<int> onSelect;
  const _BottomNav({
    required this.index,
    required this.cartCount,
    required this.onSelect,
  });
  static const labels = ['Shop', 'Dashboard', 'Cart', 'Account'];
  static const icons = [
    Icons.storefront_outlined,
    Icons.grid_view,
    Icons.shopping_cart_outlined,
    Icons.person_outline,
  ];
  static const activeIcons = [
    Icons.storefront,
    Icons.dashboard,
    Icons.shopping_cart,
    Icons.person,
  ];
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: JJ.navigation,
      border: Border(top: BorderSide(color: JJ.line)),
    ),
    child: SafeArea(
      top: false,
      child: ContentWidth(
        child: SizedBox(
          height: index == 2 || index == 3 ? 82 : 76,
          child: Row(
            children: List.generate(4, (i) {
              final active = index == i;
              return Expanded(
                child: Semantics(
                  selected: active,
                  button: true,
                  label: labels[i],
                  child: InkWell(
                    key: ValueKey('nav-${labels[i]}'),
                    onTap: () => onSelect(i),
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: 60,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: active
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF6B4B37), JJ.selected],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: active
                                  ? JJ.copper.withValues(alpha: .38)
                                  : Colors.transparent,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: .22,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Badge.count(
                              count: cartCount,
                              isLabelVisible: i == 2 && cartCount > 0,
                              backgroundColor: const Color(0xFFFFB9B3),
                              textColor: JJ.header,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  active ? activeIcons[i] : icons[i],
                                  key: ValueKey(active),
                                  size: 22,
                                  color: active
                                      ? const Color(0xFFFFDDC9)
                                      : JJ.muted.withValues(alpha: .82),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.2,
                            color: active ? JJ.cream : JJ.muted,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                          child: Text(labels[i]),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    ),
  );
}
