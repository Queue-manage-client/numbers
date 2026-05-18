// auth/presentation/pages/admin_otp_challenge_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class AdminOtpChallengePage extends HookConsumerWidget {
  const AdminOtpChallengePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeController = useTextEditingController();
    final isLoading = useState(false);
    final errorText = useState<String?>(null);
    final infoText = useState<String?>(null);

    Future<void> sendOtp({bool isResend = false}) async {
      isLoading.value = true;
      errorText.value = null;
      try {
        await ref.read(adminOtpRepositoryProvider).requestOtp();
        infoText.value = isResend
            ? '認証コードを再送しました'
            : '認証コードをメールで送信しました';
      } catch (e) {
        errorText.value = 'コード送信に失敗しました: $e';
      } finally {
        isLoading.value = false;
      }
    }

    // 初回マウント時に送信 (admin_login_page からの遷移 / セッション切れ復帰両方に対応)
    useEffect(() {
      Future.microtask(() => sendOtp());
      return null;
    }, const []);

    Future<void> verify() async {
      if (codeController.text.length != 6) {
        errorText.value = '6 桁のコードを入力してください';
        return;
      }
      isLoading.value = true;
      errorText.value = null;
      try {
        await ref.read(adminOtpRepositoryProvider).verifyOtp(
              codeController.text,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('認証に成功しました')),
          );
          context.go('/admin/dashboard');
        }
      } catch (e) {
        errorText.value = e.toString().replaceFirst('Exception: ', '');
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: const Text('管理者認証'),
        backgroundColor: ColorPalette.neutral900,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.mail_lock, size: 64, color: Colors.tealAccent),
                const SizedBox(height: SpacePalette.base),
                const Text(
                  '登録メールアドレスに送信された 6 桁の認証コードを入力してください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: SpacePalette.base),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    hintText: '000000',
                    counterText: '',
                  ),
                  onSubmitted: (_) => verify(),
                ),
                if (infoText.value != null && errorText.value == null)
                  Padding(
                    padding: const EdgeInsets.only(top: SpacePalette.sm),
                    child: Text(
                      infoText.value!,
                      style: const TextStyle(color: Colors.tealAccent),
                    ),
                  ),
                if (errorText.value != null)
                  Padding(
                    padding: const EdgeInsets.only(top: SpacePalette.sm),
                    child: Text(
                      errorText.value!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: SpacePalette.base),
                ElevatedButton(
                  onPressed: isLoading.value ? null : verify,
                  child: isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('認証する'),
                ),
                const SizedBox(height: SpacePalette.sm),
                TextButton(
                  onPressed: isLoading.value ? null : () => sendOtp(isResend: true),
                  child: const Text(
                    'コードを再送信',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
