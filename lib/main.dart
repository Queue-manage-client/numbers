// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/core/config/supabase_config.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/router/app_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
    storageOptions: const StorageClientOptions(
      retryAttempts: 3,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthNotifier _authNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authNotifier = AuthNotifier();
    _router = createAppRouter(_authNotifier);
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Numbers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
