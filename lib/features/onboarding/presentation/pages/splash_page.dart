// onboarding/presentation/pages/splash_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  VideoPlayerController? _controller;
  bool _isNavigating = false;
  bool _videoFinished = false;
  AuthState? _pendingAuthState;

  /// スプラッシュ動画の公開URL
  static const _splashVideoUrl =
      'https://fmwvqsrxauxkwtziakrd.supabase.co/storage/v1/object/public/app-assets/splash_video.mp4';

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(_splashVideoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _controller!.initialize();
      _controller!.setVolume(1.0);

      // 動画終了を検知
      _controller!.addListener(_onVideoProgress);

      if (mounted) {
        setState(() {});
        _controller!.play();
      }
    } catch (e) {
      // 動画の読み込みに失敗した場合はスキップ
      debugPrint('Splash video failed: $e');
      _onVideoComplete();
    }
  }

  void _onVideoProgress() {
    final controller = _controller;
    if (controller == null || _videoFinished) return;

    final position = controller.value.position;
    final duration = controller.value.duration;

    // 動画終了 or エラー
    if (duration > Duration.zero && position >= duration) {
      _onVideoComplete();
    }
  }

  void _onVideoComplete() {
    if (_videoFinished) return;
    _videoFinished = true;

    // 認証状態が既に確定していればナビゲート
    if (_pendingAuthState != null) {
      _handleAuthState(_pendingAuthState!);
    }
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

    // 動画がまだ終わっていなければ保留
    if (!_videoFinished) {
      _pendingAuthState = state;
      return;
    }

    if (state.session != null) {
      _navigateByRole(state.session!.user.id);
    } else {
      _isNavigating = true;
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoProgress);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 認証状態を監視
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      next.whenData((state) {
        if (mounted) _handleAuthState(state);
      });
    });

    // 初回ビルド時に現在の状態をチェック
    final authState = ref.watch(authStateProvider);
    authState.whenData((state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isNavigating) {
          _handleAuthState(state);
        }
      });
    });

    final controller = _controller;
    final isReady =
        controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      body: isReady
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
