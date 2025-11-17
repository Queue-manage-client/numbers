import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyJobListManagementPage extends StatelessWidget {
  const CompanyJobListManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: データベースから求人リストを取得
    final jobs = <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text('求人一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/company-portal/jobs/post'),
          ),
        ],
      ),
      body: jobs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '投稿済みの求人はありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/company-portal/jobs/post'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF323232),
                      foregroundColor: const Color(0xFFFFFFFF),
                    ),
                    child: const Text('最初の求人を投稿'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(0xFF323232),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      job['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF323232),
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          job['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.place, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              job['location'] ?? '',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              job['salary'] ?? '',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: Color(0xFF323232)),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('編集'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('削除'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.go('/company-portal/jobs/${job['id']}/edit');
                        } else if (value == 'delete') {
                          // TODO: 削除確認ダイアログ
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
