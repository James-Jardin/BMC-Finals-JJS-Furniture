import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../theme/jj_theme.dart';

class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ContentWidth({super.key, required this.child, this.maxWidth = 1200});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// A warm, softly raised surface used for every card in the app.
class BrownPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const BrownPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = JJ.radius,
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .18),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: JJ.cardGradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: JJ.line),
        ),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class ProductPhoto extends StatelessWidget {
  final Product product;
  const ProductPhoto(this.product, {super.key});
  @override
  Widget build(BuildContext context) {
    Widget failed(BuildContext c, Object e, StackTrace? s) => ColoredBox(
      color: JJ.cardRaised,
      child: Center(
        child: Icon(
          Icons.chair_outlined,
          color: JJ.muted.withValues(alpha: .7),
          size: 40,
        ),
      ),
    );
    final imageUrl = product.imageUrl.trim();
    final uri = Uri.tryParse(imageUrl);
    final hasRemoteImage =
        uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
    Widget remotePhoto() => hasRemoteImage
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: failed,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : ColoredBox(
                    color: JJ.cardRaised,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: JJ.outline.withValues(alpha: .7),
                        ),
                      ),
                    ),
                  ),
            width: double.infinity,
            height: double.infinity,
            semanticLabel: product.name,
          )
        : failed(context, '', null);

    final asset = product.asset;
    if (asset != null) {
      // Supplied furniture photos display immediately, even when an old
      // database URL points to a different photo or its request never finishes.
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => remotePhoto(),
        width: double.infinity,
        height: double.infinity,
        semanticLabel: product.name,
      );
    }
    return remotePhoto();
  }
}

class CategoryPill extends StatelessWidget {
  final String category;
  const CategoryPill(this.category, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: JJ.cream.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .18),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      category,
      style: const TextStyle(
        color: Color(0xFF6B584C),
        fontSize: 11.5,
        height: 1.15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
  );
}

class RatingStars extends StatelessWidget {
  final double? rating;
  final double size;
  final bool showValue;
  const RatingStars(
    this.rating, {
    super.key,
    this.size = 15,
    this.showValue = true,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: rating == null
        ? 'Not yet rated'
        : 'Rated ${rating!.toStringAsFixed(1)} out of 5',
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      children: [
        if (rating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final remaining = rating! - i;
              final icon = remaining >= 1
                  ? Icons.star
                  : remaining >= 0.5
                  ? Icons.star_half
                  : Icons.star_border;
              return Icon(
                icon,
                color: remaining >= 0.5 ? JJ.star : JJ.outline,
                size: size,
              );
            }),
          ),
        if (showValue)
          Text(
            rating?.toStringAsFixed(1) ?? 'Not yet rated',
            style: const TextStyle(
              fontSize: 12,
              height: 1.2,
              color: JJ.text,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    ),
  );
}

class QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback? minus;
  final VoidCallback? plus;
  final bool capsule;
  const QuantityControl({
    super.key,
    required this.quantity,
    this.minus,
    this.plus,
    this.capsule = false,
  });
  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback? action, String label) =>
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            tooltip: label,
            onPressed: action,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: capsule ? Colors.white : JJ.cardRaised,
              disabledBackgroundColor: capsule
                  ? Colors.white
                  : JJ.cardRaised,
              foregroundColor: capsule ? JJ.header : JJ.cream,
              disabledForegroundColor: JJ.outline.withValues(alpha: .45),
              side: capsule
                  ? BorderSide.none
                  : const BorderSide(color: JJ.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(capsule ? 18 : 10),
              ),
            ),
            icon: Icon(icon, size: 19),
          ),
        );
    return Container(
      padding: capsule
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
          : EdgeInsets.zero,
      decoration: capsule
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove, minus, 'Decrease quantity'),
          SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: capsule ? JJ.header : JJ.text,
              ),
            ),
          ),
          button(Icons.add, plus, 'Increase quantity'),
        ],
      ),
    );
  }
}

/// Small contextual badge used for stock, order and status states.
class StatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color foreground;
  final Color background;
  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.foreground = JJ.success,
    this.background = const Color(0x1F9DB985),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: foreground.withValues(alpha: .22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.15,
            color: foreground,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ],
    ),
  );
}

class ShopMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? action;
  const ShopMessage({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: JJ.cardGradient,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: JJ.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: JJ.copper, size: 34),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                color: JJ.cream,
              ),
            ),
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            if (action != null)
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: FilledButton(
                  onPressed: action,
                  child: Text(actionLabel ?? 'Try again'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void shopNotice(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info_outline, color: JJ.peach, size: 19),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
