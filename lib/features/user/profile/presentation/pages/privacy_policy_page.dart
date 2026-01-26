// profile/presentation/pages/privacy_policy_page.dart
import 'package:flutter/material.dart';
import 'package:numbers/core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          'プライバシーポリシー',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NBS プライバシーポリシー',
              style: TextStylePalette.smHeader,
            ),
            const SizedBox(height: SpacePalette.base),
            Text(
              '最終更新日: 2024年1月1日',
              style: TextStylePalette.smSubText,
            ),
            const SizedBox(height: SpacePalette.lg),

            _buildSection(
              '1. はじめに',
              '株式会社NBS（以下「当社」）は、本サービス「NBS」（以下「本サービス」）におけるユーザーの個人情報の取扱いについて、以下のとおりプライバシーポリシーを定めます。',
            ),

            _buildSection(
              '2. 収集する情報',
              '当社は、本サービスの提供にあたり、以下の情報を収集することがあります。\n\n'
              '【ユーザーから直接提供される情報】\n'
              '・氏名、メールアドレス\n'
              '・生年月日、性別\n'
              '・学歴、職歴\n'
              '・プロフィール情報\n\n'
              '【自動的に収集される情報】\n'
              '・端末情報（OS、ブラウザの種類等）\n'
              '・IPアドレス\n'
              '・Cookie情報\n'
              '・サービス利用履歴',
            ),

            _buildSection(
              '3. 情報の利用目的',
              '当社は、収集した情報を以下の目的で利用します。\n\n'
              '1. 本サービスの提供・運営\n'
              '2. ユーザーからのお問い合わせへの対応\n'
              '3. 本サービスの改善・新機能の開発\n'
              '4. 利用状況の分析・統計データの作成\n'
              '5. 不正利用の防止\n'
              '6. 重要なお知らせの送信\n'
              '7. マーケティング活動（ユーザーの同意がある場合）',
            ),

            _buildSection(
              '4. 情報の第三者提供',
              '当社は、以下の場合を除き、ユーザーの個人情報を第三者に提供することはありません。\n\n'
              '1. ユーザーの同意がある場合\n'
              '2. 法令に基づく場合\n'
              '3. 人の生命、身体または財産の保護のために必要がある場合\n'
              '4. 公衆衛生の向上または児童の健全な育成の推進のために特に必要がある場合\n'
              '5. 国の機関等が法令の定める事務を遂行することに対して協力する必要がある場合',
            ),

            _buildSection(
              '5. 情報の安全管理',
              '当社は、個人情報の漏洩、滅失またはき損の防止その他の個人情報の安全管理のために必要かつ適切な措置を講じます。',
            ),

            _buildSection(
              '6. Cookieの使用',
              '本サービスでは、ユーザー体験の向上およびサービス改善のためにCookieを使用しています。ユーザーは、ブラウザの設定によりCookieの受け入れを拒否することができますが、その場合、本サービスの一部機能が利用できなくなる可能性があります。',
            ),

            _buildSection(
              '7. ユーザーの権利',
              'ユーザーは、当社に対して以下の権利を行使することができます。\n\n'
              '・個人情報の開示請求\n'
              '・個人情報の訂正・削除請求\n'
              '・個人情報の利用停止請求\n\n'
              'これらの請求を行う場合は、本サービス内のお問い合わせフォームよりご連絡ください。',
            ),

            _buildSection(
              '8. 未成年者の個人情報',
              '18歳未満の方が本サービスを利用する場合は、保護者の同意を得た上でご利用ください。',
            ),

            _buildSection(
              '9. プライバシーポリシーの変更',
              '当社は、必要に応じて、本プライバシーポリシーを変更することがあります。変更した場合は、本サービス上で通知いたします。',
            ),

            _buildSection(
              '10. お問い合わせ',
              '本プライバシーポリシーに関するお問い合わせは、本サービス内のお問い合わせフォームよりご連絡ください。',
            ),

            const SizedBox(height: SpacePalette.lg * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacePalette.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStylePalette.smTitle,
          ),
          const SizedBox(height: SpacePalette.sm),
          Text(
            content,
            style: TextStylePalette.subText,
          ),
        ],
      ),
    );
  }
}
