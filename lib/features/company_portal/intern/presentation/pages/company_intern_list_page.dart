// company_portal/presentation/pages/company_intern_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/features/company_portal/intern/presentation/providers/company_intern_provider.dart';
import 'package:numbers/features/user/intern/domain/models/internship.dart';

class CompanyInternListManagementPage extends ConsumerWidget {
  const CompanyInternListManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internshipsAsync = ref.watch(companyInternshipsProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => context.pop(),
        ),
        title: const Text('インターン一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/company-portal/interns/post'),
          ),
        ],
      ),
      body: internshipsAsync.when(
        data: (interns) {
          if (interns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: ColorPalette.neutral600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '投稿済みのインターンはありません',
                    style: TextStylePalette.subText,
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    text: '最初のインターンを投稿',
                    onPressed: () => context.go('/company-portal/interns/post'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(companyInternshipsProvider);
            },
            color: ColorPalette.primaryColor,
            backgroundColor: ColorPalette.neutral800,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: interns.length,
              itemBuilder: (context, index) {
                final intern = interns[index];
                return _InternCard(intern: intern);
              },
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: ColorPalette.primaryColor),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'エラーが発生しました',
                style: TextStylePalette.normalText,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(companyInternshipsProvider),
                child: Text(
                  '再読み込み',
                  style: TextStyle(color: ColorPalette.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InternCard extends ConsumerWidget {
  final Internship intern;

  const _InternCard({required this.intern});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(applicationCountsProvider(intern.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: ColorPalette.neutral800,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        side: BorderSide(color: ColorPalette.neutral600),
      ),
      child: InkWell(
        onTap: () => context.go('/company-portal/interns/${intern.id}/applications'),
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      intern.title,
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  _buildPopupMenu(context, ref),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                intern.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStylePalette.subText,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: ColorPalette.neutral400),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateRange(intern.startDate, intern.endDate),
                    style: TextStylePalette.smText.copyWith(color: ColorPalette.neutral400),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 申し込み数
              countsAsync.when(
                data: (counts) => Row(
                  children: [
                    _buildCountChip('申込', counts['total'] ?? 0, ColorPalette.primaryColor),
                    const SizedBox(width: 8),
                    _buildCountChip('審査中', counts['pending'] ?? 0, Colors.orange),
                    const SizedBox(width: 8),
                    _buildCountChip('承認', counts['approved'] ?? 0, Colors.green),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              // タグ
              if (intern.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: intern.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorPalette.neutral900,
                      borderRadius: BorderRadius.circular(RadiusPalette.mini),
                    ),
                    child: Text(
                      tag,
                      style: TextStylePalette.smText.copyWith(color: ColorPalette.neutral400),
                    ),
                  )).toList(),
                ),
              // 公開状態
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    intern.isPublic ? Icons.public : Icons.public_off,
                    size: 16,
                    color: intern.isPublic ? Colors.green : ColorPalette.neutral400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    intern.isPublic ? '公開中' : '非公開',
                    style: TextStylePalette.smText.copyWith(
                      color: intern.isPublic ? Colors.green : ColorPalette.neutral400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: FontSizePalette.size12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: ColorPalette.neutral400),
      color: ColorPalette.neutral800,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'applications',
          child: Row(
            children: [
              Icon(Icons.people, color: ColorPalette.neutral0, size: 20),
              const SizedBox(width: 8),
              Text('申し込み一覧', style: TextStylePalette.normalText),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: ColorPalette.neutral0, size: 20),
              const SizedBox(width: 8),
              Text('編集', style: TextStylePalette.normalText),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle_visibility',
          child: Row(
            children: [
              Icon(
                intern.isPublic ? Icons.visibility_off : Icons.visibility,
                color: ColorPalette.neutral0,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                intern.isPublic ? '非公開にする' : '公開する',
                style: TextStylePalette.normalText,
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text('削除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'applications':
            context.go('/company-portal/interns/${intern.id}/applications');
            break;
          case 'edit':
            context.go('/company-portal/interns/${intern.id}/edit');
            break;
          case 'toggle_visibility':
            _toggleVisibility(context, ref);
            break;
          case 'delete':
            _showDeleteDialog(context, ref);
            break;
        }
      },
    );
  }

  void _toggleVisibility(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(companyInternNotifierProvider.notifier);
    final success = await notifier.update(
      internshipId: intern.id,
      isPublic: !intern.isPublic,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (intern.isPublic ? '非公開にしました' : '公開しました')
                : '変更に失敗しました',
          ),
          backgroundColor: success ? ColorPalette.primaryColor : Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text('インターンを削除', style: TextStylePalette.smTitle),
        content: Text(
          '「${intern.title}」を削除しますか？\nこの操作は取り消せません。',
          style: TextStylePalette.normalText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('キャンセル', style: TextStyle(color: ColorPalette.neutral400)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final notifier = ref.read(companyInternNotifierProvider.notifier);
              final success = await notifier.delete(intern.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '削除しました' : '削除に失敗しました'),
                    backgroundColor: success ? ColorPalette.neutral600 : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '日程未定';

    String formatDate(DateTime date) {
      return '${date.year}/${date.month}/${date.day}';
    }

    if (start != null && end != null) {
      return '${formatDate(start)} - ${formatDate(end)}';
    } else if (start != null) {
      return '${formatDate(start)} -';
    } else {
      return '- ${formatDate(end!)}';
    }
  }
}
