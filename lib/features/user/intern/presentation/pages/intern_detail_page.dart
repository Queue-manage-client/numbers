// intern/presentation/pages/intern_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/intern/presentation/providers/intern_provider.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class InternDetailPage extends ConsumerWidget {
  const InternDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internshipId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final currentRoute = GoRouterState.of(context).uri.path;

    // IDが空の場合はエラー表示
    if (internshipId.isEmpty) {
      return Scaffold(
        backgroundColor: ColorPalette.neutral900,
        appBar: AppBar(
          title: const Text('インターン詳細'),
        ),
        body: Center(
          child: Text(
            'インターンが見つかりません',
            style: TextStylePalette.subText,
          ),
        ),
        bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      );
    }

    final internshipAsync = ref.watch(internshipProvider(internshipId));
    final applicationStatusAsync = ref.watch(applicationStatusProvider(internshipId));
    final applicationState = ref.watch(internApplicationNotifierProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      body: internshipAsync.when(
        data: (internship) {
          if (internship == null) {
            return Center(
              child: Text(
                'インターンが見つかりません',
                style: TextStylePalette.subText,
              ),
            );
          }

          final company = internship['companies'] as Map<String, dynamic>?;

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 上部タイトルエリア
                    Container(
                      decoration: BoxDecoration(
                        color: ColorPalette.neutral900,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.all(SpacePalette.base),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (Navigator.of(context).canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/interns');
                                  }
                                },
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: ColorPalette.neutral0,
                                ),
                              ),
                              const SizedBox(width: SpacePalette.sm),
                              Expanded(
                                child: Text(
                                  internship['title'] ?? 'インターン詳細',
                                  style: TextStylePalette.header,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: SpacePalette.base),

                    // インターン画像
                    Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      decoration: BoxDecoration(
                        color: ColorPalette.neutral800,
                        borderRadius: BorderRadius.circular(RadiusPalette.lg),
                        border: Border.all(color: ColorPalette.neutral600),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 60,
                          color: ColorPalette.neutral600,
                        ),
                      ),
                    ),

                    const SizedBox(height: SpacePalette.base),

                    // カテゴリーとエリア
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacePalette.inner,
                              vertical: SpacePalette.xs,
                            ),
                            decoration: BoxDecoration(
                              color: ColorPalette.neutral800,
                              borderRadius: BorderRadius.circular(RadiusPalette.base),
                              border: Border.all(color: ColorPalette.neutral600),
                            ),
                            child: Text(
                              company?['industry'] ?? '業種未設定',
                              style: TextStylePalette.smText,
                            ),
                          ),
                          const SizedBox(width: SpacePalette.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacePalette.inner,
                              vertical: SpacePalette.xs,
                            ),
                            decoration: BoxDecoration(
                              color: ColorPalette.neutral800,
                              borderRadius: BorderRadius.circular(RadiusPalette.base),
                              border: Border.all(color: ColorPalette.neutral600),
                            ),
                            child: Text(
                              internship['location'] ?? company?['address'] ?? 'エリア未設定',
                              style: TextStylePalette.smText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: SpacePalette.base),

                    // タイトル
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      child: Text(
                        internship['title'] ?? '建設業界の縁の下の力持ち',
                        style: TextStylePalette.lgListTitle,
                      ),
                    ),

                    const SizedBox(height: SpacePalette.sm),

                    // 企業名
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      child: Text(
                        company?['name'] ?? '大和鉄筋株式会社',
                        style: TextStylePalette.subText,
                      ),
                    ),

                    const SizedBox(height: SpacePalette.lg),

                    // 応募ボタン（状態に応じて変化）
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      child: applicationStatusAsync.when(
                        data: (application) => _buildApplicationButton(
                          context,
                          ref,
                          internshipId,
                          application,
                          applicationState.isLoading,
                        ),
                        loading: () => _buildLoadingButton(),
                        error: (_, __) => _buildApplicationButton(
                          context,
                          ref,
                          internshipId,
                          null,
                          applicationState.isLoading,
                        ),
                      ),
                    ),

                    const SizedBox(height: SpacePalette.lg),

                    // 募集内容
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      child: Container(
                        decoration: BoxDecoration(
                          color: ColorPalette.neutral800,
                          borderRadius: BorderRadius.circular(RadiusPalette.lg),
                          border: Border.all(color: ColorPalette.neutral600),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            iconColor: ColorPalette.neutral0,
                            collapsedIconColor: ColorPalette.neutral0,
                            title: Row(
                              children: [
                                Icon(
                                  Icons.list,
                                  color: ColorPalette.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: SpacePalette.sm),
                                Text(
                                  '募集内容',
                                  style: TextStylePalette.smTitle,
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(SpacePalette.base),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (internship['description'] != null && (internship['description'] as String).isNotEmpty)
                                      Text(
                                        internship['description'],
                                        style: TextStylePalette.normalText,
                                      )
                                    else
                                      Text(
                                        '募集内容の詳細はお問い合わせください',
                                        style: TextStylePalette.subText,
                                      ),
                                    if (internship['start_date'] != null) ...[
                                      const SizedBox(height: SpacePalette.inner),
                                      _buildInfoRow(
                                        Icons.calendar_today,
                                        '開始日: ${internship['start_date']}',
                                      ),
                                    ],
                                    if (internship['end_date'] != null) ...[
                                      const SizedBox(height: SpacePalette.sm),
                                      _buildInfoRow(
                                        Icons.event,
                                        '終了日: ${internship['end_date']}',
                                      ),
                                    ],
                                    if (internship['requirements'] != null) ...[
                                      const SizedBox(height: SpacePalette.sm),
                                      _buildInfoRow(
                                        Icons.assignment,
                                        '応募条件: ${internship['requirements']}',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: SpacePalette.base),

                    // NBS SELECT
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: SpacePalette.lg),
                      child: Center(
                        child: Text(
                          'NBS SELECT',
                          style: TextStyle(
                            fontSize: FontSizePalette.size12,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.neutral400,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            '読み込みに失敗しました',
            style: TextStylePalette.normalText,
          ),
        ),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
    );
  }

  Widget _buildApplicationButton(
    BuildContext context,
    WidgetRef ref,
    String internshipId,
    InternshipApplication? application,
    bool isLoading,
  ) {
    if (isLoading) {
      return _buildLoadingButton();
    }

    // 申し込み済みの場合
    if (application != null) {
      switch (application.status) {
        case ApplicationStatus.pending:
          return _buildStatusButton(
            context,
            ref,
            '審査中',
            Icons.hourglass_empty,
            ColorPalette.neutral600,
            onPressed: () => _showCancelDialog(context, ref, application.id, internshipId),
          );
        case ApplicationStatus.approved:
          return _buildStatusButton(
            context,
            ref,
            '承認済み - チャットで連絡できます',
            Icons.check_circle,
            ColorPalette.primaryColor,
            onPressed: () {
              context.go('/chats');
            },
          );
        case ApplicationStatus.rejected:
          return _buildStatusButton(
            context,
            ref,
            '申し込みが却下されました',
            Icons.cancel,
            Colors.red,
          );
        case ApplicationStatus.cancelled:
          // キャンセル済みの場合は再申し込み可能
          return _buildApplyButton(context, ref, internshipId);
      }
    }

    // 未申し込みの場合
    return _buildApplyButton(context, ref, internshipId);
  }

  Widget _buildApplyButton(BuildContext context, WidgetRef ref, String internshipId) {
    return GradientButton(
      text: 'インターン応募',
      onPressed: () => _showApplyDialog(context, ref, internshipId),
      icon: const Icon(
        Icons.north_east,
        color: ColorPalette.neutral0,
        size: 20,
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    WidgetRef ref,
    String text,
    IconData icon,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.neutral800,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: SpacePalette.base),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusPalette.base),
            side: BorderSide(color: color),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(text),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.neutral800,
          padding: const EdgeInsets.symmetric(vertical: SpacePalette.base),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusPalette.base),
          ),
        ),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ColorPalette.primaryColor,
          ),
        ),
      ),
    );
  }

  void _showApplyDialog(BuildContext context, WidgetRef ref, String internshipId) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text(
          'インターン応募',
          style: TextStylePalette.smTitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'このインターンに応募しますか？',
              style: TextStylePalette.normalText,
            ),
            const SizedBox(height: SpacePalette.base),
            TextField(
              controller: messageController,
              maxLines: 3,
              style: TextStylePalette.normalText,
              decoration: InputDecoration(
                hintText: 'メッセージ（任意）',
                hintStyle: TextStylePalette.hintText,
                filled: true,
                fillColor: ColorPalette.neutral900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'キャンセル',
              style: TextStyle(color: ColorPalette.neutral400),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final notifier = ref.read(internApplicationNotifierProvider.notifier);
              final success = await notifier.apply(
                internshipId,
                message: messageController.text.isNotEmpty ? messageController.text : null,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '応募しました！' : '応募に失敗しました'),
                    backgroundColor: success ? ColorPalette.primaryColor : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primaryColor,
            ),
            child: const Text('応募する'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    String applicationId,
    String internshipId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text(
          '応募キャンセル',
          style: TextStylePalette.smTitle,
        ),
        content: Text(
          '応募をキャンセルしますか？',
          style: TextStylePalette.normalText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '戻る',
              style: TextStyle(color: ColorPalette.neutral400),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final notifier = ref.read(internApplicationNotifierProvider.notifier);
              final success = await notifier.cancel(applicationId, internshipId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'キャンセルしました' : 'キャンセルに失敗しました'),
                    backgroundColor: success ? ColorPalette.neutral600 : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('キャンセルする'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: ColorPalette.neutral400,
          size: 20,
        ),
        const SizedBox(width: SpacePalette.sm),
        Expanded(
          child: Text(
            text,
            style: TextStylePalette.subText,
          ),
        ),
      ],
    );
  }
}
