// profile/presentation/pages/profile_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/profile/presentation/providers/profile_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _universityController = TextEditingController();
  final _locationController = TextEditingController();
  String? _gender;
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _universityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('ユーザーが見つかりません');

      final repository = ref.read(profileRepositoryProvider);
      await repository.updateProfile(
        userId: user.id,
        nickname: _nicknameController.text.trim(),
        university: _universityController.text.trim(),
        location: _locationController.text.trim(),
        gender: _gender,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
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
    final profileAsync = ref.watch(profileProvider);
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          'プロフィール編集',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: profileAsync.when(
        data: (profile) {
          if (profile != null && _nicknameController.text.isEmpty) {
            _nicknameController.text = profile['nickname'] ?? '';
            _universityController.text = profile['university'] ?? '';
            _locationController.text = profile['location'] ?? '';
            _gender = profile['gender'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ニックネーム
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ニックネーム',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      hintText: 'ニックネームを入力',
                    ),
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 性別
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '性別',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    dropdownColor: ColorPalette.neutral800,
                    decoration: const InputDecoration(
                      hintText: '性別を選択',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'male',
                        child: Text('男性', style: TextStylePalette.normalText),
                      ),
                      DropdownMenuItem(
                        value: 'female',
                        child: Text('女性', style: TextStylePalette.normalText),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('その他', style: TextStylePalette.normalText),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _gender = value);
                    },
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 大学
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '大学',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _universityController,
                    decoration: const InputDecoration(
                      hintText: '大学名を入力',
                    ),
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 所在地
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '所在地',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: '所在地を入力',
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // 保存ボタン
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColor,
                      foregroundColor: ColorPalette.neutral0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorPalette.neutral0,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '保存',
                                style: TextStyle(
                                  color: ColorPalette.neutral0,
                                  fontSize: FontSizePalette.size16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: SpacePalette.sm),
                              const Icon(
                                Icons.north_east,
                                color: ColorPalette.neutral0,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'エラー: $error',
            style: TextStylePalette.normalText,
          ),
        ),
      ),
    );
  }
}
