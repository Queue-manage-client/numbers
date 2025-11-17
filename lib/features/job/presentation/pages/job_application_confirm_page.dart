import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/job/presentation/providers/job_provider.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';

class JobApplicationConfirmPage extends ConsumerStatefulWidget {
  const JobApplicationConfirmPage({super.key});

  @override
  ConsumerState<JobApplicationConfirmPage> createState() =>
      _JobApplicationConfirmPageState();
}

class _JobApplicationConfirmPageState
    extends ConsumerState<JobApplicationConfirmPage> {
  bool _isApplying = false;

  Future<void> _apply() async {
    setState(() => _isApplying = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('ログインが必要です');

      // TODO: 実際にはroute parameterからjobIdを取得
      const jobId = 'dummy-job-id';

      final repository = ref.read(jobRepositoryProvider);
      await repository.applyJob(jobId: jobId, userId: user.id);

      if (mounted) {
        context.go('/jobs/$jobId/apply/complete');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('応募確認'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '以下の求人に応募しますか？',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF323232),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '求人タイトル',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('企業名: サンプル企業'),
                    const SizedBox(height: 16),
                    const Text(
                      '応募後、企業からメッセージが届く場合があります。',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isApplying ? null : _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF323232),
                foregroundColor: const Color(0xFFFFFFFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isApplying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFFFFF),
                      ),
                    )
                  : const Text('応募する'),
            ),
          ],
        ),
      ),
    );
  }
}
