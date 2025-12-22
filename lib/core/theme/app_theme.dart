// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// カラーパレット
class ColorPalette {
  // カード色、白テキスト色
  static const Color neutral0 = Color(0xFFFFFFFF);
  // 背景色
  static const Color neutral100 = Color(0xFFF5F5F5);
  // 区切り線、枠線色
  static const Color neutral200 = Color(0xFFE5E5E5);
  // ヒントテキスト色
  static const Color neutral400 = Color(0xFFA3A3A3);
  // グレーテキスト色
  static const Color neutral500 = Color(0xFF737373);
  // 黒テキスト色（メイン）
  static const Color neutral800 = Color(0xFF262626);
  
  // システムカラー
  static const Color primaryColor = Color(0xFFFF6c36);
  static const Color systemGreen = Color(0xFF22C55E);
}

// フォントサイズ
class FontSizePalette {
  // 注意書き、カード内テキスト、タグチップ内、リストタイル2の文字サイズ
  static const double size12 = 12.0;
  // チャット、フィールド上、カード内ボタン内（通常文字）
  static const double size14 = 14.0;
  // 横長ボタン、AppBarヘッダー、リストタイル1の文字サイズ
  static const double size16 = 16.0;
  // 小見出し
  static const double size18 = 18.0;
  // リスト関係（大）のタイトル
  static const double size20 = 20.0;
  // 見出し
  static const double size24 = 24.0;
}

// 間隔
class SpacePalette {
  // 隣接間隔
  static const double xs = 4.0;
  // 付随項目（タイトルとフィールドなど）の間隔
  static const double sm = 8.0;
  // 内部padding
  static const double inner = 12.0;
  // 全体padding、別機能間隔
  static const double base = 16.0;
  // 大きめの間隔
  static const double lg = 24.0;
}

// 角丸 - 基本的にsmを使用
class RadiusPalette {
  // ミニボタンの角丸度
  static const double mini = 4.0;
  // 横長ボタンの角丸度
  static const double base = 8.0;
  // カードの角丸度
  static const double lg = 12.0;
}

// ボックスサイズ
class ButtonSizePalette {
  //　タグチップ高さ
  static const double tag = 30.0;
  // フィルターボックス
  static const double filter = 36.0;
  // カード内横長ボタン
  static const double innerButton = 40.0;
  // 横長ボタン、入力フィールド
  static const double button = 48.0;
}

// テキストスタイル
class TextStylePalette {
  // スモールサブテキスト
  static TextStyle smSubText = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral500,
    fontSize: FontSizePalette.size12,
  );
  // スモールテキスト
  static TextStyle smText = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral800,
    fontSize: FontSizePalette.size12,
  );
  // ミニタイトル
  // タグ内のテキスト
  static TextStyle miniTitle = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral800,
    fontSize: FontSizePalette.size12,
    fontWeight: FontWeight.bold
  );
    // スモールサブタイトル
  static TextStyle smSubTitle = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral500,
    fontSize: FontSizePalette.size12,
    fontWeight: FontWeight.bold
  );
  // ヒントテキスト
  // 入力フィールドのヒントテキストなど
  static TextStyle hintText = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral400,
    fontSize: FontSizePalette.size14,
  );
  // サブテキスト
  static TextStyle subText = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral500,
    fontSize: FontSizePalette.size14,
  );
  // テキスト（通常）
  // チャット欄のテキストなど
  static TextStyle normalText = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral800,
    fontSize: FontSizePalette.size14,
  );
  // スモールタイトル
  // 入力フィールド上のタイトルなど
  // 例: 「メールアドレス」
  static TextStyle smTitle = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral800,
    fontSize: FontSizePalette.size14,
    fontWeight: FontWeight.bold
  );
  // サブテキスト（大）
  static TextStyle bigSubText = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral500,
    fontSize: FontSizePalette.size16,
  );
  // テキスト（大）
  static TextStyle bigText = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral800,
    fontSize: FontSizePalette.size16,
  );

  // サブガイドテキスト
  // ガイドテキストを補助する役割
  // 例: 
  static TextStyle subGuide = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral500,
    fontSize: FontSizePalette.size12,
  );
  // ガイドテキスト
  // 例: 「パスワードを忘れた方はこちら」
  static TextStyle guide = GoogleFonts.notoSansJp(
    color: ColorPalette.primaryColor,
    fontSize: FontSizePalette.size12,
    fontWeight: FontWeight.bold
  );
  // Dividerテキスト
  // Divider上に表示するテキスト
  // 例: 「または」
  static TextStyle dividerText = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral500,
    fontSize: FontSizePalette.size12,
    fontWeight: FontWeight.bold
  );
  // リスト内のtitleテキスト
  static TextStyle smListTitle = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral800,
    fontSize: FontSizePalette.size14,
    fontWeight: FontWeight.bold
  );
  // リスト内のleadingテキスト
  static TextStyle smListLeading = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral500,
    fontSize: FontSizePalette.size12,
  );
  // リストタップ後の詳細画面に表示するリストのtitleテキスト
  static TextStyle lgListTitle = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral800,
    fontSize: FontSizePalette.size20,
    fontWeight: FontWeight.bold
  );
  // リストタップ後の詳細画面に表示するリストのsubtitleテキスト
  static TextStyle lgListLeading = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral500,
    fontSize: FontSizePalette.size16,
  );
  // ボタン内テキスト（白）
  static TextStyle buttonTextWhite = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size16,
    fontWeight: FontWeight.bold
  );
  // ボタン内テキスト（黒）
  static TextStyle buttonTextBlack = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral800,
    fontSize: FontSizePalette.size16,
    fontWeight: FontWeight.bold
  );
  // AppBar/セクションタイトル
  static TextStyle title = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral800,
    fontSize: FontSizePalette.size16,
    fontWeight: FontWeight.bold
  );
  // 小見出し
  static TextStyle smHeader = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral800,
    fontSize: FontSizePalette.size18,
    fontWeight: FontWeight.bold
  );
  // ヘッダーテキスト
  static TextStyle header = GoogleFonts.notoSansJp(
    color: ColorPalette.neutral800,
    fontSize: FontSizePalette.size24,
    fontWeight: FontWeight.bold
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.notoSansJpTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: ColorPalette.neutral800,
        surface: ColorPalette.neutral100,
        onPrimary: ColorPalette.neutral0,
        onSurface: ColorPalette.neutral800,
        outline: ColorPalette.neutral200,
      ),
      scaffoldBackgroundColor: ColorPalette.neutral100,
      textTheme: textTheme,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: ColorPalette.neutral100,
        foregroundColor: ColorPalette.neutral800,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStylePalette.title,
      ),
      
      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        // filled: true,
        fillColor: ColorPalette.neutral0,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.inner,
          vertical: SpacePalette.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          borderSide: const BorderSide(color: ColorPalette.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          borderSide: const BorderSide(color: ColorPalette.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          borderSide: const BorderSide(color: ColorPalette.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          borderSide: const BorderSide(color: ColorPalette.primaryColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          borderSide: const BorderSide(color: ColorPalette.primaryColor, width: 2),
        ),
        labelStyle: TextStylePalette.normalText,
        hintStyle: TextStylePalette.hintText,
      ),
      
      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primaryColor,
          foregroundColor: ColorPalette.neutral0,
          minimumSize: const Size(double.infinity, ButtonSizePalette.button),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusPalette.base),
          ),
          textStyle: TextStylePalette.buttonTextWhite,
        ),
      ),
      
      // Card - neutral0背景
      cardTheme: CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        shadowColor: ColorPalette.neutral800.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.lg),
        ),
        color: ColorPalette.neutral0,
      ),
    );
  }
}