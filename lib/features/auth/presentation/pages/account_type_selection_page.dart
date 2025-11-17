import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountTypeSelectionPage extends StatelessWidget {
  const AccountTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '新規登録',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF323232),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'アカウントタイプを選択してください',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF323232),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // 個人用アカウントカード
              _AccountTypeCard(
                icon: Icons.person,
                title: '個人アカウント',
                description: '求人情報の閲覧や応募、\n企業とのチャットができます',
                onTap: () => context.go('/signup/individual'),
              ),

              const SizedBox(height: 24),

              // 企業用アカウントカード
              _AccountTypeCard(
                icon: Icons.business,
                title: '企業アカウント',
                description: '求人情報の掲載や\n応募者とのやりとりができます',
                onTap: () => context.go('/signup/company'),
              ),

              const SizedBox(height: 32),

              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'すでにアカウントをお持ちの方はこちら',
                  style: TextStyle(color: Color(0xFF323232)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF323232),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                icon,
                size: 64,
                color: const Color(0xFF323232),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF323232),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF323232),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
