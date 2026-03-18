// auth/presentation/providers/auth_provider.dart
// 認証状態をRiverpodで管理。
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/auth/data/repositories/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// profilesテーブルからユーザーのroleを取得するProvider
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final supabase = ref.watch(supabaseClientProvider);
  try {
    final response = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return response['role'] as String?;
  } catch (e) {
    debugPrint('userRoleProvider: ロール取得エラー: $e');
    return null;
  }
});

/// GoRouterのrefreshListenableとして使用するChangeNotifier。
/// Supabaseの認証状態変更を監視し、変更時にnotifyListenersを呼び出す。
class AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  AuthNotifier() {
    _subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
