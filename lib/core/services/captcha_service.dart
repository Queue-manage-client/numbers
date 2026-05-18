// core/services/captcha_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// hCaptcha の設定情報。site key が未設定なら captcha は無効扱い。
class CaptchaService {
  static String? get hcaptchaSiteKey {
    final key = dotenv.maybeGet('HCAPTCHA_SITE_KEY');
    if (key == null || key.isEmpty) return null;
    return key;
  }

  static bool get isEnabled => hcaptchaSiteKey != null;
}
