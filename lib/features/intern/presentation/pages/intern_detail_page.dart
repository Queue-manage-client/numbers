import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/intern/presentation/providers/intern_provider.dart';

class InternDetailPage extends ConsumerWidget {
  const InternDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: 実際にはroute parameterからinternshipIdを取得
    const internshipId = 'dummy-internship-id';
    final internshipAsync = ref.watch(internshipProvider(internshipId));

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('インターン詳細'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      body: internshipAsync.when(
        data: (internship) {
          if (internship == null) {
            return const Center(child: Text('インターンが見つかりません'));
          }

          final company = internship['companies'] as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  internship['title'] ?? 'タイトル未設定',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF323232),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  company?['name'] ?? '企業名未設定',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection('募集要項', internship['description'] ?? '未設定'),
                _buildSection(
                    '開催期間',
                    '${internship['start_date'] ?? '未定'} 〜 ${internship['end_date'] ?? '未定'}'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('応募機能は準備中です')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF323232),
                      foregroundColor: const Color(0xFFFFFFFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('応募する'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF323232),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}
