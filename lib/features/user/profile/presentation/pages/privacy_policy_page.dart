// profile/presentation/pages/privacy_policy_page.dart
import 'package:flutter/material.dart';
import 'package:numbers/core/theme/app_theme.dart';


class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _sections = [
    ('基本方針', '当社は、個人情報保護法その他関連法令を遵守し、利用者、法人会員、問い合わせ者その他本サービスに関係する者の情報を適切に取り扱います。'),
    ('第2条（取得する情報）', '当社は、以下の情報を取得することがあります。\n\n【利用者登録情報】\n氏名、ニックネーム、生年月日、性別、学校名、居住地、電話番号、メールアドレス、プロフィール、希望職種、希望勤務地、希望雇用形態、スキル、資格、履歴書情報、職務経歴、自己PRその他利用者が入力する情報\n\n【法人会員登録情報】\n法人名、屋号、代表者名、担当者名、部署名、電話番号、メールアドレス、所在地、請求先情報、支払情報、ウェブサイトURL、業種、求人情報、企業紹介文、画像、動画その他法人会員が入力又は提出する情報\n\n【コミュニケーション情報】\nDM内容、チャット内容、問い合わせ内容、サポート連絡内容\n\n【端末・ログ情報】\nIPアドレス、Cookie、広告識別子、端末識別情報、OS情報、ブラウザ情報、アプリバージョン、閲覧履歴、検索履歴、クリック履歴、ログイン履歴、利用状況\n\n【位置情報】\n地図表示、近隣企業検索その他のために取得する現在地情報\n\n【決済・請求関連情報】\n決済手段に関する情報、請求履歴、支払状況、取引履歴\n\n【AI関連入力情報】\nAI検索、AI提案、AI相談機能等に入力された文章、条件、質問内容、選択履歴'),
    ('第3条（取得方法）', '(1) 本人による入力、送信、登録、アップロード、問い合わせ\n(2) 本サービスの利用に伴う自動取得\n(3) Cookie、SDK、アクセス解析ツールその他技術的手段による取得\n(4) 提携先、決済事業者、認証事業者、地図サービス事業者その他第三者からの取得\n(5) 法令に基づく取得'),
    ('第4条（利用目的）', '(1) 本サービスの提供、本人確認、認証、審査、アカウント管理のため\n(2) 企業情報、募集情報、インターン情報等の表示、検索、提案のため\n(3) AIによる企業提案、求人提案、サービス改善のため\n(4) DM、チャット、問い合わせ対応、通知送信のため\n(5) 位置情報を用いた地図表示、近隣企業検索のため\n(6) 料金請求、支払確認、請求書発行のため\n(7) 不正利用防止、セキュリティ対策、規約違反調査のため\n(8) 統計分析、利用状況分析、機能改善、新サービス開発のため\n(9) アンケート、キャンペーン、広告配信、マーケティングのため\n(10) 法令対応、権利保護、紛争対応のため'),
    ('第5条（第三者提供）', '当社は、法令に基づく場合その他正当な理由がある場合を除き、本人の同意なく個人情報を第三者に提供しません。'),
    ('第6条（委託）', '当社は、システム開発、サーバー運用、メール配信、決済処理等の業務を外部事業者へ委託することがあります。'),
    ('第7条（Cookie等の利用）', '当社は、利便性向上、ログイン保持、利用状況把握、広告配信等のため、Cookie、SDKその他類似技術を利用することがあります。'),
    ('第8条（位置情報の利用）', '当社は、利用者の同意に基づき位置情報を取得し、近隣企業検索、地図表示その他本サービス提供のために利用します。'),
    ('第9条（AI関連情報の利用）', '当社は、AI機能の提供、改善、不正防止、分析のため、AI入力内容、行動履歴その他関連情報を利用することがあります。'),
    ('第10条（安全管理）', '当社は、不正アクセス、漏えい、改ざん、滅失、毀損等を防止するため、アクセス制御、認証、権限管理、通信の暗号化その他必要かつ適切な安全管理措置を講じます。'),
    ('第11条（保有期間）', '当社は、利用目的達成に必要な期間又は法令上必要な期間、個人情報を保有します。'),
    ('第12条（開示、訂正、削除、利用停止等）', '本人は、当社に対し、法令に基づき、自己に関する個人情報の開示、訂正、追加、削除、利用停止、消去、第三者提供停止等を請求することができます。'),
    ('第13条（未成年者）', '未成年者が本サービスを利用する場合、法定代理人の同意を得たうえで利用するものとします。'),
    ('第14条（ポリシーの変更）', '当社は、必要に応じて本ポリシーを変更することができます。'),
    ('第15条（お問い合わせ窓口）', 'NuMBerS株式会社\nNBS~New Business Swipe~ 個人情報窓口'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NBS~New Business Swipe~ プライバシーポリシー',
                style: TextStylePalette.smHeader),
            const SizedBox(height: SpacePalette.sm),
            Text('制定日・施行日：2026年4月2日', style: TextStylePalette.smSubText),
            const SizedBox(height: SpacePalette.lg),
            for (final (title, content) in _sections) ...[
              Text(title, style: TextStylePalette.smTitle),
              const SizedBox(height: SpacePalette.sm),
              Text(content, style: TextStylePalette.subText),
              const SizedBox(height: SpacePalette.lg),
            ],
          ],
        ),
      ),
    );
  }
}
