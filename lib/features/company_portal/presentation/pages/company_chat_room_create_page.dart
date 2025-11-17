import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyChatRoomCreatePage extends StatefulWidget {
  const CompanyChatRoomCreatePage({super.key});

  @override
  State<CompanyChatRoomCreatePage> createState() => _CompanyChatRoomCreatePageState();
}

class _CompanyChatRoomCreatePageState extends State<CompanyChatRoomCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _roomType = 'direct';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createChatRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: チャットルーム作成処理を実装
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('チャットルームを作成しました')),
        );
        context.go('/company-portal/chats');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('作成エラー: $e')),
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
        title: const Text('チャットルーム作成'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ルーム名
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ルーム名',
                  border: OutlineInputBorder(),
                  hintText: '例: 新卒採用チャット',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ルーム名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ルームタイプ
              DropdownButtonFormField<String>(
                value: _roomType,
                decoration: const InputDecoration(
                  labelText: 'ルームタイプ',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'direct',
                    child: Text('ダイレクトメッセージ'),
                  ),
                  DropdownMenuItem(
                    value: 'group',
                    child: Text('グループチャット'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _roomType = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // 説明
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(
                          'ルームタイプについて',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ダイレクトメッセージ: 1対1のチャット\nグループチャット: 複数人でのチャット',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 作成ボタン
              ElevatedButton(
                onPressed: _isLoading ? null : _createChatRoom,
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
                    : const Text('作成'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
