// profile/presentation/pages/profile_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
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
  final _educationController = TextEditingController();
  final _locationController = TextEditingController();
  String? _gender;
  bool _isLoading = false;
  bool _isUploadingResume = false;
  String? _resumeFileName;
  String? _resumeUrl;

  @override
  void dispose() {
    _nicknameController.dispose();
    _educationController.dispose();
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
        education: _educationController.text.trim(),
        location: _locationController.text.trim(),
        gender: _gender,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
        ref.invalidate(profileProvider);
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

  Future<void> _pickAndUploadResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      setState(() => _isUploadingResume = true);

      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('ユーザーが見つかりません');

      final repository = ref.read(profileRepositoryProvider);
      final url = await repository.uploadResume(
        userId: user.id,
        filePath: file.path!,
        fileName: file.name,
      );

      if (mounted) {
        setState(() {
          _resumeFileName = file.name;
          _resumeUrl = url;
        });
        ref.invalidate(profileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('職務経歴書をアップロードしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アップロードエラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingResume = false);
      }
    }
  }

  Future<void> _deleteResume() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final repository = ref.read(profileRepositoryProvider);
      await repository.deleteResume(user.id);

      if (mounted) {
        setState(() {
          _resumeFileName = null;
          _resumeUrl = null;
        });
        ref.invalidate(profileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('職務経歴書を削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除エラー: $e')),
        );
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
            _educationController.text = profile['education'] ?? profile['university'] ?? '';
            _locationController.text = profile['location'] ?? '';
            _gender = profile['gender'];
            _resumeFileName ??= profile['resume_file_name'];
            _resumeUrl ??= profile['resume_url'];
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ニックネームを入力してください';
                      }
                      return null;
                    },
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

                  // 学歴
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '学歴',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _educationController,
                    decoration: const InputDecoration(
                      hintText: '学歴を入力（例: ○○大学、○○高校卒業）',
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

                  // 職務経歴書セクション
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '職務経歴書',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  Container(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    decoration: BoxDecoration(
                      color: ColorPalette.neutral800,
                      borderRadius: BorderRadius.circular(RadiusPalette.lg),
                      border: Border.all(color: ColorPalette.neutral600),
                    ),
                    child: Column(
                      children: [
                        if (_resumeFileName != null && _resumeFileName!.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.description, color: ColorPalette.primaryColor, size: 20),
                              const SizedBox(width: SpacePalette.sm),
                              Expanded(
                                child: Text(
                                  _resumeFileName!,
                                  style: TextStylePalette.normalText,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: _deleteResume,
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: SpacePalette.sm),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isUploadingResume ? null : _pickAndUploadResume,
                            icon: _isUploadingResume
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: ColorPalette.primaryColor),
                                  )
                                : const Icon(Icons.upload_file),
                            label: Text(
                              _resumeFileName != null ? 'ファイルを変更' : '職務経歴書をアップロード',
                            ),
                          ),
                        ),
                        const SizedBox(height: SpacePalette.sm),
                        // 区切り線
                        Row(
                          children: [
                            const Expanded(child: Divider(color: ColorPalette.neutral600)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: SpacePalette.sm),
                              child: Text('または', style: TextStylePalette.dividerText),
                            ),
                            const Expanded(child: Divider(color: ColorPalette.neutral600)),
                          ],
                        ),
                        const SizedBox(height: SpacePalette.sm),
                        // アプリ内作成ボタン
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/resume/build'),
                            icon: const Icon(Icons.edit_document, size: 18),
                            label: const Text('アプリで作成する'),
                          ),
                        ),
                        const SizedBox(height: SpacePalette.xs),
                        Text(
                          'ひな形に沿って入力するだけで作成できます',
                          style: TextStylePalette.smSubText,
                        ),
                      ],
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
