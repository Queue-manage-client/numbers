// onboarding/presentation/pages/splash_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _scaleAnimations;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _scaleAnimations = List.generate(4, (index) {
      final startInterval = index * 0.15;
      final endInterval = startInterval + 0.5;

      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.6)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.6, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            startInterval.clamp(0.0, 1.0),
            endInterval.clamp(0.0, 1.0),
            curve: Curves.linear,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateByRole(String userId) async {
    if (_isNavigating) return;
    _isNavigating = true;

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

  void _handleAuthState(AuthState state) {
    if (_isNavigating) return;

    if (state.session != null) {
      _navigateByRole(state.session!.user.id);
    } else {
      _isNavigating = true;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 認証状態を監視し、状態が確定したらナビゲート
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      next.whenData((state) {
        if (mounted) {
          _handleAuthState(state);
        }
      });
    });

    // 初回ビルド時に現在の状態をチェック
    final authState = ref.watch(authStateProvider);
    authState.whenData((state) {
      // 次のフレームでナビゲート（ビルド中のナビゲートを避ける）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isNavigating) {
          _handleAuthState(state);
        }
      });
    });

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NBS',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: ColorPalette.primaryColor,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Transform.scale(
                        scale: _scaleAnimations[index].value,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: ColorPalette.primaryColor.withOpacity(
                              0.4 + (_scaleAnimations[index].value - 1.0) * 0.6,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorPalette.neutral400,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
