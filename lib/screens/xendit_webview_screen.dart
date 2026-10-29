import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/jj_theme.dart';
import '../widgets/shop_widgets.dart';

class XenditWebViewScreen extends StatefulWidget {
  final String invoiceUrl;
  const XenditWebViewScreen({super.key, required this.invoiceUrl});
  @override
  State<XenditWebViewScreen> createState() => _XenditWebViewScreenState();
}

class _XenditWebViewScreenState extends State<XenditWebViewScreen> {
  WebViewController? controller;
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      openBrowser();
    } else {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) {
                setState(() {
                  loading = true;
                  error = null;
                });
              }
            },
            onPageFinished: (_) {
              if (mounted) setState(() => loading = false);
            },
            onWebResourceError: (e) {
              if (mounted && e.isForMainFrame == true) {
                setState(() {
                  loading = false;
                  error = 'The payment page could not be loaded.';
                });
              }
            },
            onNavigationRequest: (request) async {
              final uri = Uri.tryParse(request.url);
              if (uri == null) return NavigationDecision.prevent;
              if (uri.scheme == 'https') return NavigationDecision.navigate;
              if (uri.scheme == 'gcash') {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.invoiceUrl));
    }
  }

  Future<void> openBrowser() async {
    try {
      final opened = await launchUrl(
        Uri.parse(widget.invoiceUrl),
        mode: LaunchMode.externalApplication,
      );
      if (mounted) {
        setState(() {
          loading = false;
          error = opened
              ? null
              : 'Your browser blocked the payment tab. Tap Open payment page.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'The payment tab could not be opened.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Secure checkout'),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check),
          label: const Text('Check payment'),
        ),
      ],
    ),
    body: kIsWeb || error != null
        ? ShopMessage(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Complete payment with Xendit',
            description: error ?? 'Use the secure payment page, then return here and select Check payment. Your order is confirmed only after payment verification.',
            actionLabel: 'Open payment page',
            action: openBrowser,
          )
        : Stack(
            children: [
              if (controller != null) WebViewWidget(controller: controller!),
              if (loading)
                const Center(child: CircularProgressIndicator(color: JJ.peach)),
            ],
          ),
  );
}
