import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JobApplicationCompletePage extends StatelessWidget {
  const JobApplicationCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('応募完了'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                '応募が完了しました',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF323232),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                '企業からの返信をお待ちください。\nチャットでメッセージが届く場合があります。',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/feed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF323232),
                    foregroundColor: const Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('ホームに戻る'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/applications'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF323232),
                    side: const BorderSide(color: Color(0xFF323232)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('応募履歴を見る'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
