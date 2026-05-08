import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../providers/subscription_providers.dart';

/// Stripe Checkout / Customer Portal を WebView で開く汎用ページ。
/// success/cancel/portal-return URL のいずれかに遷移したら閉じる。
class StripeWebViewPage extends ConsumerStatefulWidget {
  const StripeWebViewPage({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  ConsumerState<StripeWebViewPage> createState() => _StripeWebViewPageState();
}

class _StripeWebViewPageState extends ConsumerState<StripeWebViewPage> {
  bool _isLoading = true;

  static const _terminatingPathSegments = <String>[
    '/subscription/success',
    '/subscription/cancel',
    '/subscription/portal-return',
  ];

  bool _isTerminatingUrl(Uri? uri) {
    if (uri == null) return false;
    return _terminatingPathSegments.any((p) => uri.path.endsWith(p));
  }

  void _close() {
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    // 終了経路 (URL detection / 戻るボタン / Close ボタン) に関わらず必ず再取得
    ref.invalidate(currentCompanySubscriptionProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
        title: Text(widget.title, style: TextStylePalette.title),
        leading: IconButton(
          icon: const Icon(Icons.close, color: ColorPalette.neutral0),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
            ),
            onLoadStart: (_, __) => setState(() => _isLoading = true),
            onLoadStop: (_, __) => setState(() => _isLoading = false),
            shouldOverrideUrlLoading: (controller, action) async {
              if (_isTerminatingUrl(action.request.url)) {
                _close();
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: ColorPalette.primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}
