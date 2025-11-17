import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/presentation/providers/company_portal_provider.dart';

class CompanyVideoPostPage extends ConsumerStatefulWidget {
  const CompanyVideoPostPage({super.key});

  @override
  ConsumerState<CompanyVideoPostPage> createState() => _CompanyVideoPostPageState();
}

class _CompanyVideoPostPageState extends ConsumerState<CompanyVideoPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isVertical = true;
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _postVideo() async {
    if (!_formKey.currentState!.validate()) return;

    final companyId = ref.read(currentCompanyIdProvider);
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('企業IDが取得できません')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // タグをカンマ区切りで配列に変換
      final tagsText = _tagsController.text.trim();
      final tags = tagsText.isEmpty
          ? <String>[]
          : tagsText.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();

      // 動画データを作成
      final videoData = {
        'company_id': companyId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'vertical': _isVertical,
        'is_public': _isPublic,
        'tags': tags,
        'video_path': 'placeholder_path', // TODO: 実際の動画アップロード処理
        'thumbnail_path': null,
        'sort_order': 0,
      };

      await ref.read(companyPortalRepositoryProvider).createVideo(videoData);

      // 動画一覧を再取得
      ref.invalidate(companyVideosProvider);
      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('動画を投稿しました')),
        );
        context.go('/company-portal/videos');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿エラー: $e')),
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
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text('動画投稿'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 動画ファイル選択
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF323232)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_file_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: 動画ファイル選択
                        },
                        icon: const Icon(Icons.upload),
                        label: const Text('動画ファイルを選択'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF323232),
                          foregroundColor: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // タイトル
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 説明
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '説明',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // タグ
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'タグ（カンマ区切り）',
                  border: OutlineInputBorder(),
                  hintText: '例: IT, エンジニア, 新卒',
                ),
              ),
              const SizedBox(height: 16),

              // 縦型動画
              SwitchListTile(
                title: const Text(
                  '縦型動画',
                  style: TextStyle(color: Color(0xFF323232)),
                ),
                value: _isVertical,
                onChanged: (value) => setState(() => _isVertical = value),
                activeColor: const Color(0xFF323232),
              ),

              // 公開設定
              SwitchListTile(
                title: const Text(
                  '公開',
                  style: TextStyle(color: Color(0xFF323232)),
                ),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                activeColor: const Color(0xFF323232),
              ),
              const SizedBox(height: 24),

              // 投稿ボタン
              ElevatedButton(
                onPressed: _isLoading ? null : _postVideo,
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
                    : const Text('投稿'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
