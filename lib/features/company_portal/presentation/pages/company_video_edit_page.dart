import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyVideoEditPage extends StatefulWidget {
  const CompanyVideoEditPage({super.key});

  @override
  State<CompanyVideoEditPage> createState() => _CompanyVideoEditPageState();
}

class _CompanyVideoEditPageState extends State<CompanyVideoEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isVertical = true;
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // TODO: 動画データを取得してコントローラーにセット
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _updateVideo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: 動画更新処理を実装
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('動画を更新しました')),
        );
        context.go('/company-portal/videos/list');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新エラー: $e')),
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
        title: const Text('動画編集'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 動画プレビュー
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF323232)),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[300],
                ),
                child: const Center(
                  child: Icon(Icons.play_circle_outline, size: 64),
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

              // 更新ボタン
              ElevatedButton(
                onPressed: _isLoading ? null : _updateVideo,
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
                    : const Text('更新'),
              ),
              const SizedBox(height: 16),

              // 削除ボタン
              OutlinedButton(
                onPressed: () {
                  // TODO: 削除確認ダイアログ
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('削除'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
