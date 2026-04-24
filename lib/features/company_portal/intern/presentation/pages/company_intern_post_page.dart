// company_portal/presentation/pages/company_intern_post_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/features/company_portal/intern/presentation/providers/company_intern_provider.dart';

class CompanyInternPostPage extends ConsumerStatefulWidget {
  const CompanyInternPostPage({super.key});

  @override
  ConsumerState<CompanyInternPostPage> createState() => _CompanyInternPostPageState();
}

class _CompanyInternPostPageState extends ConsumerState<CompanyInternPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: ColorPalette.primaryColor,
              onPrimary: ColorPalette.neutral0,
              surface: ColorPalette.neutral800,
              onSurface: ColorPalette.neutral0,
            ),
            dialogBackgroundColor: ColorPalette.neutral800,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _postIntern() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('開始日と終了日を選択してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tags = _tagsController.text.isNotEmpty
        ? _tagsController.text.split(',').map((t) => t.trim()).toList()
        : <String>[];

    final notifier = ref.read(companyInternNotifierProvider.notifier);
    final result = await notifier.create(
      title: _titleController.text,
      description: _descriptionController.text,
      startDate: _startDate,
      endDate: _endDate,
      tags: tags,
    );

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('インターンを投稿しました'),
            backgroundColor: ColorPalette.primaryColor,
          ),
        );
        context.go('/company-portal/interns');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('投稿に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(companyInternNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () { if (Navigator.of(context).canPop()) { context.pop(); } else { context.go("/feed"); } },
        ),
        title: const Text('インターン投稿'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // タイトル
              TextFormField(
                controller: _titleController,
                style: TextStylePalette.normalText,
                decoration: InputDecoration(
                  labelText: 'タイトル',
                  labelStyle: TextStylePalette.hintText,
                  filled: true,
                  fillColor: ColorPalette.neutral800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide: BorderSide(color: ColorPalette.neutral600),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide: BorderSide(color: ColorPalette.neutral600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide: BorderSide(color: ColorPalette.primaryColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 説明
              TextFormField(
                controller: _descriptionController,
                style: TextStylePalette.normalText,
                decoration: InputDecoration(
                  labelText: '説明',
                  labelStyle: TextStylePalette.hintText,
                  filled: true,
                  fillColor: ColorPalette.neutral800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide: BorderSide(color: ColorPalette.neutral600),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide: BorderSide(color: ColorPalette.neutral600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide: BorderSide(color: ColorPalette.primaryColor),
                  ),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '説明を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 開始日
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '開始日',
                    labelStyle: TextStylePalette.hintText,
                    filled: true,
                    fillColor: ColorPalette.neutral800,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                      borderSide: BorderSide(color: ColorPalette.neutral600),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                      borderSide: BorderSide(color: ColorPalette.neutral600),
                    ),
                    suffixIcon: Icon(Icons.calendar_today, color: ColorPalette.neutral400),
                  ),
                  child: Text(
                    _startDate != null
                        ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}'
                        : '日付を選択してください',
                    style: TextStyle(
                      color: _startDate != null ? ColorPalette.neutral0 : ColorPalette.neutral400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 終了日
              InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '終了日',
                    labelStyle: TextStylePalette.hintText,
                    filled: true,
                    fillColor: ColorPalette.neutral800,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                      borderSide: BorderSide(color: ColorPalette.neutral600),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                      borderSide: BorderSide(color: ColorPalette.neutral600),
                    ),
                    suffixIcon: Icon(Icons.calendar_today, color: ColorPalette.neutral400),
                  ),
                  child: Text(
                    _endDate != null
                        ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                        : '日付を選択してください',
                    style: TextStyle(
                      color: _endDate != null ? ColorPalette.neutral0 : ColorPalette.neutral400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // タグ
              TextFormField(
                controller: _tagsController,
                style: TextStylePalette.normalText,
                decoration: InputDecoration(
                  labelText: 'タグ（カンマ区切り）',
                  labelStyle: TextStylePalette.hintText,
                  hintText: '例: IT, エンジニア, 夏季',
                  hintStyle: TextStylePalette.hintText,
                  filled: true,
                  fillColor: ColorPalette.neutral800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide: BorderSide(color: ColorPalette.neutral600),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide: BorderSide(color: ColorPalette.neutral600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide: BorderSide(color: ColorPalette.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 投稿ボタン
              GradientButton(
                text: '投稿',
                onPressed: isLoading ? null : _postIntern,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
