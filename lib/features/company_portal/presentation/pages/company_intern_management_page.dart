import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyInternManagementPage extends StatelessWidget {
  const CompanyInternManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text('インターン管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/company-portal/interns/post'),
                    icon: const Icon(Icons.add),
                    label: const Text('新規インターン投稿'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF323232),
                      foregroundColor: const Color(0xFFFFFFFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/company-portal/interns/list'),
                    icon: const Icon(Icons.list),
                    label: const Text('インターン一覧'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF323232),
                      side: const BorderSide(color: Color(0xFF323232)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              '投稿済みインターン',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF323232),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '投稿済みのインターンはありません',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/company-portal/interns/post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF323232),
                        foregroundColor: const Color(0xFFFFFFFF),
                      ),
                      child: const Text('最初のインターンを投稿'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
