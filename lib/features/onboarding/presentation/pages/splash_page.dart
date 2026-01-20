// onboarding/presentation/pages/splash_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // 認証状態を監視
    final authState = ref.read(authStateProvider);

    authState.when(
      data: (state) async {
        if (!mounted) return;
        // セッションが存在する場合はログイン済みと判断
        if (state.session != null) {
          // roleを取得して適切な画面へ遷移
          await _navigateByRole(state.session!.user.id);
        } else {
          context.go('/login');
        }
      },
      loading: () {
        if (!mounted) return;
        // ローディング中は待機
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _checkAuth();
          }
        });
      },
      error: (_, __) {
        if (!mounted) return;
        context.go('/login');
      },
    );
  }

  Future<void> _navigateByRole(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      final role = profile?['role'] as String?;

      if (role == 'admin') {
        context.go('/admin/dashboard');
      } else if (role == 'company_user') {
        context.go('/company-portal/dashboard');
      } else {
        context.go('/feed');
      }
    } catch (e) {
      if (mounted) {
        context.go('/feed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Numbers',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF323232),
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: Color(0xFF323232),
            ),
          ],
        ),
      ),
    );
  }
}
