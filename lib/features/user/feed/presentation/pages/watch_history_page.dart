import 'package:flutter/material.dart';
import 'package:numbers/core/theme/app_theme.dart';

class WatchHistoryPage extends StatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
  int _currentPage = 0;
  static const int _videosPerPage = 10;

  // ダミーデータ（30件）
  static const List<_HistoryVideoData> _allVideos = [
    _HistoryVideoData(title: '会社紹介ムービー', companyName: 'テックソリューションズ', thumbnail: 'assets/images/1.png', watchedAt: '2時間前'),
    _HistoryVideoData(title: 'エンジニア座談会', companyName: 'グローバルコネクト', thumbnail: 'assets/images/2.png', watchedAt: '3時間前'),
    _HistoryVideoData(title: 'オフィスツアー', companyName: 'イノベートR&D', thumbnail: 'assets/images/1.png', watchedAt: '5時間前'),
    _HistoryVideoData(title: 'インターン体験記', companyName: 'サステナ未来ラボ', thumbnail: 'assets/images/2.png', watchedAt: '昨日'),
    _HistoryVideoData(title: '新卒1年目の1日', companyName: 'フューチャーテック', thumbnail: 'assets/images/1.png', watchedAt: '昨日'),
    _HistoryVideoData(title: '社員インタビュー', companyName: 'スマートワークス', thumbnail: 'assets/images/2.png', watchedAt: '昨日'),
    _HistoryVideoData(title: '開発チーム紹介', companyName: 'ネクストイノベーション', thumbnail: 'assets/images/1.png', watchedAt: '2日前'),
    _HistoryVideoData(title: '福利厚生について', companyName: 'デジタルクリエイト', thumbnail: 'assets/images/2.png', watchedAt: '2日前'),
    _HistoryVideoData(title: 'プロジェクト事例', companyName: 'テックソリューションズ', thumbnail: 'assets/images/1.png', watchedAt: '3日前'),
    _HistoryVideoData(title: 'リモートワーク環境', companyName: 'グローバルコネクト', thumbnail: 'assets/images/2.png', watchedAt: '3日前'),
    _HistoryVideoData(title: '採用メッセージ', companyName: 'イノベートR&D', thumbnail: 'assets/images/1.png', watchedAt: '4日前'),
    _HistoryVideoData(title: 'キャリアパス紹介', companyName: 'サステナ未来ラボ', thumbnail: 'assets/images/2.png', watchedAt: '4日前'),
    _HistoryVideoData(title: '研修制度について', companyName: 'フューチャーテック', thumbnail: 'assets/images/1.png', watchedAt: '5日前'),
    _HistoryVideoData(title: '社内イベント', companyName: 'スマートワークス', thumbnail: 'assets/images/2.png', watchedAt: '5日前'),
    _HistoryVideoData(title: 'CEOメッセージ', companyName: 'ネクストイノベーション', thumbnail: 'assets/images/1.png', watchedAt: '1週間前'),
    _HistoryVideoData(title: 'ワークライフバランス', companyName: 'デジタルクリエイト', thumbnail: 'assets/images/2.png', watchedAt: '1週間前'),
    _HistoryVideoData(title: 'グローバル展開', companyName: 'テックソリューションズ', thumbnail: 'assets/images/1.png', watchedAt: '1週間前'),
    _HistoryVideoData(title: 'テクノロジースタック', companyName: 'グローバルコネクト', thumbnail: 'assets/images/2.png', watchedAt: '1週間前'),
    _HistoryVideoData(title: '新規事業紹介', companyName: 'イノベートR&D', thumbnail: 'assets/images/1.png', watchedAt: '2週間前'),
    _HistoryVideoData(title: 'チームカルチャー', companyName: 'サステナ未来ラボ', thumbnail: 'assets/images/2.png', watchedAt: '2週間前'),
    _HistoryVideoData(title: 'サービス紹介', companyName: 'フューチャーテック', thumbnail: 'assets/images/1.png', watchedAt: '2週間前'),
    _HistoryVideoData(title: '社長が語る未来', companyName: 'スマートワークス', thumbnail: 'assets/images/2.png', watchedAt: '3週間前'),
    _HistoryVideoData(title: 'エンジニアの1日', companyName: 'ネクストイノベーション', thumbnail: 'assets/images/1.png', watchedAt: '3週間前'),
    _HistoryVideoData(title: 'デザイナーの仕事', companyName: 'デジタルクリエイト', thumbnail: 'assets/images/2.png', watchedAt: '3週間前'),
    _HistoryVideoData(title: '営業職紹介', companyName: 'テックソリューションズ', thumbnail: 'assets/images/1.png', watchedAt: '1ヶ月前'),
    _HistoryVideoData(title: 'マーケティング部門', companyName: 'グローバルコネクト', thumbnail: 'assets/images/2.png', watchedAt: '1ヶ月前'),
    _HistoryVideoData(title: '入社式', companyName: 'イノベートR&D', thumbnail: 'assets/images/1.png', watchedAt: '1ヶ月前'),
    _HistoryVideoData(title: '夏の社内旅行', companyName: 'サステナ未来ラボ', thumbnail: 'assets/images/2.png', watchedAt: '1ヶ月前'),
    _HistoryVideoData(title: 'ハッカソン', companyName: 'フューチャーテック', thumbnail: 'assets/images/1.png', watchedAt: '1ヶ月前'),
    _HistoryVideoData(title: '年末振り返り', companyName: 'スマートワークス', thumbnail: 'assets/images/2.png', watchedAt: '1ヶ月前'),
  ];

  int get _totalPages => (_allVideos.length / _videosPerPage).ceil();

  List<_HistoryVideoData> get _currentPageVideos {
    final start = _currentPage * _videosPerPage;
    final end = (start + _videosPerPage).clamp(0, _allVideos.length);
    return _allVideos.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        backgroundColor: ColorPalette.neutral900,
        title: const Text(
          '視聴履歴',
          style: TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: FontSizePalette.size16,
            fontVariations: [FontVariation('wght', 800)],
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // 動画リスト
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(SpacePalette.base),
              itemCount: _currentPageVideos.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: SpacePalette.sm),
              itemBuilder: (context, index) {
                final video = _currentPageVideos[index];
                return _buildVideoCard(video);
              },
            ),
          ),

          // ページネーション
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildVideoCard(_HistoryVideoData video) {
    return Container(
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
            child: Image.asset(
              video.thumbnail,
              fit: BoxFit.cover,
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
                    video.title,
                    style: const TextStyle(
                      fontFamily: 'NotoSansJP',
                      fontSize: FontSizePalette.size14,
                      fontVariations: [FontVariation('wght', 700)],
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    video.companyName,
                    style: TextStyle(
                      fontFamily: 'NotoSansJP',
                      fontSize: FontSizePalette.size12,
                      fontVariations: const [FontVariation('wght', 500)],
                      color: ColorPalette.neutral400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    video.watchedAt,
                    style: TextStyle(
                      fontFamily: 'NotoSansJP',
                      fontSize: FontSizePalette.size12,
                      fontVariations: const [FontVariation('wght', 400)],
                      color: ColorPalette.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: SpacePalette.sm),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.base,
        vertical: SpacePalette.sm,
      ),
      decoration: BoxDecoration(
        color: ColorPalette.neutral900,
        border: Border(
          top: BorderSide(color: ColorPalette.neutral600, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 前へ
          IconButton(
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            icon: Icon(
              Icons.chevron_left,
              color: _currentPage > 0
                  ? ColorPalette.neutral0
                  : ColorPalette.neutral600,
            ),
          ),

          // ページ番号
          ...List.generate(_totalPages, (index) {
            final isSelected = index == _currentPage;
            return GestureDetector(
              onTap: () => setState(() => _currentPage = index),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorPalette.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                  border: isSelected
                      ? null
                      : Border.all(color: ColorPalette.neutral600),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: FontSizePalette.size14,
                    fontVariations: [
                      FontVariation('wght', isSelected ? 700 : 500),
                    ],
                    color: isSelected
                        ? ColorPalette.neutral900
                        : ColorPalette.neutral0,
                  ),
                ),
              ),
            );
          }),

          // 次へ
          IconButton(
            onPressed: _currentPage < _totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: _currentPage < _totalPages - 1
                  ? ColorPalette.neutral0
                  : ColorPalette.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryVideoData {
  final String title;
  final String companyName;
  final String thumbnail;
  final String watchedAt;

  const _HistoryVideoData({
    required this.title,
    required this.companyName,
    required this.thumbnail,
    required this.watchedAt,
  });
}
