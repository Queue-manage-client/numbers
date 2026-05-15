// profile/presentation/pages/resume_view_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/user/profile/presentation/providers/profile_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';


class ResumeViewPage extends ConsumerWidget {
  const ResumeViewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/feed');
            }
          },
        ),
        title: const Text('職務経歴書'),
      ),
      body: profileAsync.when(
        data: (profile) {
          final resumeUrl = profile?['resume_url'] as String?;
          final resumeFileName = profile?['resume_file_name'] as String?;
          final hasResume = resumeUrl != null && resumeUrl.isNotEmpty;

          if (!hasResume) {
            return _buildEmptyState(context);
          }

          return _PdfViewer(
            storagePath: resumeUrl,
            fileName: resumeFileName ?? '職務経歴書',
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: ColorPalette.primaryColor),
        ),
        error: (error, _) => Center(
          child: Text('エラー: $error', style: TextStylePalette.subText),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SpacePalette.base),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.upload_file,
              size: 64,
              color: ColorPalette.neutral400,
            ),
            const SizedBox(height: SpacePalette.base),
            Text(
              '職務経歴書が登録されていません',
              style: TextStylePalette.smTitle,
            ),
            const SizedBox(height: SpacePalette.base),
            Text(
              'プロフィール編集から登録できます',
              style: TextStylePalette.subText,
            ),
            const SizedBox(height: SpacePalette.base),
            OutlinedButton(
              onPressed: () => context.push('/profile/edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPalette.primaryColor,
                side: const BorderSide(color: ColorPalette.primaryColor),
              ),
              child: const Text('プロフィール編集へ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfViewer extends StatefulWidget {
  final String storagePath;
  final String fileName;

  const _PdfViewer({required this.storagePath, required this.fileName});

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final supabase = Supabase.instance.client;
      // 署名付きURLを使用（publicバケットでも確実に動作する）
      final downloadUrl = await supabase.storage
          .from('documents')
          .createSignedUrl(widget.storagePath, 3600);

      debugPrint('Resume download URL: $downloadUrl');
      debugPrint('Resume storage path: ${widget.storagePath}');
      final response = await http.get(Uri.parse(downloadUrl));
      debugPrint('Resume download status: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception('ダウンロード失敗 (${response.statusCode})\nURL: $downloadUrl');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/resume_preview.pdf');
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: ColorPalette.primaryColor),
            const SizedBox(height: SpacePalette.base),
            Text('PDFを読み込み中...', style: TextStylePalette.subText),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(SpacePalette.base),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: SpacePalette.base),
              Text('読み込みに失敗しました', style: TextStylePalette.smTitle),
              const SizedBox(height: SpacePalette.sm),
              Text(_error!, style: TextStylePalette.subText, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      backgroundColor: ColorPalette.neutral900,
    );
  }
}
