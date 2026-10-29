import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../state/shop_controller.dart';
import '../theme/jj_theme.dart';
import '../widgets/shop_widgets.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final ShopController shop;
  const ProductListScreen({super.key, required this.shop});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final TextEditingController search = TextEditingController(
    text: widget.shop.query,
  );
  final scroll = ScrollController();
  @override
  void dispose() {
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  void filters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 620),
      builder: (context) => AnimatedBuilder(
        animation: widget.shop,
        builder: (context, _) {
          final shop = widget.shop;
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                          Icons.tune_rounded,
                          color: JJ.peach,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filter & sort',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Narrow the catalog to your space.',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close filters',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: JJ.cardRaised.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: JJ.line),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          title: const Text('In stock only'),
                          subtitle: const Text('Hide pieces awaiting stock'),
                          value: shop.inStockOnly,
                          onChanged: (v) => shop.updateFilters(stockOnly: v),
                        ),
                        const Divider(indent: 16, endIndent: 16),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          title: const Text('Saved pieces only'),
                          subtitle: const Text('Browse your wishlist'),
                          value: shop.savedOnly,
                          onChanged: (v) => shop.updateFilters(wishlistOnly: v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    key: ValueKey('sort-${shop.sort}'),
                    initialValue: shop.sort,
                    decoration: const InputDecoration(
                      labelText: 'Sort products',
                      filled: true,
                      fillColor: JJ.background,
                      enabledBorder: JJInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(color: JJ.line),
                      ),
                      focusedBorder: JJInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(color: JJ.peach, width: 1.5),
                      ),
                    ),
                    dropdownColor: JJ.cardRaised,
                    borderRadius: BorderRadius.circular(16),
                    menuMaxHeight: 280,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: JJ.muted,
                    ),
                    style: const TextStyle(color: JJ.text, fontSize: 15),
                    items:
                        [
                              'Featured',
                              'Price: low to high',
                              'Price: high to low',
                              'Top rated',
                            ]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                    onChanged: (v) => shop.updateFilters(order: v),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          shop.updateFilters(
                            stockOnly: false,
                            wishlistOnly: false,
                            order: 'Featured',
                          );
                        },
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Show products'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final filterCount =
        (shop.inStockOnly ? 1 : 0) +
        (shop.savedOnly ? 1 : 0) +
        (shop.sort != 'Featured' ? 1 : 0);
    return ContentWidth(
      child: RefreshIndicator(
        onRefresh: shop.load,
        edgeOffset: 8,
        child: CustomScrollView(
          controller: scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: TextField(
                              controller: search,
                              key: const ValueKey('product-search'),
                              textAlignVertical: TextAlignVertical.center,
                              style: const TextStyle(
                                color: JJ.header,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search sofa, chair, oak...',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 22,
                                  color: JJ.selected,
                                ),
                                suffixIcon: shop.query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear search',
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: JJ.selected,
                                          size: 19,
                                        ),
                                        onPressed: () {
                                          search.clear();
                                          shop.updateFilters(search: '');
                                        },
                                      ),
                              ),
                              onChanged: (v) => shop.updateFilters(search: v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: 'Filter products',
                          child: Semantics(
                            button: true,
                            label: 'Filter products',
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Material(
                                color: filterCount > 0 ? JJ.peach : JJ.cream,
                                borderRadius: BorderRadius.circular(18),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: filters,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        color: filterCount > 0
                                            ? JJ.header
                                            : JJ.selected,
                                        size: 22,
                                      ),
                                      if (filterCount > 0)
                                        Positioned(
                                          top: 13,
                                          right: 13,
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: JJ.header,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: shop.categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final c = shop.categories[i];
                          final active = c == shop.category;
                          return FilterChip(
                            label: Text(c),
                            selected: active,
                            showCheckmark: true,
                            checkmarkColor: JJ.cream,
                            selectedColor: JJ.copper,
                            backgroundColor: JJ.card,
                            elevation: 0,
                            pressElevation: 0,
                            surfaceTintColor: Colors.transparent,
                            visualDensity: VisualDensity.standard,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(
                              color: active ? JJ.copper : JJ.line,
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            labelStyle: TextStyle(
                              color: active ? JJ.cream : JJ.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) =>
                                shop.updateFilters(collection: c),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PromoBanner(
                      onShop: () {
                        shop.updateFilters(
                          collection: 'Living Room',
                          wishlistOnly: false,
                          search: '',
                        );
                        search.clear();
                        scroll.animateTo(
                          300,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        );
                      },
                    ),
                    const SizedBox(height: 26),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.savedOnly
                                    ? 'Wishlist (${shop.filtered.length})'
                                    : 'Featured (${shop.filtered.length})',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shop.savedOnly
                                    ? 'Pieces you have set aside.'
                                    : 'Curated comfort for a slower home.',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: JJ.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => shop.updateFilters(
                            wishlistOnly: !shop.savedOnly,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: shop.savedOnly
                                ? JJ.peach
                                : JJ.muted,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                          ),
                          icon: Icon(
                            shop.savedOnly
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                          ),
                          label: Text(
                            '${shop.saved.length} saved',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            if (shop.loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!shop.loading && shop.error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ShopMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Catalog unavailable',
                  description: shop.error,
                  action: shop.load,
                ),
              ),
            if (!shop.loading && shop.error == null && shop.filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ShopMessage(
                  icon: Icons.chair_outlined,
                  title: shop.products.isEmpty
                      ? 'No pieces in the catalog yet'
                      : 'No matching pieces',
                  description: 'Try another search or collection.',
                  actionLabel: 'Reset filters',
                  action: () {
                    search.clear();
                    shop.updateFilters(
                      search: '',
                      collection: 'All',
                      stockOnly: false,
                      wishlistOnly: false,
                    );
                  },
                ),
              ),
            if (!shop.loading && shop.error == null && shop.filtered.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 1000
                        ? 4
                        : constraints.crossAxisExtent >= 650
                        ? 3
                        : 2;
                    final width =
                        (constraints.crossAxisExtent - 18 * (columns - 1)) /
                        columns;
                    final textScale =
                        MediaQuery.textScalerOf(context).scale(14) / 14;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        mainAxisExtent:
                            width +
                            (textScale > 1.1
                                ? 152 * textScale
                                : (width < 165 ? 128 : 122)),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            ProductCard(product: shop.filtered[i], shop: shop),
                        childCount: shop.filtered.length,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final VoidCallback onShop;
  const _PromoBanner({required this.onShop});
  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 18;
    return Container(
      height: largeText ? 224 : 166,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: JJ.promoGradient,
        border: Border.all(color: JJ.copper.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -34,
            child: Container(
              width: 152,
              height: 152,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .045),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .06),
                ),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -18,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: JJ.peach.withValues(alpha: .16),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: largeText ? 26 : 38,
            child: Icon(
              Icons.weekend_outlined,
              size: 92,
              color: Colors.white.withValues(alpha: .16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mid-season comfort sale',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 23,
                        height: 1.15,
                        letterSpacing: -0.3,
                        color: JJ.cream,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Up to 20% off Living Room icons',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        color: JJ.muted,
                      ),
                    ),
                  ],
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: JJ.selected,
                    minimumSize: const Size(112, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: onShop,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Shop now'),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward_rounded, size: 15),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final ShopController shop;
  const ProductCard({super.key, required this.product, required this.shop});
  @override
  Widget build(BuildContext context) {
    final saved = shop.saved.contains(product.id);
    return Material(
      color: JJ.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: JJ.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('product-${product.id}'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product, shop: shop),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductPhoto(product),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: .22),
                            Colors.transparent,
                          ],
                          stops: const [0, .45],
                        ),
                      ),
                    ),
                  ),
                  if (product.category.isNotEmpty)
                    Positioned(
                      left: 9,
                      top: 9,
                      child: CategoryPill(product.category),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        tooltip: saved
                            ? 'Unsave ${product.name}'
                            : 'Save ${product.name}',
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: saved
                              ? JJ.peach
                              : Colors.black.withValues(alpha: .34),
                          foregroundColor: saved ? JJ.header : JJ.cream,
                          side: BorderSide(
                            color: saved
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: .16),
                          ),
                        ),
                        onPressed: () => shop.toggleSaved(product),
                        icon: Icon(
                          saved ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: JJ.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RatingStars(product.rating, size: 13),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            JJ.money(product.price),
                            style: const TextStyle(
                              fontSize: 16.5,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: JJ.copper,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          tooltip: product.available
                              ? 'Add ${product.name} to cart'
                              : product.stock == 0
                              ? 'Out of stock'
                              : 'Stock not confirmed',
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: product.available
                                ? JJ.selected
                                : JJ.cardRaised,
                            foregroundColor: product.available
                                ? const Color(0xFFFFDDC9)
                                : JJ.outline.withValues(alpha: .45),
                            side: BorderSide(
                              color: product.available ? JJ.copper : JJ.line,
                            ),
                          ),
                          onPressed: product.available
                              ? () {
                                  shopNotice(
                                    context,
                                    shop.add(product)
                                        ? '${product.name} added to cart'
                                        : 'All available units are already in your cart.',
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.add_rounded, size: 21),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
