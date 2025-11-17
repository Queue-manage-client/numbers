import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/presentation/providers/company_portal_provider.dart';

class CompanyProfileEditPage extends ConsumerStatefulWidget {
  const CompanyProfileEditPage({super.key});

  @override
  ConsumerState<CompanyProfileEditPage> createState() => _CompanyProfileEditPageState();
}

class _CompanyProfileEditPageState extends ConsumerState<CompanyProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _industryController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // データベースから企業情報を取得してコントローラーにセット
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompanyInfo();
    });
  }

  Future<void> _loadCompanyInfo() async {
    final companyInfo = await ref.read(companyInfoProvider.future);
    if (companyInfo != null && mounted) {
      setState(() {
        _companyNameController.text = companyInfo['name'] ?? '';
        _descriptionController.text = companyInfo['description'] ?? '';
        _addressController.text = companyInfo['address'] ?? '';
        _industryController.text = companyInfo['industry'] ?? '';
        _websiteController.text = companyInfo['website'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final companyId = ref.read(currentCompanyIdProvider);
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('企業IDが取得できません')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'name': _companyNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'industry': _industryController.text.trim(),
        'website': _websiteController.text.trim(),
      };

      await ref.read(companyPortalRepositoryProvider).updateCompany(companyId, updateData);

      // 企業情報を再取得
      ref.invalidate(companyInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('企業情報を更新しました')),
        );
        context.go('/company-portal/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text('企業情報編集'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 企業ロゴ
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF323232), width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: const Icon(
                        Icons.business,
                        size: 60,
                        color: Color(0xFF323232),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF323232),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Color(0xFFFFFFFF)),
                          onPressed: () {
                            // TODO: 画像選択
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 企業名
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: '企業名',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '企業名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 説明
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '企業説明',
                  border: OutlineInputBorder(),
                  hintText: '企業の概要を入力してください',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // 所在地
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '所在地',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 業界
              TextFormField(
                controller: _industryController,
                decoration: const InputDecoration(
                  labelText: '業界',
                  border: OutlineInputBorder(),
                  hintText: '例: IT, 製造業, サービス業',
                ),
              ),
              const SizedBox(height: 16),

              // ウェブサイト
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'ウェブサイト',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 32),

              // 更新ボタン
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF323232),
                  foregroundColor: const Color(0xFFFFFFFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFFFFFF),
                        ),
                      )
                    : const Text('更新'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
