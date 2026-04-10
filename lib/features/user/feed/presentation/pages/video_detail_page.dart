// feed/presentation/pages/video_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:numbers/core/theme/app_theme.dart';

class VideoDetailPage extends ConsumerStatefulWidget {
  final String companyId;
  final String videoId;

  const VideoDetailPage({
    super.key,
    required this.companyId,
    required this.videoId,
  });

  @override
  ConsumerState<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends ConsumerState<VideoDetailPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _videoData;
  Map<String, dynamic>? _companyData;
  Map<String, dynamic>? _jobData;
  List<Map<String, dynamic>> _relatedVideos = [];
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadVideoData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.pause();
    }
  }

  Future<void> _loadVideoData() async {
    try {
      final supabase = Supabase.instance.client;

      // 動画データを取得（関連求人も含む）
      final videoResponse = await supabase
          .from('company_videos')
          .select('*, companies(*), jobs(*)')
          .eq('id', widget.videoId)
          .eq('company_id', widget.companyId)
          .maybeSingle();

      if (videoResponse == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '動画が見つかりません';
        });
        return;
      }

      _videoData = videoResponse;
      _companyData = videoResponse['companies'] as Map<String, dynamic>?;
      _jobData = videoResponse['jobs'] as Map<String, dynamic>?;

      final videoPath = videoResponse['video_path'] as String?;
      if (videoPath == null || videoPath.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '動画ファイルがありません';
        });
        return;
      }

      // 動画URLを取得（署名付きURL）
      String videoUrl;
      if (videoPath.startsWith('http')) {
        videoUrl = videoPath;
      } else {
        videoUrl = await supabase.storage
            .from('company-videos')
            .createSignedUrl(videoPath, 3600);
      }

      // 動画プレイヤーを初期化
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      try {
        await _controller!.initialize();
      } catch (initError) {
        // 動画初期化エラー - ファイルが存在しないか、フォーマットがサポートされていない可能性
        setState(() {
          _isLoading = false;
          _errorMessage = '動画を再生できません。\n\nファイルが存在しないか、サポートされていない形式です。';
        });
        return;
      }

      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
      });

      // 関連動画を取得（同じ企業の他の動画）
      await _loadRelatedVideos();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '動画の読み込みに失敗しました: $e';
      });
    }
  }

  Future<void> _loadRelatedVideos() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('company_videos')
          .select('*, companies(*)')
          .eq('company_id', widget.companyId)
          .neq('id', widget.videoId)
          .limit(10);

      setState(() {
        _relatedVideos = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // Related videos load error silently ignored
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Widget _buildRelatedVideoCard(Map<String, dynamic> video) {
    final title = video['title'] as String? ?? '無題';
    final thumbnailPath = video['thumbnail_path'] as String?;
    final videoId = video['id'] as String? ?? '';
    final companyId = video['company_id'] as String? ?? '';
    final company = video['companies'] as Map<String, dynamic>?;
    final companyName = company?['name'] as String? ?? '';

    String? thumbnailUrl;
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      thumbnailUrl = Supabase.instance.client.storage
          .from('company-thumbnails')
          .getPublicUrl(thumbnailPath);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacePalette.sm),
      child: GestureDetector(
        onTap: () {
          context.push('/companies/$companyId/videos/$videoId');
        },
        child: Container(
          decoration: BoxDecoration(
            color: ColorPalette.neutral800,
            borderRadius: BorderRadius.circular(RadiusPalette.base),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // サムネイル
              SizedBox(
                width: 140,
                height: 80,
                child: thumbnailUrl != null
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: ColorPalette.neutral600,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: ColorPalette.neutral400,
                                size: 32,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: ColorPalette.neutral600,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: ColorPalette.neutral400,
                            size: 32,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: SpacePalette.sm),
              // テキスト情報
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: SpacePalette.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'NotoSansJP',
                          fontSize: FontSizePalette.size14,
                          fontVariations: [FontVariation('wght', 700)],
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (companyName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          companyName,
                          style: TextStyle(
                            fontFamily: 'NotoSansJP',
                            fontSize: FontSizePalette.size12,
                            fontVariations: const [FontVariation('wght', 500)],
                            color: ColorPalette.neutral400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: SpacePalette.sm),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: ColorPalette.primaryColor,
                ),
              )
            : _videoData == null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 80,
              color: ColorPalette.neutral400,
            ),
            const SizedBox(height: SpacePalette.lg),
            Text(
              '動画を再生できません',
              style: TextStylePalette.header,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacePalette.sm),
            Text(
              _errorMessage ?? '不明なエラーが発生しました',
              style: TextStylePalette.subText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacePalette.lg * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPalette.neutral400,
                    side: const BorderSide(
                      color: ColorPalette.neutral600,
                      width: 1,
                    ),
                    minimumSize: const Size(100, ButtonSizePalette.button),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                    ),
                  ),
                  child: const Text('戻る'),
                ),
                const SizedBox(width: SpacePalette.base),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadVideoData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, ButtonSizePalette.button),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                    ),
                  ),
                  child: const Text('再試行'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final title = _videoData?['title'] as String? ?? '無題';
    final description = _videoData?['description'] as String? ?? '';
    final companyName = _companyData?['name'] as String? ?? '';
    final companyLogoUrl = _companyData?['logo_url'] as String?;
    final tags = (_videoData?['tags'] as List<dynamic>?)?.cast<String>() ?? [];

    return Column(
      children: [
        // 動画プレイヤー
        AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 動画
                if (_controller != null && _controller!.value.isInitialized)
                  VideoPlayer(_controller!)
                else if (_errorMessage != null)
                  // 動画が読み込めない場合のプレースホルダー
                  Container(
                    color: ColorPalette.neutral800,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_off,
                            size: 48,
                            color: ColorPalette.neutral400,
                          ),
                          const SizedBox(height: SpacePalette.sm),
                          Text(
                            '動画を再生できません',
                            style: TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: FontSizePalette.size14,
                              color: ColorPalette.neutral400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    color: ColorPalette.neutral800,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ColorPalette.primaryColor,
                      ),
                    ),
                  ),

                // コントロールオーバーレイ
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.2, 0.8, 1.0],
                      ),
                    ),
                    child: Column(
                      children: [
                        // 上部バー
                        Padding(
                          padding: const EdgeInsets.all(SpacePalette.sm),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => context.pop(),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // 再生ボタン（動画が再生可能な場合のみ表示）
                        if (_controller != null && _controller!.value.isInitialized)
                          Center(
                            child: IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause_circle : Icons.play_circle,
                                color: Colors.white,
                                size: 64,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                          ),

                        const Spacer(),

                        // 下部バー (シークバー)
                        if (_controller != null && _controller!.value.isInitialized)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacePalette.base,
                              vertical: SpacePalette.sm,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _formatDuration(_controller!.value.position),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: FontSizePalette.size12,
                                  ),
                                ),
                                const SizedBox(width: SpacePalette.sm),
                                Expanded(
                                  child: VideoProgressIndicator(
                                    _controller!,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                      playedColor: ColorPalette.primaryColor,
                                      bufferedColor: ColorPalette.neutral600,
                                      backgroundColor: ColorPalette.neutral600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: SpacePalette.sm),
                                Text(
                                  _formatDuration(_controller!.value.duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: FontSizePalette.size12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 動画情報
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: FontSizePalette.size18,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.neutral0,
                  ),
                ),

                const SizedBox(height: SpacePalette.sm),

                // 企業名
                if (companyName.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      context.push('/company/${widget.companyId}');
                    },
                    child: Row(
                      children: [
                        if (companyLogoUrl != null && companyLogoUrl.isNotEmpty)
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: NetworkImage(companyLogoUrl),
                            backgroundColor: ColorPalette.neutral600,
                          )
                        else
                          Icon(
                            Icons.business,
                            size: 16,
                            color: ColorPalette.neutral400,
                          ),
                        const SizedBox(width: SpacePalette.xs),
                        Text(
                          companyName,
                          style: const TextStyle(
                            fontFamily: 'NotoSansJP',
                            fontSize: FontSizePalette.size14,
                            fontWeight: FontWeight.w500,
                            color: ColorPalette.primaryColor,
                          ),
                        ),
                        const SizedBox(width: SpacePalette.xs),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: ColorPalette.primaryColor,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: SpacePalette.base),

                // タグ
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: SpacePalette.sm,
                    runSpacing: SpacePalette.sm,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacePalette.sm,
                          vertical: SpacePalette.xs,
                        ),
                        decoration: BoxDecoration(
                          color: ColorPalette.neutral600,
                          borderRadius: BorderRadius.circular(RadiusPalette.mini),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            fontFamily: 'NotoSansJP',
                            fontSize: FontSizePalette.size12,
                            fontWeight: FontWeight.w500,
                            color: ColorPalette.neutral300,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                if (tags.isNotEmpty) const SizedBox(height: SpacePalette.base),

                // 説明文
                if (description.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    decoration: BoxDecoration(
                      color: ColorPalette.neutral800,
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: FontSizePalette.size14,
                        fontWeight: FontWeight.w400,
                        color: ColorPalette.neutral400,
                        height: 1.6,
                      ),
                    ),
                  ),

                // 関連求人カード
                if (_jobData != null) ...[
                  const SizedBox(height: SpacePalette.lg),
                  Text(
                    '関連求人',
                    style: TextStylePalette.smHeader,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  GestureDetector(
                    onTap: () {
                      final jobId = _jobData!['id'] as String?;
                      if (jobId != null) {
                        context.push('/jobs/$jobId');
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(SpacePalette.base),
                      decoration: BoxDecoration(
                        color: ColorPalette.neutral800,
                        borderRadius: BorderRadius.circular(RadiusPalette.lg),
                        border: Border.all(
                          color: ColorPalette.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: ColorPalette.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(RadiusPalette.base),
                            ),
                            child: const Icon(
                              Icons.work,
                              color: ColorPalette.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: SpacePalette.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _jobData!['title'] as String? ?? '無題',
                                  style: TextStylePalette.smListTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    _jobData!['job_category'] as String?,
                                    _jobData!['job_type'] as String?,
                                    _jobData!['location_text'] as String?,
                                  ].where((s) => s != null && s.isNotEmpty).join(' / '),
                                  style: TextStylePalette.smSubText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: ColorPalette.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: SpacePalette.lg * 2),

                // 企業の他の動画を見るボタン
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/company/${widget.companyId}/videos');
                    },
                    icon: const Icon(Icons.video_library),
                    label: const Text('この企業の他の動画を見る'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorPalette.primaryColor,
                      side: const BorderSide(
                        color: ColorPalette.primaryColor,
                        width: 2,
                      ),
                      minimumSize: const Size(double.infinity, ButtonSizePalette.button),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusPalette.base),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: SpacePalette.base),

                // 企業詳細を見るボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/company/${widget.companyId}');
                    },
                    icon: const Icon(Icons.business),
                    label: const Text('企業詳細を見る'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, ButtonSizePalette.button),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusPalette.base),
                      ),
                    ),
                  ),
                ),

                // 関連動画セクション
                if (_relatedVideos.isNotEmpty) ...[
                  const SizedBox(height: SpacePalette.lg * 2),
                  const Text(
                    '関連動画',
                    style: TextStyle(
                      fontFamily: 'NotoSansJP',
                      fontSize: FontSizePalette.size16,
                      fontVariations: [FontVariation('wght', 800)],
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  ...List.generate(_relatedVideos.length, (index) {
                    final related = _relatedVideos[index];
                    return _buildRelatedVideoCard(related);
                  }),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
