import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'screens/shop_shell.dart';
import 'services/payment_service.dart';
import 'state/shop_controller.dart';
import 'theme/jj_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );
  final preferences = await SharedPreferences.getInstance();
  final shop = ShopController(
    service: PaymentService(),
    preferences: preferences,
  );
  runApp(JjsFurnitureApp(shop: shop));
  await shop.load();
}

class JjsFurnitureApp extends StatelessWidget {
  final ShopController shop;
  const JjsFurnitureApp({super.key, required this.shop});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "JJ'S FURNITURE",
    theme: JJ.theme,
    onGenerateRoute: (settings) {
      final uri = Uri.tryParse(settings.name ?? '/');
      final segments = uri?.pathSegments ?? [];
      final id = segments.length == 2 && segments.first == 'product'
          ? int.tryParse(segments.last)
          : null;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => ShopShell(shop: shop, initialProductId: id),
      );
    },
  );
}
