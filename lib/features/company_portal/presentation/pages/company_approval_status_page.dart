// company_portal/presentation/pages/company_approval_status_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/company_portal/providers/company_portal_provider.dart';
import 'package:numbers/core/domain/models/company.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/router/app_router.dart';

class CompanyApprovalStatusPage extends HookConsumerWidget {
  const CompanyApprovalStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyInfoAsync = ref.watch(companyInfoProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => context.go('/feed'),
        ),
        title: Text(
          'アカウント審査状況',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: ColorPalette.neutral0),
            onPressed: () async {
              final repository = ref.read(authRepositoryProvider);
              await repository.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: companyInfoAsync.when(
        data: (companyData) {
          if (companyData == null) {
            return Center(
              child: Text(
                '企業情報の取得に失敗しました',
                style: TextStylePalette.normalText,
              ),
            );
          }

          final company = Company.fromJson(companyData);

          // 承認済みの場合、キャッシュをクリアしてフィードへ自動遷移
          if (company.isApproved) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              clearRoleCache();
              if (context.mounted) {
                context.go('/feed');
              }
            });
          }

          return _buildStatusContent(context, ref, company);
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'エラー: $error',
                style: TextStylePalette.normalText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacePalette.base),
              ElevatedButton(
                onPressed: () => ref.invalidate(companyInfoProvider),
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusContent(BuildContext context, WidgetRef ref, Company company) {
    final isPending = company.isPending;
    final isRejected = company.isRejected;

    final IconData statusIcon;
    final Color statusColor;
    final String statusTitle;
    final String statusMessage;

    if (isPending) {
      statusIcon = Icons.hourglass_top;
      statusColor = Colors.orange;
      statusTitle = '審査待ち';
      statusMessage = 'アカウントは現在審査中です。\n運営側の審査が完了するまでお待ちください。\n審査完了後、企業ポータルの全機能をご利用いただけます。';
    } else if (isRejected) {
      statusIcon = Icons.cancel_outlined;
      statusColor = Colors.red;
      statusTitle = '審査否認';
      statusMessage = 'アカウントの審査が否認されました。\n詳細については運営までお問い合わせください。';
    } else {
      // approved - should not normally reach here
      statusIcon = Icons.check_circle_outline;
      statusColor = ColorPalette.primaryColor;
      statusTitle = '審査通過';
      statusMessage = 'アカウントは承認されています。';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacePalette.lg),
      child: Column(
        children: [
          const SizedBox(height: SpacePalette.lg * 2),

          // ステータスアイコン
          Icon(
            statusIcon,
            size: 80,
            color: statusColor,
          ),
          const SizedBox(height: SpacePalette.lg),

          // ステータスタイトル
          Text(
            statusTitle,
            style: TextStylePalette.header.copyWith(
              color: statusColor,
            ),
          ),
          const SizedBox(height: SpacePalette.lg),

          // ステータスメッセージ
          Container(
            padding: const EdgeInsets.all(SpacePalette.lg),
            decoration: BoxDecoration(
              color: ColorPalette.neutral800,
              borderRadius: BorderRadius.circular(RadiusPalette.lg),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  statusMessage,
                  style: TextStylePalette.normalText,
                  textAlign: TextAlign.center,
                ),
                if (isRejected && company.approvalNote != null && company.approvalNote!.isNotEmpty) ...[
                  const SizedBox(height: SpacePalette.base),
                  const Divider(color: ColorPalette.neutral600),
                  const SizedBox(height: SpacePalette.base),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '否認理由:',
                      style: TextStylePalette.smTitle.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      company.approvalNote!,
                      style: TextStylePalette.normalText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: SpacePalette.lg),

          // 企業情報サマリー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacePalette.base),
            decoration: BoxDecoration(
              color: ColorPalette.neutral800,
              borderRadius: BorderRadius.circular(RadiusPalette.lg),
              border: Border.all(color: ColorPalette.neutral600),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '登録企業情報',
                  style: TextStylePalette.smTitle,
                ),
                const SizedBox(height: SpacePalette.base),
                _infoRow('企業名', company.name),
                if (company.representativeName != null)
                  _infoRow('代表者名', company.representativeName!),
                if (company.phone != null)
                  _infoRow('電話番号', company.phone!),
              ],
            ),
          ),
          const SizedBox(height: SpacePalette.lg),

          // 再読み込みボタン
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                clearRoleCache();
                ref.invalidate(companyInfoProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('ステータスを更新'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPalette.primaryColor,
                side: const BorderSide(color: ColorPalette.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: SpacePalette.base),
              ),
            ),
          ),

          const SizedBox(height: SpacePalette.base),

          // ホームへ戻るボタン
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => context.go('/feed'),
              icon: const Icon(Icons.home),
              label: const Text('ホームへ戻る'),
              style: TextButton.styleFrom(
                foregroundColor: ColorPalette.neutral400,
                padding: const EdgeInsets.symmetric(vertical: SpacePalette.base),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacePalette.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStylePalette.subText,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStylePalette.normalText,
            ),
          ),
        ],
      ),
    );
  }
}
