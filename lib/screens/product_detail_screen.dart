import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product_model.dart';
import '../state/shop_controller.dart';
import '../theme/jj_theme.dart';
import '../widgets/shop_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final ShopController shop;
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.shop,
  });
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  late String finish = widget.product.finishes.firstOrNull ?? '';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.shop,
    builder: (context, _) {
      final p = widget.product;
      final shop = widget.shop;
      final wide = MediaQuery.sizeOf(context).width >= 850;
      final saved = shop.saved.contains(p.id);
      final hero = ClipRRect(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(wide ? 28 : 0),
        ),
        child: Stack(
          children: [
            SizedBox(
              height: wide ? 600 : MediaQuery.sizeOf(context).width * .855,
              width: double.infinity,
              child: ProductPhoto(p),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .42),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: .22),
                      ],
                      stops: const [0, .22, .78, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _HeroButton(
                    tooltip: 'Back to shop',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _HeroButton(
                    tooltip: saved ? 'Unsave product' : 'Save product',
                    icon: saved ? Icons.favorite : Icons.favorite_border,
                    color: saved ? const Color(0xFFFF8A80) : JJ.cream,
                    onPressed: () => shop.toggleSaved(p),
                  ),
                  const SizedBox(width: 8),
                  _HeroButton(
                    tooltip: 'Share product',
                    icon: Icons.ios_share_rounded,
                    onPressed: () async {
                      final base = Uri.base;
                      final link =
                          base.scheme == 'http' || base.scheme == 'https'
                          ? base.replace(fragment: '/product/${p.id}').toString()
                          : "${p.name} — JJ'S FURNITURE";
                      await Clipboard.setData(ClipboardData(text: link));
                      if (context.mounted) {
                        shopNotice(context, 'Product link copied');
                      }
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 26,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      final stockPill = StatusPill(
        label: p.available
            ? 'In stock'
            : p.stock == 0
            ? 'Out of stock'
            : 'Stock not confirmed',
        icon: p.available ? Icons.verified_rounded : Icons.info_outline,
        foreground: p.available ? JJ.success : JJ.gold,
        background: p.available
            ? JJ.success.withValues(alpha: .12)
            : JJ.gold.withValues(alpha: .12),
      );
      final info = Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 25,
                      height: 1.2,
                      letterSpacing: -0.3,
                      color: JJ.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 136),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      JJ.money(p.price),
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.15,
                        color: JJ.copper,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RatingStars(p.rating, size: 18),
                if (p.category.isNotEmpty) CategoryPill(p.category),
                stockPill,
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Finish',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: JJ.text,
                              fontSize: 14,
                            ),
                          ),
                          if (finish.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              finish,
                              style: const TextStyle(
                                fontSize: 12,
                                color: JJ.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 11),
                      if (p.finishes.isEmpty)
                        const Text('Not specified')
                      else
                        Wrap(
                          spacing: 11,
                          runSpacing: 9,
                          children: p.finishes.map((f) {
                            final hex = int.tryParse(
                              f.replaceFirst('#', ''),
                              radix: 16,
                            );
                            final swatch = hex == null
                                ? JJ.selected
                                : Color(0xFF000000 | hex);
                            final selected = f == finish;
                            return Tooltip(
                              message: f,
                              child: Semantics(
                                label: 'Finish $f',
                                selected: selected,
                                button: true,
                                child: InkWell(
                                  onTap: () => setState(() => finish = f),
                                  borderRadius: BorderRadius.circular(30),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: swatch,
                                      border: Border.all(
                                        color: selected ? JJ.peach : JJ.line,
                                        width: selected ? 3 : 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: .22,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      opacity: selected ? 1 : 0,
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 19,
                                        color: swatch.computeLuminance() > .45
                                            ? JJ.header
                                            : JJ.cream,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: JJ.text,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 9),
                    QuantityControl(
                      quantity: quantity,
                      capsule: true,
                      minus: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                      plus:
                          p.available &&
                              quantity + shop.quantityFor(p) < p.stock!
                          ? () => setState(() => quantity++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            BrownPanel(
              padding: const EdgeInsets.all(17),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: JJ.cardRaised,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: JJ.line),
                        ),
                        child: const Icon(
                          Icons.straighten_rounded,
                          color: JJ.copper,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Dimensions',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (p.width != null &&
                          p.depth != null &&
                          p.height != null)
                        Text(
                          '${p.width} x ${p.depth} x ${p.height} cm',
                          style: const TextStyle(
                            fontSize: 13,
                            color: JJ.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      dimension('Width', p.width),
                      const SizedBox(width: 8),
                      dimension('Depth', p.depth),
                      const SizedBox(width: 8),
                      dimension('Height', p.height),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: JJ.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              p.description.isEmpty
                  ? 'Product details have not been provided yet.'
                  : p.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: JJ.muted,
              ),
            ),
            if (p.reviews.isNotEmpty) ...[
              const SizedBox(height: 30),
              Row(
                children: [
                  const Text(
                    'Customer Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: JJ.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(
                    label: '${p.reviews.length} reviews',
                    foreground: JJ.muted,
                    background: JJ.cardRaised.withValues(alpha: .8),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...p.reviews.map(reviewTile),
            ],
          ],
        ),
      );
      return Scaffold(
        body: ContentWidth(
          child: SingleChildScrollView(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: hero),
                      Expanded(child: info),
                    ],
                  )
                : Column(children: [hero, info]),
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: JJ.header,
            border: Border(top: BorderSide(color: JJ.line)),
          ),
          child: SafeArea(
            top: false,
            child: ContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 18, 32),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: JJ.muted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              JJ.money(p.price * quantity),
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: FilledButton.icon(
                        onPressed: p.available
                            ? () {
                                final ok = shop.add(
                                  p,
                                  quantity: quantity,
                                  finish: finish,
                                );
                                shopNotice(
                                  context,
                                  ok
                                      ? 'Added to cart'
                                      : 'Not enough stock for this quantity.',
                                );
                              }
                            : null,
                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 19,
                        ),
                        label: Text('Add $quantity to Cart'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget reviewTile(ProductReview review) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: JJ.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: JJ.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: JJ.brandGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .12),
                ),
              ),
              child: Center(
                child: Text(
                  review.name.isEmpty ? '?' : review.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                review.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: JJ.text,
                ),
              ),
            ),
            RatingStars(review.rating.toDouble(), size: 13, showValue: false),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          review.comment,
          style: const TextStyle(fontSize: 13.5, height: 1.5, color: JJ.muted),
        ),
      ],
    ),
  );

  Widget dimension(String label, num? value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: JJ.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFA58B7C),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value == null ? '—' : '$value cm',
            style: const TextStyle(
              color: JJ.selected,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Frosted circular action used over product photography.
class _HeroButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _HeroButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color = JJ.cream,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 42,
    height: 42,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: .36),
        foregroundColor: color,
        side: BorderSide(color: Colors.white.withValues(alpha: .18)),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon, size: 20),
    ),
  );
}
