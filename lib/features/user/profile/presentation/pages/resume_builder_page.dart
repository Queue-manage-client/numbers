// profile/presentation/pages/resume_builder_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/profile/presentation/providers/profile_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class ResumeBuilderPage extends ConsumerStatefulWidget {
  const ResumeBuilderPage({super.key});

  @override
  ConsumerState<ResumeBuilderPage> createState() => _ResumeBuilderPageState();
}

class _ResumeBuilderPageState extends ConsumerState<ResumeBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isDataLoaded = false;

  // 証明写真
  String? _photoUrl;
  bool _isUploadingPhoto = false;

  // 基本情報
  final _nameController = TextEditingController();
  final _furiganaController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // 学歴・職歴（動的リスト）
  final List<TextEditingController> _educationControllers = [TextEditingController()];
  final List<TextEditingController> _workControllers = [TextEditingController()];

  // 資格・免許
  final _qualificationsController = TextEditingController();

  // 志望動機・自己PR
  final _motivationController = TextEditingController();
  final _selfPrController = TextEditingController();

  // 本人希望
  final _hopeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _furiganaController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    for (final c in _educationControllers) {
      c.dispose();
    }
    for (final c in _workControllers) {
      c.dispose();
    }
    _qualificationsController.dispose();
    _motivationController.dispose();
    _selfPrController.dispose();
    _hopeController.dispose();
    super.dispose();
  }

  void _loadExistingData(Map<String, dynamic>? profile) {
    if (profile == null || _isDataLoaded) return;
    _isDataLoaded = true;

    _photoUrl = profile['resume_photo_url'] as String?;

    final data = profile['resume_data'];
    if (data == null) return;

    final Map<String, dynamic> resumeData =
        data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);

    _nameController.text = resumeData['name'] ?? '';
    _furiganaController.text = resumeData['furigana'] ?? '';
    _birthDateController.text = resumeData['birth_date'] ?? '';
    _addressController.text = resumeData['address'] ?? '';
    _phoneController.text = resumeData['phone'] ?? '';
    _emailController.text = resumeData['email'] ?? '';
    _qualificationsController.text = resumeData['qualifications'] ?? '';
    _motivationController.text = resumeData['motivation'] ?? '';
    _selfPrController.text = resumeData['self_pr'] ?? '';
    _hopeController.text = resumeData['hope'] ?? '';

    final educations = resumeData['educations'] as List<dynamic>?;
    if (educations != null && educations.isNotEmpty) {
      for (final c in _educationControllers) {
        c.dispose();
      }
      _educationControllers.clear();
      for (final e in educations) {
        _educationControllers.add(TextEditingController(text: e.toString()));
      }
    }

    final works = resumeData['works'] as List<dynamic>?;
    if (works != null && works.isNotEmpty) {
      for (final c in _workControllers) {
        c.dispose();
      }
      _workControllers.clear();
      for (final w in works) {
        _workControllers.add(TextEditingController(text: w.toString()));
      }
    }
  }

  Future<void> _pickPhoto() async {
    try {
      setState(() => _isUploadingPhoto = true);

      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('ユーザーが見つかりません');

      final bytes = await image.readAsBytes();
      final supabase = Supabase.instance.client;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'resume_photos/${user.id}/photo_$timestamp.jpg';

      await supabase.storage.from('documents').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final publicUrl = supabase.storage.from('documents').getPublicUrl(path);

      await supabase.from('profiles').update({
        'resume_photo_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      setState(() => _photoUrl = publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真をアップロードしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('写真のアップロードに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('ユーザーが見つかりません');

      final resumeData = {
        'name': _nameController.text.trim(),
        'furigana': _furiganaController.text.trim(),
        'birth_date': _birthDateController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'educations': _educationControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
        'works': _workControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
        'qualifications': _qualificationsController.text.trim(),
        'motivation': _motivationController.text.trim(),
        'self_pr': _selfPrController.text.trim(),
        'hope': _hopeController.text.trim(),
      };

      final supabase = Supabase.instance.client;
      await supabase.from('profiles').update({
        'resume_data': resumeData,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('職務経歴書を保存しました')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存エラー: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: const Text('職務経歴書を作成'),
      ),
      body: profileAsync.when(
        data: (profile) {
          _loadExistingData(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── 証明写真 ───
                  _sectionHeader('証明写真'),
                  const SizedBox(height: SpacePalette.sm),
                  Center(
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _pickPhoto,
                      child: Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          color: ColorPalette.neutral800,
                          borderRadius: BorderRadius.circular(RadiusPalette.base),
                          border: Border.all(color: ColorPalette.neutral600),
                          image: _photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _isUploadingPhoto
                            ? const Center(child: CircularProgressIndicator())
                            : _photoUrl == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, color: ColorPalette.neutral400, size: 32),
                                      const SizedBox(height: SpacePalette.xs),
                                      Text('写真を追加', style: TextStylePalette.smSubText),
                                    ],
                                  )
                                : Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(RadiusPalette.base),
                                          bottomRight: Radius.circular(RadiusPalette.base),
                                        ),
                                      ),
                                      child: Text(
                                        '変更',
                                        textAlign: TextAlign.center,
                                        style: TextStylePalette.smText,
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // ─── 基本情報 ───
                  _sectionHeader('基本情報'),
                  const SizedBox(height: SpacePalette.sm),
                  _field('氏名', _nameController, hint: '山田 太郎', required: true),
                  _field('ふりがな', _furiganaController, hint: 'やまだ たろう'),
                  _field('生年月日', _birthDateController, hint: '2000年4月1日'),
                  _field('住所', _addressController, hint: '東京都渋谷区〇〇1-2-3'),
                  _field('電話番号', _phoneController, hint: '090-1234-5678', keyboard: TextInputType.phone),
                  _field('メールアドレス', _emailController, hint: 'example@example.com', keyboard: TextInputType.emailAddress),
                  const SizedBox(height: SpacePalette.sm),

                  // ─── 学歴 ───
                  _sectionHeader('学歴'),
                  const SizedBox(height: SpacePalette.sm),
                  ..._buildDynamicFields(
                    _educationControllers,
                    hint: '例: 2020年3月 〇〇大学 〇〇学部 卒業',
                  ),
                  const SizedBox(height: SpacePalette.sm),

                  // ─── 職歴 ───
                  _sectionHeader('職歴'),
                  const SizedBox(height: SpacePalette.sm),
                  ..._buildDynamicFields(
                    _workControllers,
                    hint: '例: 2020年4月 株式会社〇〇 入社',
                  ),
                  const SizedBox(height: SpacePalette.sm),

                  // ─── 資格・免許 ───
                  _sectionHeader('資格・免許'),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _qualificationsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '例: 普通自動車免許\nTOEIC 800点',
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // ─── 志望動機 ───
                  _sectionHeader('志望動機'),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _motivationController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: '志望動機を入力してください',
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // ─── 自己PR ───
                  _sectionHeader('自己PR'),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _selfPrController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: '自己PRを入力してください',
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // ─── 本人希望 ───
                  _sectionHeader('本人希望記入欄'),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _hopeController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '例: 勤務地・給与・勤務時間等の希望があればご記入ください',
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg * 2),

                  // ─── 保存ボタン ───
                  GradientButton(
                    text: '保存する',
                    onPressed: _isLoading ? null : _save,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: SpacePalette.lg),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e', style: TextStylePalette.subText)),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.sm,
        vertical: SpacePalette.xs,
      ),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: ColorPalette.primaryColor, width: 3),
        ),
      ),
      child: Text(title, style: TextStylePalette.smHeader),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool required = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacePalette.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStylePalette.smTitle,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$labelを入力してください' : null
            : null,
      ),
    );
  }

  List<Widget> _buildDynamicFields(
    List<TextEditingController> controllers, {
    required String hint,
  }) {
    return [
      for (int i = 0; i < controllers.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: SpacePalette.sm),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers[i],
                  decoration: InputDecoration(hintText: hint),
                ),
              ),
              if (controllers.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      controllers[i].dispose();
                      controllers.removeAt(i);
                    });
                  },
                ),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            setState(() => controllers.add(TextEditingController()));
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('行を追加'),
        ),
      ),
    ];
  }
}
