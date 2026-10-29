import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/shop_controller.dart';
import '../theme/jj_theme.dart';
import '../widgets/shop_widgets.dart';
import 'product_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final ShopController shop;
  const DashboardScreen({super.key, required this.shop});
  @override
  Widget build(BuildContext context) {
    if (shop.loading) return const Center(child: CircularProgressIndicator());
    if (shop.error != null) {
      return ShopMessage(
        icon: Icons.cloud_off,
        title: 'Store overview unavailable',
        description: shop.error,
        action: shop.load,
      );
    }
    final categories = <String, int>{};
    for (final p in shop.products) {
      if (p.category.isNotEmpty) {
        categories.update(p.category, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final rated = shop.products.where((p) => p.rating != null).toList()
      ..sort((a, b) => b.rating!.compareTo(a.rating!));
    final average = rated.isEmpty
        ? null
        : rated.fold(0.0, (n, p) => n + p.rating!) / rated.length;
    final maxCount = categories.values.fold(1, math.max);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return ContentWidth(
      child: RefreshIndicator(
        onRefresh: shop.load,
        edgeOffset: 8,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store overview',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Live from catalog + cart state',
                        style: TextStyle(fontSize: 13, color: JJ.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const StatusPill(
                  label: 'Live',
                  icon: Icons.circle,
                  foreground: JJ.success,
                  background: Color(0x1F9DB985),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, c) {
                final columns = c.maxWidth >= 850 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1,
                  mainAxisExtent: textScale > 1.1 ? 196 : 166,
                  children: [
                    stat(
                      context,
                      Icons.payments_outlined,
                      JJ.money(shop.subtotalCents / 100),
                      'Cart revenue',
                      '${shop.count} units in cart',
                      JJ.gold,
                    ),
                    stat(
                      context,
                      Icons.weekend_outlined,
                      shop.products.length.toString(),
                      'Products',
                      '${shop.products.where((p) => p.stock == 0).length} out of stock',
                      JJ.success,
                    ),
                    stat(
                      context,
                      Icons.star_border_rounded,
                      average?.toStringAsFixed(1) ?? '—',
                      'Avg rating',
                      'Across all products',
                      JJ.gold,
                    ),
                    stat(
                      context,
                      Icons.category_outlined,
                      categories.length.toString(),
                      'Categories',
                      'Active collections',
                      JJ.success,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Catalog by category',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Text(
                  '${categories.length} collections',
                  style: const TextStyle(fontSize: 12, color: JJ.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BrownPanel(
              child: categories.isEmpty
                  ? const Text('No categories in the catalog yet.')
                  : Column(
                      children: sortedCategories
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 94,
                                    child: Text(
                                      e.key,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: JJ.text,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _CategoryBar(
                                      value: e.value / maxCount,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 26,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: JJ.cardRaised,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: JJ.line),
                                    ),
                                    child: Text(
                                      e.value.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: JJ.text,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Top rated',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (rated.isNotEmpty)
                  Text(
                    '${rated.length} rated',
                    style: const TextStyle(fontSize: 12, color: JJ.muted),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (rated.isEmpty)
              const BrownPanel(child: Text('No rated products yet.'))
            else
              ...rated.take(3).toList().asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BrownPanel(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      leading: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: ProductPhoto(entry.value),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xE619110C),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: JJ.peach,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        entry.value.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: RatingStars(entry.value.rating),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            JJ.money(entry.value.price),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: JJ.copper,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: JJ.muted,
                            size: 19,
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            product: entry.value,
                            shop: shop,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget stat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    String note,
    Color accent,
  ) => BrownPanel(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: JJ.cardRaised,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: JJ.line),
          ),
          child: Icon(icon, color: JJ.copper, size: 20),
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  color: JJ.text,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: JJ.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _CategoryBar extends StatelessWidget {
  final double value;
  const _CategoryBar({required this.value});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.clamp(0, 1)),
    duration: const Duration(milliseconds: 650),
    curve: Curves.easeOutCubic,
    builder: (context, animated, _) => ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(height: 8, color: JJ.background),
          FractionallySizedBox(
            widthFactor: animated,
            child: Container(
              height: 8,
              decoration: const BoxDecoration(gradient: JJ.copperGradient),
            ),
          ),
        ],
      ),
    ),
  );
}
