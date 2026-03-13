// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

const String _fontFamily = 'NotoSansJP';

// カラーパレット
class ColorPalette {
  // 白色（テキスト、カード背景など）
  static const Color neutral0 = Color(0xFFFFFFFF);
  // 背景色（ダークテーマ用）
  static const Color neutral100 = Color(0xFF0A0A0A);
  // 区切り線、枠線色
  static const Color neutral200 = Color(0xFF222222);
  // ライトグレー（サブテキスト）
  static const Color neutral300 = Color(0xFFB0B0B0);
  // グレー（ヒントテキスト）
  static const Color neutral400 = Color(0xFF888888);
  // グレーテキスト色
  static const Color neutral500 = Color(0xFF666666);
  // ダークグレー（区切り線）
  static const Color neutral600 = Color(0xFF333333);
  // ダーク背景
  static const Color neutral800 = Color(0xFF1A1A1A);
  // 純黒（メイン背景）
  static const Color neutral900 = Color(0xFF000000);

  // システムカラー
  static const Color primaryColor = Color(0xFFDAA520); // メインゴールド
  static const Color primaryDark = Color(0xFFB8860B); // ダークゴールド
  static const Color primaryLight = Color(0xFFFFD700); // ライトゴールド
  static const Color primaryPale = Color(0xFFFFFBED); // ほぼ白のゴールド
  static const Color systemGold = Color(0xFFDAA520);
  static const Color systemGreen = Color(0xFF34C759);

  // グラデーション
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryLight, primaryColor],
  );
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

// テキストスタイル（Variable Font用にfontVariationsを使用）
class TextStylePalette {
  // スモールサブテキスト
  static TextStyle get smSubText => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral400,
    fontSize: FontSizePalette.size12,
    fontVariations: const [FontVariation('wght', 700)],
  );
  // スモールテキスト
  static TextStyle get smText => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size12,
    fontVariations: const [FontVariation('wght', 700)],
  );
  // ミニタイトル
  // タグ内のテキスト
  static TextStyle get miniTitle => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size12,
    fontVariations: const [FontVariation('wght', 800)],
  );
  // スモールサブタイトル
  static TextStyle get smSubTitle => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral400,
    fontSize: FontSizePalette.size12,
    fontVariations: const [FontVariation('wght', 700)],
  );
  // ヒントテキスト
  // 入力フィールドのヒントテキストなど
  static TextStyle get hintText => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral400,
    fontSize: FontSizePalette.size14,
    fontVariations: const [FontVariation('wght', 500)],
  );
  // サブテキスト
  static TextStyle get subText => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral400,
    fontSize: FontSizePalette.size14,
    fontVariations: const [FontVariation('wght', 700)],
  );
  // テキスト（通常）
  // チャット欄のテキストなど
  static TextStyle get normalText => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size14,
    fontVariations: const [FontVariation('wght', 700)],
  );
  // スモールタイトル
  // 入力フィールド上のタイトルなど
  // 例: 「メールアドレス」
  static TextStyle get smTitle => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size14,
    fontVariations: const [FontVariation('wght', 800)],
  );
  // サブテキスト（大）
  static TextStyle get bigSubText => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral400,
    fontSize: FontSizePalette.size16,
    fontVariations: const [FontVariation('wght', 700)],
  );
  // テキスト（大）
  static TextStyle get bigText => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size16,
    fontVariations: const [FontVariation('wght', 700)],
  );

  // サブガイドテキスト
  // ガイドテキストを補助する役割
  static TextStyle get subGuide => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral400,
    fontSize: FontSizePalette.size12,
    fontVariations: const [FontVariation('wght', 600)],
  );
  // ガイドテキスト
  // 例: 「パスワードを忘れた方はこちら」
  static TextStyle get guide => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.primaryColor,
    fontSize: FontSizePalette.size12,
    fontVariations: const [FontVariation('wght', 800)],
  );
  // Dividerテキスト
  // Divider上に表示するテキスト
  // 例: 「または」
  static TextStyle get dividerText => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral400,
    fontSize: FontSizePalette.size12,
    fontVariations: const [FontVariation('wght', 700)],
  );
  // リスト内のtitleテキスト
  static TextStyle get smListTitle => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size14,
    fontVariations: const [FontVariation('wght', 800)],
  );
  // リスト内のleadingテキスト
  static TextStyle get smListLeading => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral400,
    fontSize: FontSizePalette.size12,
    fontVariations: const [FontVariation('wght', 700)],
  );
  // リストタップ後の詳細画面に表示するリストのtitleテキスト
  static TextStyle get lgListTitle => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size20,
    fontVariations: const [FontVariation('wght', 900)],
  );
  // リストタップ後の詳細画面に表示するリストのsubtitleテキスト
  static TextStyle get lgListLeading => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral400,
    fontSize: FontSizePalette.size16,
    fontVariations: const [FontVariation('wght', 700)],
  );
  // ボタン内テキスト（黒）
  static TextStyle get buttonTextWhite => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral900,
    fontSize: FontSizePalette.size16,
    fontVariations: const [FontVariation('wght', 900)],
  );
  // ボタン内テキスト（白）
  static TextStyle get buttonTextBlack => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size16,
    fontVariations: const [FontVariation('wght', 900)],
  );
  // AppBar/セクションタイトル
  static TextStyle get title => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size16,
    fontVariations: const [FontVariation('wght', 800)],
  );
  // 小見出し
  static TextStyle get smHeader => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size18,
    fontVariations: const [FontVariation('wght', 900)],
  );
  // ヘッダーテキスト
  static TextStyle get header => TextStyle(
    fontFamily: _fontFamily,
    color: ColorPalette.neutral0,
    fontSize: FontSizePalette.size24,
    fontVariations: const [FontVariation('wght', 900)],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = TextTheme(
      displayLarge: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 900)]),
      displayMedium: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 900)]),
      displaySmall: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 800)]),
      headlineLarge: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 800)]),
      headlineMedium: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 800)]),
      headlineSmall: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 700)]),
      titleLarge: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 800)]),
      titleMedium: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 700)]),
      titleSmall: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 700)]),
      bodyLarge: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 600)]),
      bodyMedium: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 600)]),
      bodySmall: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 600)]),
      labelLarge: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 700)]),
      labelMedium: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 600)]),
      labelSmall: TextStyle(fontFamily: _fontFamily, color: ColorPalette.neutral0, fontVariations: const [FontVariation('wght', 600)]),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      colorScheme: ColorScheme.dark(
        primary: ColorPalette.primaryColor,
        secondary: ColorPalette.primaryColor,
        surface: ColorPalette.neutral900,
        onPrimary: ColorPalette.neutral900,
        onSecondary: ColorPalette.neutral900,
        onSurface: ColorPalette.neutral0,
        outline: ColorPalette.neutral600,
      ),
      scaffoldBackgroundColor: ColorPalette.neutral900,
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStylePalette.title,
        iconTheme: const IconThemeData(color: ColorPalette.neutral0),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.neutral800,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.inner,
          vertical: SpacePalette.sm,
        ),
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
          borderSide: const BorderSide(color: ColorPalette.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStylePalette.normalText,
        hintStyle: TextStylePalette.hintText,
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primaryColor,
          foregroundColor: ColorPalette.neutral900,
          minimumSize: const Size(double.infinity, ButtonSizePalette.button),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusPalette.base),
          ),
          textStyle: TextStylePalette.buttonTextWhite,
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorPalette.primaryColor,
          side: const BorderSide(color: ColorPalette.primaryColor, width: 2),
          minimumSize: const Size(double.infinity, ButtonSizePalette.button),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusPalette.base),
          ),
          textStyle: TextStylePalette.buttonTextBlack,
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorPalette.primaryColor,
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontVariations: const [FontVariation('wght', 700)],
          ),
        ),
      ),

      // Card - ダーク背景
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.lg),
          side: const BorderSide(color: ColorPalette.neutral600, width: 1),
        ),
        color: ColorPalette.neutral800,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: ColorPalette.neutral600,
        thickness: 1,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: ColorPalette.neutral0,
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        textColor: ColorPalette.neutral0,
        iconColor: ColorPalette.neutral0,
        tileColor: ColorPalette.neutral800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorPalette.neutral900,
        selectedItemColor: ColorPalette.primaryColor,
        unselectedItemColor: ColorPalette.neutral400,
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: ColorPalette.primaryColor,
        unselectedLabelColor: ColorPalette.neutral400,
        indicatorColor: ColorPalette.primaryColor,
        labelStyle: TextStyle(fontFamily: _fontFamily, fontVariations: const [FontVariation('wght', 700)]),
        unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontVariations: const [FontVariation('wght', 600)]),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: ColorPalette.neutral800,
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          color: ColorPalette.neutral0,
          fontVariations: const [FontVariation('wght', 600)],
        ),
        side: const BorderSide(color: ColorPalette.neutral600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: ColorPalette.neutral800,
        titleTextStyle: TextStylePalette.title,
        contentTextStyle: TextStylePalette.normalText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.lg),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorPalette.neutral800,
        contentTextStyle: TextStylePalette.normalText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorPalette.primaryColor,
        foregroundColor: ColorPalette.neutral900,
      ),

      // ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ColorPalette.primaryColor,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorPalette.primaryColor;
          }
          return ColorPalette.neutral400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorPalette.primaryColor.withOpacity(0.5);
          }
          return ColorPalette.neutral600;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorPalette.primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(ColorPalette.neutral900),
        side: const BorderSide(color: ColorPalette.neutral400, width: 2),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorPalette.primaryColor;
          }
          return ColorPalette.neutral400;
        }),
      ),
    );
  }
}

/// グラデーション付きボタンウィジェット
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = ButtonSizePalette.button,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: isEnabled ? ColorPalette.primaryGradient : null,
        color: isEnabled ? null : ColorPalette.neutral600,
        borderRadius: BorderRadius.circular(RadiusPalette.base),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: ColorPalette.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorPalette.neutral0,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: FontSizePalette.size16,
                          fontVariations: const [FontVariation('wght', 900)],
                          color: ColorPalette.neutral900,
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: SpacePalette.base),
                        icon!,
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
