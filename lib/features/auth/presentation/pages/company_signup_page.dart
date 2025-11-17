import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';

class CompanySignupPage extends ConsumerStatefulWidget {
  const CompanySignupPage({super.key});

  @override
  ConsumerState<CompanySignupPage> createState() => _CompanySignupPageState();
}

class _CompanySignupPageState extends ConsumerState<CompanySignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _representativeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _representativeNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードが一致しません')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(authRepositoryProvider);

      // 企業アカウントとして登録
      final response = await repository.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // セッションが確立されるまで少し待機
        await Future.delayed(const Duration(milliseconds: 500));

        // 認証状態を確認
        final user = repository.currentUser;
        if (user != null) {
          // TODO: 企業情報をデータベースに保存
          // company_name: _companyNameController.text
          // representative_name: _representativeNameController.text
          // phone: _phoneController.text
          // is_company: true

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('企業登録完了しました')),
          );
          context.go('/company-portal/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登録完了しました。ログインしてください。')),
          );
          context.go('/company-portal/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF323232)),
          onPressed: () => context.go('/signup'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.business,
                  size: 64,
                  color: Color(0xFF323232),
                ),
                const SizedBox(height: 16),
                const Text(
                  '企業アカウント登録',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF323232),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // 企業名
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: '企業名',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '企業名を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 代表者名
                TextFormField(
                  controller: _representativeNameController,
                  decoration: const InputDecoration(
                    labelText: '代表者名',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '代表者名を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 電話番号
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '電話番号',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '電話番号を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // メールアドレス
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!value.contains('@')) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // パスワード
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'パスワード',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    if (value.length < 6) {
                      return 'パスワードは6文字以上で入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // パスワード確認
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'パスワード（確認）',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワード（確認）を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 登録ボタン
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF323232),
                    foregroundColor: const Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFFFFFF),
                          ),
                        )
                      : const Text('登録'),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.go('/company-portal/login'),
                  child: const Text(
                    'すでに企業アカウントをお持ちの方はこちら',
                    style: TextStyle(color: Color(0xFF323232)),
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
