import 'dart:math';

import 'package:flutter/material.dart';

import '../state/shop_controller.dart';
import '../theme/jj_theme.dart';
import '../widgets/shop_widgets.dart';
import 'xendit_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final ShopController shop;
  const CheckoutScreen({super.key, required this.shop});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final requestId = List.generate(
    32,
    (_) => Random.secure().nextInt(16).toRadixString(16),
  ).join();
  Map<String, dynamic>? invoiceData;
  bool busy = false;
  bool submitted = false;
  String? error;
  List<Map<String, dynamic>>? submittedItems;
  Map<String, String>? submittedCustomer;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> pay() async {
    if (busy || !form.currentState!.validate() || widget.shop.cart.isEmpty) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      // A retry reuses the same payload and idempotency key, even after a timeout.
      submittedItems ??= widget.shop.cart
          .map(
            (l) => <String, dynamic>{
              'product_id': l.product.id,
              'quantity': l.quantity,
              'finish': l.finish,
            },
          )
          .toList();
      submittedCustomer ??= {
        'name': name.text.trim(),
        'email': email.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim(),
      };
      submitted = true;
      final invoice = invoiceData ??= await widget.shop.service
          .createCartInvoice(
            items: submittedItems!,
            customer: submittedCustomer!,
            requestId: requestId,
          );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              XenditWebViewScreen(invoiceUrl: invoice['invoice_url'] as String),
        ),
      );
      if (!mounted) return;
      final status = await widget.shop.service.checkOrderStatus(
        invoice['external_id'] as String,
      );
      if (!mounted) return;
      if (status == 'PAID') {
        widget.shop.clearCart();
        await widget.shop.load();
        if (!mounted) return;
        Navigator.pop(context);
        shopNotice(context, 'Payment verified. Thank you for your order!');
      } else {
        setState(
          () => error = status == 'PENDING'
              ? 'Payment is still pending. Complete payment, then retry to check again.'
              : 'Order status: $status. Check Orders for the latest update.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Checkout could not be completed. Your order has not been marked paid. Retry safely or check Orders.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guest checkout')),
    body: ContentWidth(
      maxWidth: 720,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: JJ.cardRaised,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: JJ.line),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: JJ.copper,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery details',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'No account needed — just where the piece should go.',
                          style: TextStyle(fontSize: 12.5, color: JJ.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              field(
                name,
                'Full name',
                TextInputType.name,
                icon: Icons.person_outline_rounded,
                action: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              field(
                email,
                'Email',
                TextInputType.emailAddress,
                icon: Icons.alternate_email_rounded,
                action: TextInputAction.next,
                validate: (v) =>
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)
                    ? null
                    : 'Enter a valid email',
              ),
              const SizedBox(height: 12),
              field(
                phone,
                'Mobile number',
                TextInputType.phone,
                icon: Icons.phone_outlined,
                action: TextInputAction.next,
                validate: (v) => RegExp(r'^\+?[0-9 ()-]{10,20}$').hasMatch(v)
                    ? null
                    : 'Enter a valid mobile number',
              ),
              const SizedBox(height: 12),
              field(
                address,
                'Delivery address',
                TextInputType.streetAddress,
                icon: Icons.home_outlined,
                action: TextInputAction.newline,
                lines: 3,
              ),
              const SizedBox(height: 24),
              BrownPanel(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            Icons.receipt_long_outlined,
                            color: JJ.copper,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Order summary',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: JJ.text,
                            ),
                          ),
                        ),
                        Text(
                          '${widget.shop.count} item(s)',
                          style: const TextStyle(fontSize: 12, color: JJ.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...widget.shop.cart.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${line.quantity} × ${line.product.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: JJ.muted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              JJ.money(line.totalCents / 100),
                              style: const TextStyle(
                                fontSize: 13,
                                color: JJ.text,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 18),
                    _summaryRow(
                      'Subtotal',
                      JJ.money(widget.shop.subtotalCents / 100),
                    ),
                    const SizedBox(height: 6),
                    _summaryRow(
                      'Tax (8%)',
                      JJ.money(widget.shop.taxCents / 100),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: JJ.cream,
                            ),
                          ),
                        ),
                        Text(
                          JJ.money(widget.shop.totalCents / 100),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: JJ.peach,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BrownPanel(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            Icons.shield_outlined,
                            color: JJ.success,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Secure payment via Xendit',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: JJ.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Prices, availability and the final total are confirmed securely before payment.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: JJ.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const StatusPill(
                      label: 'Encrypted',
                      icon: Icons.lock_outline_rounded,
                      foreground: JJ.success,
                      background: Color(0x1F9DB985),
                    ),
                  ],
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error
                          .withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error
                            .withValues(alpha: .3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Theme.of(context).colorScheme.error,
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : pay,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: JJ.header,
                          ),
                        )
                      : const Icon(Icons.lock_outline_rounded, size: 18),
                  label: Text(
                    busy
                        ? 'Confirming your order...'
                        : submitted
                        ? 'Retry / check payment'
                        : 'Continue to payment',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'You will be redirected to Xendit to finish paying.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: JJ.outline),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _summaryRow(String label, String value) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: JJ.muted),
        ),
      ),
      Text(value, style: const TextStyle(fontSize: 13, color: JJ.text)),
    ],
  );
  Widget field(
    TextEditingController controller,
    String label,
    TextInputType keyboard, {
    IconData? icon,
    TextInputAction? action,
    String? Function(String)? validate,
    int lines = 1,
  }) => TextFormField(
    controller: controller,
    enabled: !busy && !submitted,
    keyboardType: keyboard,
    textInputAction: action,
    maxLines: lines,
    style: const TextStyle(
      color: JJ.header,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 19, color: JJ.selected),
      alignLabelWithHint: lines > 1,
    ),
    validator: (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return 'Required';
      if (text.length > 1000) return 'Please shorten this field';
      return validate?.call(text);
    },
  );
}
