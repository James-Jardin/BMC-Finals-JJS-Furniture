import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../state/shop_controller.dart';
import '../theme/jj_theme.dart';
import '../widgets/shop_widgets.dart';

const _sampleProduct = <String, Object>{
  'name': 'Aurora Accent Chair',
  'price': 7500.00,
  'stock': 6,
  'category': 'Living Room',
  'description': 'A softly upholstered accent chair with a curved back, plush seat, and tapered oak legs. Its neutral grey fabric and warm wood tones make it an easy fit for living rooms, bedrooms, and reading corners.',
  'image_url': 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&w=1200&q=80',
  'finishes': <String>['#8C8C8C', '#C19A6B'],
};

class AdminScreen extends StatefulWidget {
  final ShopController shop;
  const AdminScreen({super.key, required this.shop});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool authorized = false;
  bool busy = true;
  String? error;
  List<Map<String, dynamic>> orders = [];
  @override
  void initState() {
    super.initState();
    check();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> check() async {
    try {
      final admin = await widget.shop.service.isAdmin();
      final rows = admin
          ? await widget.shop.service.adminOrders()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          authorized = admin;
          orders = rows;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Admin access could not be verified.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> signIn() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.shop.service.signInAdmin(email.text.trim(), password.text);
      password.clear();
      await check();
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Sign-in failed or this account is not an administrator.';
        });
      }
    }
  }

  Future<void> edit(Product p) async {
    final editForm = GlobalKey<FormState>();
    final price = TextEditingController(text: p.price.toStringAsFixed(2));
    final stock = TextEditingController(text: p.stock?.toString() ?? '');
    final category = TextEditingController(text: p.category);
    final description = TextEditingController(text: p.description);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(p.name),
        content: SingleChildScrollView(
          child: Form(
            key: editForm,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                editField(
                  price,
                  'Price (PHP)',
                  numeric: true,
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 12),
                editField(
                  stock,
                  'Available stock',
                  integer: true,
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 12),
                editField(category, 'Category', icon: Icons.category_outlined),
                const SizedBox(height: 12),
                editField(
                  description,
                  'Description',
                  required: false,
                  icon: Icons.notes_rounded,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: JJ.muted),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (editForm.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true) {
      setState(() => busy = true);
      try {
        await widget.shop.service.updateProduct(p.id, {
          'price': num.parse(price.text),
          'stock': int.parse(stock.text),
          'category': category.text.trim(),
          'description': description.text.trim(),
        });
        await widget.shop.load();
      } catch (_) {
        if (mounted) {
          shopNotice(context, 'Product update was rejected or unavailable.');
        }
      } finally {
        if (mounted) setState(() => busy = false);
      }
    }
    price.dispose();
    stock.dispose();
    category.dispose();
    description.dispose();
  }

  Future<void> add() async {
    final addForm = GlobalKey<FormState>();
    final name = TextEditingController(text: _sampleProduct['name'] as String);
    final price = TextEditingController(
      text: (_sampleProduct['price'] as num).toStringAsFixed(2),
    );
    final stock = TextEditingController(text: '${_sampleProduct['stock']}');
    final category = TextEditingController(
      text: _sampleProduct['category'] as String,
    );
    final description = TextEditingController(
      text: _sampleProduct['description'] as String,
    );
    final imageUrl = TextEditingController(
      text: _sampleProduct['image_url'] as String,
    );
    final finishes = TextEditingController(
      text: (_sampleProduct['finishes'] as List<String>).join(', '),
    );
    var published = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add product'),
          content: SingleChildScrollView(
            child: Form(
              key: addForm,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'A sample product is filled in. Edit any field, then save '
                    'to publish it to the customer shop.',
                    style: TextStyle(
                      fontSize: 12,
                      color: JJ.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  editField(name, 'Product name', icon: Icons.chair_outlined),
                  const SizedBox(height: 12),
                  editField(
                    price,
                    'Price (PHP)',
                    numeric: true,
                    icon: Icons.payments_outlined,
                  ),
                  const SizedBox(height: 12),
                  editField(
                    stock,
                    'Available stock',
                    integer: true,
                    icon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(height: 12),
                  editField(
                    category,
                    'Category',
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 12),
                  editField(
                    description,
                    'Description',
                    required: false,
                    maxLines: 3,
                    icon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 12),
                  editField(
                    imageUrl,
                    'Image URL (optional)',
                    required: false,
                    icon: Icons.image_outlined,
                  ),
                  const SizedBox(height: 12),
                  editField(
                    finishes,
                    'Finishes (hex, comma-separated)',
                    required: false,
                    icon: Icons.palette_outlined,
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: published,
                    onChanged: (value) =>
                        setDialogState(() => published = value),
                    title: const Text(
                      'Visible to customers',
                      style: TextStyle(fontSize: 14, color: JJ.text),
                    ),
                    subtitle: const Text(
                      'Publish this product in the shop',
                      style: TextStyle(fontSize: 12, color: JJ.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: TextButton.styleFrom(foregroundColor: JJ.muted),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (addForm.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save product'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      setState(() => busy = true);
      try {
        final finishList = finishes.text
            .split(',')
            .map((finish) => finish.trim())
            .where((finish) => finish.isNotEmpty)
            .toList();
        await widget.shop.service.createProduct({
          'name': name.text.trim(),
          'price': num.parse(price.text),
          'stock': int.parse(stock.text),
          'category': category.text.trim(),
          'description': description.text.trim(),
          'image_url': imageUrl.text.trim(),
          'finishes': finishList,
          'published': published,
        });
        await widget.shop.load();
        if (mounted) {
          shopNotice(context, '${name.text.trim()} is now live in the shop.');
        }
      } catch (_) {
        if (mounted) {
          shopNotice(
            context,
            'Product could not be added. Run the admin product migration and try again.',
          );
        }
      } finally {
        if (mounted) setState(() => busy = false);
      }
    }
    name.dispose();
    price.dispose();
    stock.dispose();
    category.dispose();
    description.dispose();
    imageUrl.dispose();
    finishes.dispose();
  }

  Widget editField(
    TextEditingController c,
    String label, {
    bool numeric = false,
    bool integer = false,
    bool required = true,
    int maxLines = 1,
    IconData? icon,
  }) => TextFormField(
    controller: c,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 19, color: JJ.selected),
    ),
    keyboardType: numeric || integer
        ? TextInputType.number
        : TextInputType.text,
    style: const TextStyle(color: JJ.header, fontSize: 15),
    validator: (v) {
      final s = (v ?? '').trim();
      if (required && s.isEmpty) return 'Required';
      if (numeric &&
          (num.tryParse(s) == null ||
              !num.parse(s).isFinite ||
              num.parse(s) < 0)) {
        return 'Enter a valid price';
      }
      if (integer && (int.tryParse(s) == null || int.parse(s) < 0)) {
        return 'Enter a whole number';
      }
      return null;
    },
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin'),
      actions: authorized
          ? [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: busy
                    ? null
                    : () {
                        setState(() => busy = true);
                        check();
                      },
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        await widget.shop.service.supabase.auth.signOut();
                        if (mounted) {
                          setState(() {
                            authorized = false;
                            orders = [];
                          });
                        }
                      },
                child: const Text('Sign out'),
              ),
              const SizedBox(width: 6),
            ]
          : null,
    ),
    body: busy
        ? const Center(child: CircularProgressIndicator())
        : ContentWidth(
            maxWidth: authorized ? 1000 : 520,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(13),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!authorized)
                  BrownPanel(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                    child: Form(
                      key: form,
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: JJ.brandGradient,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .15),
                              ),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_outlined,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Administrator sign-in',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: JJ.text,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Manage the catalog and recent orders.',
                            style: TextStyle(fontSize: 12.5, color: JJ.muted),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: email,
                            style: const TextStyle(
                              color: JJ.header,
                              fontSize: 15,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(
                                Icons.alternate_email_rounded,
                                size: 19,
                                color: JJ.selected,
                              ),
                            ),
                            validator: (v) => (v ?? '').contains('@')
                                ? null
                                : 'Enter your email',
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: password,
                            style: const TextStyle(
                              color: JJ.header,
                              fontSize: 15,
                            ),
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                size: 19,
                                color: JJ.selected,
                              ),
                            ),
                            validator: (v) => (v ?? '').isNotEmpty
                                ? null
                                : 'Enter your password',
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: signIn,
                              child: const Text('Sign in'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (authorized) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Manage catalog',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Text(
                        '${widget.shop.products.length} products',
                        style: const TextStyle(fontSize: 12, color: JJ.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: busy ? null : add,
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text('Add product'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.shop.products.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BrownPanel(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            12,
                            8,
                            8,
                            8,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: ProductPhoto(p),
                            ),
                          ),
                          title: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '${JJ.money(p.price)} · Stock: ${p.stock?.toString() ?? 'not configured'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: JJ.muted,
                              ),
                            ),
                          ),
                          trailing: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: JJ.cardRaised,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: JJ.line),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 17,
                              color: JJ.muted,
                            ),
                          ),
                          onTap: () => edit(p),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent orders',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Text(
                        '${orders.length} order(s)',
                        style: const TextStyle(fontSize: 12, color: JJ.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (orders.isEmpty)
                    const BrownPanel(child: Text('No orders yet.'))
                  else
                    ...orders.map(
                      (o) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BrownPanel(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  StatusPill(
                                    label: '${o['status']}',
                                    icon: o['status'] == 'PAID'
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.schedule_rounded,
                                    foreground: o['status'] == 'PAID'
                                        ? JJ.success
                                        : JJ.gold,
                                    background:
                                        (o['status'] == 'PAID'
                                                ? JJ.success
                                                : JJ.gold)
                                            .withValues(alpha: .12),
                                  ),
                                  const Spacer(),
                                  Text(
                                    JJ.money((o['total_cents'] as num) / 100),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: JJ.copper,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SelectableText(
                                '${o['id']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: JJ.outline,
                                ),
                              ),
                              if (o['status'] == 'PAID' &&
                                  o['fulfillment_status'] != 'FULFILLED')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      setState(() => busy = true);
                                      try {
                                        await widget.shop.service.fulfillOrder(
                                          o['id'] as String,
                                        );
                                        await check();
                                      } catch (_) {
                                        if (context.mounted) {
                                          shopNotice(
                                            context,
                                            'Order update was rejected.',
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => busy = false);
                                        }
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.local_shipping_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Mark fulfilled'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
  );
}
