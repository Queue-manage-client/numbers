// company_portal/presentation/pages/company_profile_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/company_portal/providers/company_portal_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyProfileEditPage extends HookConsumerWidget {
  const CompanyProfileEditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final companyNameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final addressController = useTextEditingController();
    final industryController = useTextEditingController();
    final websiteController = useTextEditingController();
    final snsController = useTextEditingController();
    final isLoading = useState(false);
    final isDataLoaded = useState(false);
    final detailImageFile = useState<PlatformFile?>(null);
    final existingDetailImageUrl = useState<String?>(null);

    // 企業情報を取得
    final companyInfoAsync = ref.watch(companyInfoProvider);

    // データをフォームにセット
    useEffect(() {
      companyInfoAsync.whenData((companyInfo) {
        if (companyInfo != null && !isDataLoaded.value) {
          companyNameController.text = companyInfo['name'] ?? '';
          descriptionController.text = companyInfo['description'] ?? '';
          addressController.text = companyInfo['address'] ?? '';
          industryController.text = companyInfo['industry'] ?? '';
          websiteController.text = companyInfo['website'] ?? '';
          snsController.text = companyInfo['sns_url'] ?? '';
          existingDetailImageUrl.value = companyInfo['detail_image_url'] as String?;
          isDataLoaded.value = true;
        }
      });
      return null;
    }, [companyInfoAsync]);

    final updateProfile = useCallback(() async {
      if (!formKey.currentState!.validate()) return;

      final companyId = ref.read(currentCompanyIdProvider);
      if (companyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '企業IDが取得できません',
              style: TextStylePalette.normalText.copyWith(
                color: ColorPalette.neutral0,
              ),
            ),
            backgroundColor: ColorPalette.primaryColor,
          ),
        );
        return;
      }

      isLoading.value = true;

      try {
        // 詳細画像アップロード
        String? detailImageUrl = existingDetailImageUrl.value;
        if (detailImageFile.value != null && detailImageFile.value!.bytes != null) {
          final supabase = Supabase.instance.client;
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final imagePath = 'companies/$companyId/detail_${timestamp}.jpg';

          await supabase.storage.from('company-thumbnails').uploadBinary(
            imagePath,
            detailImageFile.value!.bytes!,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

          detailImageUrl = supabase.storage
              .from('company-thumbnails')
              .getPublicUrl(imagePath);
        }

        final updateData = {
          'name': companyNameController.text.trim(),
          'description': descriptionController.text.trim(),
          'address': addressController.text.trim(),
          'industry': industryController.text.trim(),
          'website': websiteController.text.trim(),
          'sns_url': snsController.text.trim(),
          'detail_image_url': detailImageUrl,
        };

        await ref.read(companyPortalRepositoryProvider).updateCompany(companyId, updateData);

        // 企業情報を再取得
        ref.invalidate(companyInfoProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '企業情報を更新しました',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.systemGold,
            ),
          );
          context.go('/company-portal/dashboard');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '更新エラー: $e',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.primaryColor,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }, [
      companyNameController,
      descriptionController,
      addressController,
      industryController,
      websiteController,
      snsController,
    ]);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => context.go('/company-portal/dashboard'),
        ),
        title: const Text('企業情報編集'),
      ),
      body: companyInfoAsync.when(
        data: (companyInfo) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Form(
              key: formKey,
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
                            border: Border.all(
                              color: ColorPalette.neutral200,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(RadiusPalette.lg),
                            color: ColorPalette.neutral200,
                          ),
                          child: Icon(
                            Icons.business,
                            size: 60,
                            color: ColorPalette.neutral500,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorPalette.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                color: ColorPalette.neutral0,
                              ),
                              onPressed: () {
                                // TODO: 画像選択
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'ロゴアップロード機能は実装中です',
                                      style: TextStylePalette.normalText.copyWith(
                                        color: ColorPalette.neutral0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // 企業詳細画像
                  Text(
                    '企業詳細画像',
                    style: TextStylePalette.smTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  GestureDetector(
                    onTap: () async {
                      try {
                        if (kIsWeb) {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            detailImageFile.value = result.files.first;
                          }
                        } else {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            detailImageFile.value = PlatformFile(
                              name: image.name,
                              size: bytes.length,
                              bytes: bytes,
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('画像選択エラー: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: ColorPalette.neutral800,
                        borderRadius: BorderRadius.circular(RadiusPalette.lg),
                        border: Border.all(
                          color: detailImageFile.value != null
                              ? ColorPalette.primaryColor
                              : ColorPalette.neutral600,
                        ),
                        image: detailImageFile.value == null &&
                                existingDetailImageUrl.value != null &&
                                existingDetailImageUrl.value!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(existingDetailImageUrl.value!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: detailImageFile.value != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(RadiusPalette.lg),
                                  child: Image.memory(
                                    detailImageFile.value!.bytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: SpacePalette.base,
                                      vertical: SpacePalette.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                                    ),
                                    child: Text('タップして変更', style: TextStylePalette.smText),
                                  ),
                                ),
                              ],
                            )
                          : existingDetailImageUrl.value != null &&
                                  existingDetailImageUrl.value!.isNotEmpty
                              ? Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: SpacePalette.base,
                                      vertical: SpacePalette.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                                    ),
                                    child: Text('タップして変更', style: TextStylePalette.smText),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: ColorPalette.neutral400,
                                    ),
                                    const SizedBox(height: SpacePalette.sm),
                                    Text(
                                      'タップして画像を選択',
                                      style: TextStylePalette.smSubText,
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // 企業名
                  Text(
                    '企業名',
                    style: TextStylePalette.smTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: companyNameController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '企業名を入力',
                      hintStyle: TextStylePalette.hintText,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '企業名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 説明
                  Text(
                    '企業説明',
                    style: TextStylePalette.smTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: descriptionController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '企業の概要を入力してください',
                      hintStyle: TextStylePalette.hintText,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 所在地
                  Text(
                    '所在地',
                    style: TextStylePalette.smTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: addressController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '例: 東京都渋谷区',
                      hintStyle: TextStylePalette.hintText,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 業界
                  Text(
                    '業界',
                    style: TextStylePalette.smTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: industryController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '例: IT, 製造業, サービス業',
                      hintStyle: TextStylePalette.hintText,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // ウェブサイト
                  Text(
                    'ウェブサイト',
                    style: TextStylePalette.smTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: websiteController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: 'https://example.com',
                      hintStyle: TextStylePalette.hintText,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // SNS
                  Text(
                    'SNS',
                    style: TextStylePalette.smTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: snsController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: 'https://twitter.com/example',
                      hintStyle: TextStylePalette.hintText,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: SpacePalette.lg * 2),

                  // 更新ボタン
                  ElevatedButton(
                    onPressed: isLoading.value ? null : updateProfile,
                    child: isLoading.value
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
                ],
              ),
            ),
          );
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
              Icon(
                Icons.error_outline,
                size: 80,
                color: ColorPalette.primaryColor,
              ),
              const SizedBox(height: SpacePalette.lg),
              Text(
                'エラーが発生しました',
                style: TextStylePalette.header,
              ),
              const SizedBox(height: SpacePalette.sm),
              Text(
                '$error',
                style: TextStylePalette.subText,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}