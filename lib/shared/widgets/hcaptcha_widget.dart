// shared/widgets/hcaptcha_widget.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:numbers/core/services/captcha_service.dart';

/// hCaptcha チェックボックスを表示し、検証完了時に [onVerified] でトークンを返す。
/// HCAPTCHA_SITE_KEY が未設定ならウィジェットは何も描画せず onVerified を即時 null で呼ぶ。
class HCaptchaWidget extends StatefulWidget {
  final ValueChanged<String?> onVerified;
  final double height;

  const HCaptchaWidget({
    super.key,
    required this.onVerified,
    this.height = 120,
  });

  @override
  State<HCaptchaWidget> createState() => _HCaptchaWidgetState();
}

class _HCaptchaWidgetState extends State<HCaptchaWidget> {
  @override
  void initState() {
    super.initState();
    if (!CaptchaService.isEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onVerified(null);
      });
    }
  }

  String _buildHtml(String siteKey) {
    return '''
<!doctype html>
<html><head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script src="https://hcaptcha.com/1/api.js" async defer></script>
  <style>body{margin:0;display:flex;align-items:center;justify-content:center;background:transparent;}</style>
</head><body>
  <div class="h-captcha"
       data-sitekey="$siteKey"
       data-callback="onSubmit"
       data-expired-callback="onExpired"
       data-error-callback="onError"></div>
  <script>
    function onSubmit(token){
      window.flutter_inappwebview.callHandler('hcaptcha', token);
    }
    function onExpired(){
      window.flutter_inappwebview.callHandler('hcaptcha', null);
    }
    function onError(){
      window.flutter_inappwebview.callHandler('hcaptcha', null);
    }
  </script>
</body></html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final siteKey = CaptchaService.hcaptchaSiteKey;
    if (siteKey == null) return const SizedBox.shrink();

    return SizedBox(
      height: widget.height,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(data: _buildHtml(siteKey)),
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          javaScriptEnabled: true,
        ),
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: 'hcaptcha',
            callback: (args) {
              final token = args.isNotEmpty ? args.first as String? : null;
              widget.onVerified(token);
            },
          );
        },
        onConsoleMessage: (controller, msg) {
          if (kDebugMode) debugPrint('[hcaptcha-webview] $msg');
        },
      ),
    );
  }
}
