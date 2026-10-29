import 'package:flutter/material.dart';

import '../services/payment_service.dart';
import '../theme/jj_theme.dart';
import '../widgets/shop_widgets.dart';

class OrdersScreen extends StatefulWidget {
  final PaymentService service;
  const OrdersScreen({super.key, required this.service});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Map<String, dynamic>>> orders = widget.service.fetchOrders();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Orders'),
      actions: [
        IconButton(
          tooltip: 'Refresh orders',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () =>
              setState(() => orders = widget.service.fetchOrders()),
        ),
        const SizedBox(width: 6),
      ],
    ),
    body: ContentWidth(
      maxWidth: 800,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ShopMessage(
              icon: Icons.cloud_off,
              title: 'Orders unavailable',
              description: 'Please check your connection and try again.',
              action: () =>
                  setState(() => orders = widget.service.fetchOrders()),
            );
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const ShopMessage(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              description: 'Orders from this guest session will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
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
                          'Recent purchases',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Text(
                        '${rows.length} order(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: JJ.muted,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final row = rows[i - 1];
              final items = (row['jj_order_items'] as List? ?? []);
              final paid = row['status'] == 'PAID';
              final pending =
                  row['status'] == 'PENDING' || row['status'] == 'CREATED';
              final statusColor = paid
                  ? JJ.success
                  : pending
                  ? JJ.gold
                  : JJ.muted;
              return BrownPanel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPill(
                          label: '${row['status']}',
                          icon: paid
                              ? Icons.check_circle_outline_rounded
                              : pending
                              ? Icons.schedule_rounded
                              : Icons.info_outline_rounded,
                          foreground: statusColor,
                          background: statusColor.withValues(alpha: .12),
                        ),
                        const Spacer(),
                        Text(
                          JJ.money((row['total_cents'] as num) / 100),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: JJ.copper,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: JJ.cardRaised,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: JJ.line),
                              ),
                              child: Center(
                                child: Text(
                                  '${item['quantity']}×',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: JJ.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                '${item['product_name']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: JJ.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.tag_rounded,
                          size: 14,
                          color: JJ.outline,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: SelectableText(
                            'Ref: ${row['id']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: JJ.outline,
                            ),
                          ),
                        ),
                      ],
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
