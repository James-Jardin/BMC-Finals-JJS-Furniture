import 'package:flutter/material.dart';

import '../services/payment_service.dart';
import '../theme/jj_theme.dart';
import '../widgets/shop_widgets.dart';

class AddressesScreen extends StatefulWidget {
  final PaymentService service;
  const AddressesScreen({super.key, required this.service});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  late Future<List<Map<String, dynamic>>> addresses = widget.service
      .fetchAddresses();
  bool busy = false;
  Future<void> addAddress() async {
    final form = GlobalKey<FormState>();
    final name = TextEditingController();
    final address = TextEditingController();
    final phone = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_location_alt_outlined, color: JJ.copper, size: 22),
            SizedBox(width: 10),
            Text('Add address'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field(name, 'Full name', icon: Icons.person_outline_rounded),
                const SizedBox(height: 12),
                field(
                  address,
                  'Delivery address',
                  icon: Icons.home_outlined,
                  lines: 2,
                ),
                const SizedBox(height: 12),
                field(phone, 'Phone number', icon: Icons.phone_outlined),
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
              if (form.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      setState(() => busy = true);
      try {
        await widget.service.saveAddress(
          name.text.trim(),
          address.text.trim(),
          phone.text.trim(),
        );
        if (mounted) {
          setState(() => addresses = widget.service.fetchAddresses());
        }
      } catch (_) {
        if (mounted) {
          shopNotice(context, 'Address could not be saved. Try again.');
        }
      } finally {
        if (mounted) setState(() => busy = false);
      }
    }
    name.dispose();
    address.dispose();
    phone.dispose();
  }

  Widget field(
    TextEditingController c,
    String label, {
    IconData? icon,
    int lines = 1,
  }) => TextFormField(
    controller: c,
    maxLines: lines,
    style: const TextStyle(
      color: JJ.header,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, color: JJ.selected, size: 19),
      alignLabelWithHint: lines > 1,
    ),
    validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Addresses')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: busy ? null : addAddress,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add address'),
    ),
    body: ContentWidth(
      maxWidth: 760,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: addresses,
        builder: (context, snap) {
          if (busy || snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ShopMessage(
              icon: Icons.cloud_off,
              title: 'Addresses unavailable',
              action: () =>
                  setState(() => addresses = widget.service.fetchAddresses()),
            );
          }
          final rows = snap.data ?? [];
          if (rows.isEmpty) {
            return const ShopMessage(
              icon: Icons.location_on_outlined,
              title: 'No saved addresses',
              description: 'Add a delivery address for this guest session.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 104),
            itemCount: rows.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Saved addresses',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Text(
                        '${rows.length}',
                        style: const TextStyle(fontSize: 12, color: JJ.muted),
                      ),
                    ],
                  ),
                );
              }
              final row = rows[i - 1];
              return BrownPanel(
                padding: const EdgeInsets.fromLTRB(15, 14, 8, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: JJ.cardRaised,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: JJ.line),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: JJ.copper,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row['name']}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: JJ.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${row['address']}',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: JJ.muted,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 13,
                                color: JJ.outline,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${row['phone']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: JJ.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete address',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: JJ.muted,
                      ),
                      onPressed: busy
                          ? null
                          : () async {
                              setState(() => busy = true);
                              try {
                                await widget.service.deleteAddress(
                                  row['id'] as String,
                                );
                                if (mounted) {
                                  setState(
                                    () => addresses = widget.service
                                        .fetchAddresses(),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  shopNotice(
                                    context,
                                    'Address could not be deleted.',
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => busy = false);
                              }
                            },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
