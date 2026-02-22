// admin/presentation/pages/admin_user_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/admin/providers/admin_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class AdminUserManagementPage extends HookConsumerWidget {
  const AdminUserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final usersAsync = ref.watch(adminUsersProvider);
    final filter = ref.watch(userFilterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('ユーザー管理'),
      ),
      body: Column(
        children: [
          // フィルターバー
          Container(
            padding: const EdgeInsets.all(SpacePalette.base),
            color: ColorPalette.neutral800,
            child: Column(
              children: [
                // 検索フィールド
                TextField(
                  controller: searchController,
                  style: TextStylePalette.normalText,
                  decoration: InputDecoration(
                    hintText: 'ニックネームで検索',
                    hintStyle: TextStylePalette.subText,
                    filled: true,
                    fillColor: ColorPalette.neutral600,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: ColorPalette.neutral400),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              ref.read(userFilterProvider.notifier).state =
                                  filter.copyWith(searchQuery: null);
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (value) {
                    ref.read(userFilterProvider.notifier).state =
                        filter.copyWith(searchQuery: value.isEmpty ? null : value);
                  },
                ),
                const SizedBox(height: SpacePalette.sm),
                // ロールフィルター
                Row(
                  children: [
                    Text('ロール:', style: TextStylePalette.normalText),
                    const SizedBox(width: SpacePalette.sm),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: '全て',
                              isSelected: filter.role == null,
                              onTap: () {
                                ref.read(userFilterProvider.notifier).state =
                                    UserFilter(searchQuery: filter.searchQuery);
                              },
                            ),
                            const SizedBox(width: SpacePalette.xs),
                            _FilterChip(
                              label: 'ユーザー',
                              isSelected: filter.role == 'user',
                              onTap: () {
                                ref.read(userFilterProvider.notifier).state =
                                    filter.copyWith(role: 'user');
                              },
                            ),
                            const SizedBox(width: SpacePalette.xs),
                            _FilterChip(
                              label: '企業',
                              isSelected: filter.role == 'company_user',
                              onTap: () {
                                ref.read(userFilterProvider.notifier).state =
                                    filter.copyWith(role: 'company_user');
                              },
                            ),
                            const SizedBox(width: SpacePalette.xs),
                            _FilterChip(
                              label: '管理者',
                              isSelected: filter.role == 'admin',
                              onTap: () {
                                ref.read(userFilterProvider.notifier).state =
                                    filter.copyWith(role: 'admin');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ユーザーリスト
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminUsersProvider);
              },
              child: usersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        'ユーザーが見つかりません',
                        style: TextStylePalette.subText,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _UserCard(
                        user: user,
                        onSuspendToggle: () async {
                          final isSuspended = user['is_suspended'] == true;
                          try {
                            final repo = ref.read(adminRepositoryProvider);
                            if (isSuspended) {
                              await repo.reactivateUser(user['id']);
                            } else {
                              await repo.suspendUser(user['id']);
                            }
                            ref.invalidate(adminUsersProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isSuspended ? 'ユーザーを復活しました' : 'ユーザーを停止しました',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('エラー: $e')),
                              );
                            }
                          }
                        },
                        onEditRole: () {
                          _showEditRoleDialog(context, ref, user);
                        },
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: ColorPalette.primaryColor,
                  ),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'エラー: $error',
                    style: TextStylePalette.subText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('ロールを変更'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ユーザー: ${user['nickname'] ?? '不明'}'),
              const SizedBox(height: SpacePalette.base),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'ロール'),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('ユーザー')),
                  DropdownMenuItem(value: 'company_user', child: Text('企業ユーザー')),
                  DropdownMenuItem(value: 'admin', child: Text('管理者')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedRole = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final repo = ref.read(adminRepositoryProvider);
                  await repo.updateUser(user['id'], {'role': selectedRole});
                  ref.invalidate(adminUsersProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ロールを更新しました')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('エラー: $e')),
                    );
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.sm,
          vertical: SpacePalette.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.primaryColor : ColorPalette.neutral600,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
        child: Text(
          label,
          style: TextStylePalette.normalText.copyWith(
            color: ColorPalette.neutral0,
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSuspendToggle;
  final VoidCallback onEditRole;

  const _UserCard({
    required this.user,
    required this.onSuspendToggle,
    required this.onEditRole,
  });

  @override
  Widget build(BuildContext context) {
    final role = user['role'] ?? 'user';
    final isSuspended = user['is_suspended'] == true;
    final company = user['companies'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Row(
          children: [
            // アバター
            CircleAvatar(
              backgroundColor: isSuspended
                  ? ColorPalette.neutral400
                  : ColorPalette.primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: isSuspended
                    ? ColorPalette.neutral500
                    : ColorPalette.primaryColor,
              ),
            ),
            const SizedBox(width: SpacePalette.base),

            // ユーザー情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user['nickname'] ?? '不明',
                          style: TextStylePalette.smListTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _RoleBadge(role: role),
                      if (isSuspended) ...[
                        const SizedBox(width: SpacePalette.xs),
                        _StatusBadge(isSuspended: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: SpacePalette.xs),
                  if (company != null)
                    Text(
                      '企業: ${company['name'] ?? '不明'}',
                      style: TextStylePalette.subText,
                    ),
                  Text(
                    'ID: ${user['id']?.substring(0, 8) ?? '不明'}...',
                    style: TextStylePalette.subText.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),

            // アクションメニュー
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'suspend') {
                  onSuspendToggle();
                } else if (value == 'edit') {
                  onEditRole();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: SpacePalette.sm),
                      Text('ロール変更'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'suspend',
                  child: Row(
                    children: [
                      Icon(isSuspended ? Icons.play_arrow : Icons.block),
                      const SizedBox(width: SpacePalette.sm),
                      Text(isSuspended ? '復活' : '停止'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (role) {
      case 'admin':
        label = '管理者';
        color = Colors.red;
        break;
      case 'company_user':
        label = '企業';
        color = Colors.blue;
        break;
      default:
        label = 'ユーザー';
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStylePalette.subText.copyWith(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isSuspended;

  const _StatusBadge({required this.isSuspended});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Text(
        '停止中',
        style: TextStylePalette.subText.copyWith(
          fontSize: 10,
          color: Colors.red,
        ),
      ),
    );
  }
}
