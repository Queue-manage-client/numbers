// company_portal/job/presentation/pages/company_job_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/job/presentation/providers/company_job_provider.dart';
import 'package:numbers/features/user/job/domain/models/job.dart';
import 'package:numbers/features/user/job/presentation/providers/job_map_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyJobEditPage extends ConsumerStatefulWidget {
  const CompanyJobEditPage({super.key});

  @override
  ConsumerState<CompanyJobEditPage> createState() => _CompanyJobEditPageState();
}

class _CompanyJobEditPageState extends ConsumerState<CompanyJobEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  String _status = 'open';
  String? _jobType;
  String? _jobCategory;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    _workingHoursController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    super.dispose();
  }

  void _initializeForm(Job job) {
    if (_isInitialized) return;
    _isInitialized = true;
    _titleController.text = job.title;
    _descriptionController.text = job.description;
    _salaryController.text = job.salary ?? '';
    _locationController.text = job.location ?? '';
    _workingHoursController.text = job.workingHours ?? '';
    _salaryMinController.text = job.salaryMin?.toString() ?? '';
    _salaryMaxController.text = job.salaryMax?.toString() ?? '';
    _status = job.status;
    _jobType = job.jobType;
    _jobCategory = job.jobCategory;
  }

  Future<void> _updateJob(String jobId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get coordinates from address using Geocoding
      double? latitude;
      double? longitude;
      final address = _locationController.text.trim();

      if (address.isNotEmpty) {
        final geocodingService = ref.read(geocodingServiceProvider);
        final result =
            await geocodingService.getCoordinatesFromAddress(address);
        if (result != null) {
          latitude = result.latitude;
          longitude = result.longitude;
        }
      }

      final salaryMin = _salaryMinController.text.trim().isNotEmpty
          ? int.tryParse(_salaryMinController.text.trim())
          : null;
      final salaryMax = _salaryMaxController.text.trim().isNotEmpty
          ? int.tryParse(_salaryMaxController.text.trim())
          : null;

      final notifier = ref.read(companyJobNotifierProvider.notifier);
      final success = await notifier.update(
        jobId: jobId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        salary: _salaryController.text.trim().isNotEmpty
            ? _salaryController.text.trim()
            : null,
        location: address.isNotEmpty ? address : null,
        jobType: _jobType,
        jobCategory: _jobCategory,
        workingHours: _workingHoursController.text.trim().isNotEmpty
            ? _workingHoursController.text.trim()
            : null,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        status: _status,
        latitude: latitude,
        longitude: longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? '求人を更新しました' : '更新に失敗しました',
              style: TextStylePalette.normalText
                  .copyWith(color: ColorPalette.neutral0),
            ),
            backgroundColor:
                success ? ColorPalette.systemGreen : Colors.red,
          ),
        );
        if (success) {
          context.go('/company-portal/jobs');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteJob(String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text('確認', style: TextStylePalette.title),
        content: Text('この求人を削除してもよろしいですか？',
            style: TextStylePalette.normalText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('キャンセル',
                style: TextStyle(color: ColorPalette.neutral400)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final notifier = ref.read(companyJobNotifierProvider.notifier);
        final success = await notifier.delete(jobId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? '求人を削除しました' : '削除に失敗しました'),
              backgroundColor:
                  success ? ColorPalette.systemGreen : Colors.red,
            ),
          );
          if (success) {
            context.go('/company-portal/jobs');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('削除エラー: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final jobAsync = ref.watch(companyJobDetailProvider(jobId));

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => context.go('/company-portal/jobs'),
        ),
        title: const Text('求人編集'),
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return Center(
              child: Text('求人が見つかりません',
                  style: TextStylePalette.subText),
            );
          }

          _initializeForm(job);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // タイトル
                  Text('タイトル', style: TextStylePalette.smTitle),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _titleController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '例: Webエンジニア募集',
                      hintStyle: TextStylePalette.hintText,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'タイトルを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 職種カテゴリ
                  Text('職種カテゴリ', style: TextStylePalette.smTitle),
                  const SizedBox(height: SpacePalette.sm),
                  DropdownButtonFormField<String>(
                    value: _jobCategory,
                    style: TextStylePalette.normalText,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '選択してください',
                    ),
                    items: JobCategory.all
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat,
                                  style: TextStylePalette.normalText),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _jobCategory = value);
                    },
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 雇用形態
                  Text('雇用形態', style: TextStylePalette.smTitle),
                  const SizedBox(height: SpacePalette.sm),
                  DropdownButtonFormField<String>(
                    value: _jobType,
                    style: TextStylePalette.normalText,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '選択してください',
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'full_time', child: Text('正社員')),
                      DropdownMenuItem(
                          value: 'part_time', child: Text('バイト')),
                      DropdownMenuItem(
                          value: 'new_grad', child: Text('新卒')),
                      DropdownMenuItem(
                          value: 'mid_career', child: Text('中途')),
                    ],
                    onChanged: (value) {
                      setState(() => _jobType = value);
                    },
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 仕事内容
                  Text('仕事内容', style: TextStylePalette.smTitle),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '求人の詳細を入力',
                      hintStyle: TextStylePalette.hintText,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '仕事内容を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 月給範囲
                  Text('月給（万円）', style: TextStylePalette.smTitle),
                  const SizedBox(height: SpacePalette.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _salaryMinController,
                          style: TextStylePalette.normalText,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '下限',
                            hintStyle: TextStylePalette.hintText,
                            suffixText: '万円',
                            suffixStyle: TextStylePalette.smText,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: SpacePalette.sm),
                        child: Text('〜',
                            style: TextStylePalette.normalText),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _salaryMaxController,
                          style: TextStylePalette.normalText,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '上限',
                            hintStyle: TextStylePalette.hintText,
                            suffixText: '万円',
                            suffixStyle: TextStylePalette.smText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _salaryController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '補足: 例: 賞与年2回、交通費支給',
                      hintStyle: TextStylePalette.hintText,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 勤務時間
                  Text('勤務時間', style: TextStylePalette.smTitle),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _workingHoursController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '例: 9:00〜18:00（休憩1時間）',
                      hintStyle: TextStylePalette.hintText,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 勤務地
                  Text('勤務地', style: TextStylePalette.smTitle),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: _locationController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '例: 東京都渋谷区',
                      hintStyle: TextStylePalette.hintText,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '勤務地を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // ステータス
                  Text('ステータス', style: TextStylePalette.smTitle),
                  const SizedBox(height: SpacePalette.sm),
                  DropdownButtonFormField<String>(
                    value: _status,
                    style: TextStylePalette.normalText,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'open',
                        child: Text('募集中',
                            style: TextStylePalette.normalText),
                      ),
                      DropdownMenuItem(
                        value: 'closed',
                        child: Text('募集終了',
                            style: TextStylePalette.normalText),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                  const SizedBox(height: SpacePalette.lg * 2),

                  // 更新ボタン
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _updateJob(jobId),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorPalette.neutral0,
                            ),
                          )
                        : const Text('更新'),
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 削除ボタン
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => _deleteJob(jobId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                          vertical: SpacePalette.base),
                    ),
                    child: const Text('削除'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
              color: ColorPalette.primaryColor),
        ),
        error: (error, _) => Center(
          child: Text('エラー: $error', style: TextStylePalette.subText),
        ),
      ),
    );
  }
}
