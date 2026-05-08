import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/plan_application.dart';
import '../../domain/entities/subscription_plan.dart';
import '../providers/subscription_providers.dart';

class PlanApplicationPage extends ConsumerStatefulWidget {
  const PlanApplicationPage({super.key});

  @override
  ConsumerState<PlanApplicationPage> createState() =>
      _PlanApplicationPageState();
}

class _PlanApplicationPageState extends ConsumerState<PlanApplicationPage> {
  String? _selectedPlanCode;
  final _noteController = TextEditingController();
  XFile? _evidenceFile;
  bool _submitting = false;

  static const _evidenceBucket = 'plan-evidence';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _evidenceFile = picked);
  }

  Future<String?> _uploadEvidence(String companyId) async {
    final file = _evidenceFile;
    if (file == null) return null;

    final client = Supabase.instance.client;
    final ext = file.path.split('.').last.toLowerCase();
    final path = '$companyId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await client.storage.from(_evidenceBucket).upload(
          path,
          File(file.path),
          fileOptions: const FileOptions(upsert: false),
        );
    return path;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final code = _selectedPlanCode;
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プランを選択してください')),
      );
      return;
    }

    final sub = ref.read(currentCompanySubscriptionProvider).valueOrNull;
    if (sub == null) return;

    setState(() => _submitting = true);
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final evidenceUrl = await _uploadEvidence(sub.companyId);
      await repo.submitPlanApplication(
        companyId: sub.companyId,
        planCode: code,
        evidenceUrl: evidenceUrl,
        applicantNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      ref.invalidate(ownPlanApplicationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('申請を受け付けました')),
      );
      setState(() {
        _selectedPlanCode = null;
        _noteController.clear();
        _evidenceFile = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('申請に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(availablePlansProvider);
    final applicationsAsync = ref.watch(ownPlanApplicationsProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/company-portal/subscription/plans');
            }
          },
        ),
        title: Text('プラン申請', style: TextStylePalette.title),
      ),
      body: plansAsync.when(
        data: (plans) {
          final approvalPlans =
              plans.where((p) => p.requiresApproval).toList();
          return ListView(
            padding: const EdgeInsets.all(SpacePalette.base),
            children: [
              Text(
                '商工会プラン・特別プランは審査制です。会員証等のエビデンスを添付してください。',
                style: TextStylePalette.subText,
              ),
              const SizedBox(height: SpacePalette.base),
              if (approvalPlans.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: SpacePalette.sm),
                  child: Text('申請可能なプランがありません',
                      style: TextStylePalette.subText),
                )
              else
                ...approvalPlans.map(_buildPlanRadio),
              const SizedBox(height: SpacePalette.base),
              Text('エビデンス（画像）', style: TextStylePalette.smTitle),
              const SizedBox(height: SpacePalette.sm),
              SizedBox(
                width: double.infinity,
                height: ButtonSizePalette.button,
                child: OutlinedButton.icon(
                  onPressed: _pickEvidence,
                  icon: const Icon(Icons.upload_file,
                      color: ColorPalette.primaryColor),
                  label: Text(
                    _evidenceFile == null
                        ? '画像を選択'
                        : _evidenceFile!.name,
                    style: TextStylePalette.normalText,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: ColorPalette.neutral800,
                    side: const BorderSide(color: ColorPalette.neutral600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: SpacePalette.base),
              Text('申請理由・備考', style: TextStylePalette.smTitle),
              const SizedBox(height: SpacePalette.sm),
              TextField(
                controller: _noteController,
                maxLines: 4,
                style: TextStylePalette.normalText,
                cursorColor: ColorPalette.primaryColor,
                decoration: InputDecoration(
                  hintText: '所属商工会名や特別プランの該当理由など',
                  hintStyle: TextStylePalette.hintText,
                  filled: true,
                  fillColor: ColorPalette.neutral800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide: const BorderSide(color: ColorPalette.neutral600),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide: const BorderSide(color: ColorPalette.neutral600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    borderSide:
                        const BorderSide(color: ColorPalette.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: SpacePalette.lg),
              SizedBox(
                width: double.infinity,
                height: ButtonSizePalette.button,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColor,
                    foregroundColor: ColorPalette.neutral900,
                    disabledBackgroundColor: ColorPalette.neutral600,
                    disabledForegroundColor: ColorPalette.neutral400,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                    ),
                  ),
                  child: Text(
                    _submitting ? '送信中...' : '申請する',
                    style: TextStylePalette.buttonTextDark,
                  ),
                ),
              ),
              const SizedBox(height: SpacePalette.lg),
              Text('申請履歴', style: TextStylePalette.smHeader),
              const SizedBox(height: SpacePalette.sm),
              applicationsAsync.when(
                data: (apps) => apps.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: SpacePalette.sm),
                        child: Text('まだ申請はありません',
                            style: TextStylePalette.subText),
                      )
                    : Column(
                        children: apps.map(_buildApplicationItem).toList(),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(SpacePalette.sm),
                  child: LinearProgressIndicator(
                    color: ColorPalette.primaryColor,
                    backgroundColor: ColorPalette.neutral800,
                  ),
                ),
                error: (e, _) => Text('履歴取得失敗: $e',
                    style: TextStylePalette.subText),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: ColorPalette.primaryColor),
        ),
        error: (e, _) => Center(
          child: Text('読み込み失敗: $e', style: TextStylePalette.subText),
        ),
      ),
    );
  }

  Widget _buildPlanRadio(SubscriptionPlan plan) {
    final isSelected = _selectedPlanCode == plan.code;
    return Container(
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        border: Border.all(
          color: isSelected
              ? ColorPalette.primaryColor
              : ColorPalette.neutral600,
        ),
        borderRadius: BorderRadius.circular(RadiusPalette.base),
      ),
      child: RadioListTile<String>(
        value: plan.code,
        groupValue: _selectedPlanCode,
        onChanged: (v) => setState(() => _selectedPlanCode = v),
        title: Text(plan.name, style: TextStylePalette.bigText),
        subtitle: Text('月額 ¥${plan.monthlyAmount}（税込）',
            style: TextStylePalette.subText),
        activeColor: ColorPalette.primaryColor,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _buildApplicationItem(PlanApplication app) {
    final statusColor = switch (app.status) {
      PlanApplicationStatus.approved => ColorPalette.primaryColor,
      PlanApplicationStatus.rejected => Colors.redAccent,
      PlanApplicationStatus.pending => Colors.orange,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      padding: const EdgeInsets.all(SpacePalette.inner),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.base),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(app.requestedPlanCode, style: TextStylePalette.smTitle),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacePalette.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(RadiusPalette.mini),
                ),
                child: Text(
                  app.status.label,
                  style: TextStylePalette.miniTitle.copyWith(
                    color: ColorPalette.neutral900,
                  ),
                ),
              ),
            ],
          ),
          if (app.rejectionReason != null) ...[
            const SizedBox(height: SpacePalette.xs),
            Text('却下理由: ${app.rejectionReason}',
                style: TextStylePalette.smSubText
                    .copyWith(color: Colors.redAccent)),
          ],
        ],
      ),
    );
  }
}
