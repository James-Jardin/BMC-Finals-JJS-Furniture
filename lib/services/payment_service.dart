import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';

class PaymentService {
  final SupabaseClient? client;
  PaymentService({this.client});
  SupabaseClient get supabase => client ?? Supabase.instance.client;
  Future<List<Product>> fetchProducts() async {
    final rows = await supabase
        .from('products')
        .select()
        .order('id', ascending: true);
    return rows.map(Product.fromMap).toList();
  }

  Future<String> ensureGuest() async {
    final user =
        supabase.auth.currentUser ??
        (await supabase.auth.signInAnonymously()).user;
    if (user == null) {
      throw StateError('A secure guest session could not be started.');
    }
    return user.id;
  }

  Future<Map<String, dynamic>> createCartInvoice({
    required List<Map<String, dynamic>> items,
    required Map<String, String> customer,
    required String requestId,
  }) async {
    await ensureGuest();
    final res = await supabase.functions.invoke(
      'create-invoice',
      body: {'items': items, 'customer': customer, 'request_id': requestId},
    );
    if (res.status != 200 || res.data is! Map) {
      throw StateError('Checkout is unavailable. Please try again.');
    }
    final data = Map<String, dynamic>.from(res.data);
    final url = Uri.tryParse(data['invoice_url'] as String? ?? '');
    if (url == null ||
        url.scheme != 'https' ||
        !(url.host == 'checkout.xendit.co' ||
            url.host.endsWith('.xendit.co'))) {
      throw StateError(
        'The payment provider returned an invalid checkout link.',
      );
    }
    return data;
  }

  Future<String> checkOrderStatus(String externalId) async {
    final userId = await ensureGuest();
    final row = await supabase
        .from('jj_orders')
        .select('status')
        .eq('user_id', userId)
        .eq('id', externalId)
        .single();
    return row['status'] as String;
  }

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final userId = await ensureGuest();
    return await supabase
        .from('jj_orders')
        .select(
          'id,status,total_cents,created_at,jj_order_items(product_name,quantity)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    final userId = await ensureGuest();
    return await supabase
        .from('jj_addresses')
        .select()
        .eq('user_id', userId)
        .order('created_at');
  }

  Future<void> saveAddress(String name, String address, String phone) async {
    final userId = await ensureGuest();
    await supabase.from('jj_addresses').insert({
      'user_id': userId,
      'name': name,
      'address': address,
      'phone': phone,
    });
  }

  Future<void> deleteAddress(String id) async {
    final userId = await ensureGuest();
    await supabase
        .from('jj_addresses')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<bool> isAdmin() async {
    if (supabase.auth.currentUser == null) return false;
    return await supabase.rpc('jj_is_admin') == true;
  }

  Future<void> signInAdmin(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
    if (!await isAdmin()) {
      await supabase.auth.signOut();
      throw StateError('This account does not have administrator access.');
    }
  }

  Future<List<Map<String, dynamic>>> adminOrders() async {
    if (!await isAdmin()) throw StateError('Administrator access required.');
    return await supabase
        .from('jj_orders')
        .select('id,status,total_cents,created_at,fulfillment_status')
        .order('created_at', ascending: false)
        .limit(100);
  }

  Future<void> updateProduct(int id, Map<String, dynamic> changes) async {
    if (!await isAdmin()) throw StateError('Administrator access required.');
    await supabase.from('products').update(changes).eq('id', id);
  }

  Future<void> createProduct(Map<String, dynamic> product) async {
    if (!await isAdmin()) throw StateError('Administrator access required.');
    await supabase.from('products').insert(product);
  }

  Future<void> fulfillOrder(String id) async {
    if (!await isAdmin()) throw StateError('Administrator access required.');
    await supabase.rpc('jj_fulfill_order', params: {'p_order_id': id});
  }
}
