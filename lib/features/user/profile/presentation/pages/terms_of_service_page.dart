// profile/presentation/pages/terms_of_service_page.dart
import 'package:flutter/material.dart';
import 'package:numbers/core/theme/app_theme.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          '利用規約',
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
              'NBS 利用規約',
              style: TextStylePalette.smHeader,
            ),
            const SizedBox(height: SpacePalette.base),
            Text(
              '最終更新日: 2024年1月1日',
              style: TextStylePalette.smSubText,
            ),
            const SizedBox(height: SpacePalette.lg),

            _buildSection(
              '第1条（適用）',
              '本規約は、本サービスの利用に関する条件を、本サービスを利用するすべてのユーザーと当社との間で定めるものです。ユーザーは、本サービスを利用することにより、本規約に同意したものとみなされます。',
            ),

            _buildSection(
              '第2条（定義）',
              '本規約において使用する用語の定義は、以下のとおりとします。\n\n'
              '1.「本サービス」とは、当社が提供する求人情報・企業動画配信サービス「NBS」をいいます。\n'
              '2.「ユーザー」とは、本サービスを利用する個人または法人をいいます。\n'
              '3.「コンテンツ」とは、本サービス上で提供される動画、画像、テキスト等の情報をいいます。',
            ),

            _buildSection(
              '第3条（利用登録）',
              '1. 本サービスの利用を希望する者は、当社の定める方法により利用登録を申請するものとします。\n'
              '2. 当社は、利用登録の申請者に以下の事由があると判断した場合、利用登録を拒否することがあります。\n'
              '  - 虚偽の事項を届け出た場合\n'
              '  - 本規約に違反したことがある者からの申請である場合\n'
              '  - その他、当社が利用登録を相当でないと判断した場合',
            ),

            _buildSection(
              '第4条（禁止事項）',
              'ユーザーは、本サービスの利用にあたり、以下の行為をしてはなりません。\n\n'
              '1. 法令または公序良俗に違反する行為\n'
              '2. 犯罪行為に関連する行為\n'
              '3. 当社または第三者の知的財産権を侵害する行為\n'
              '4. 当社または第三者の名誉・信用を毀損する行為\n'
              '5. 本サービスの運営を妨害する行為\n'
              '6. 不正アクセスまたはこれを試みる行為\n'
              '7. 他のユーザーになりすます行為\n'
              '8. その他、当社が不適切と判断する行為',
            ),

            _buildSection(
              '第5条（本サービスの提供の停止等）',
              '当社は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします。\n\n'
              '1. 本サービスにかかるコンピュータシステムの保守点検または更新を行う場合\n'
              '2. 地震、落雷、火災等の不可抗力により、本サービスの提供が困難となった場合\n'
              '3. その他、当社が本サービスの提供が困難と判断した場合',
            ),

            _buildSection(
              '第6条（免責事項）',
              '1. 当社は、本サービスに関して、ユーザーと他のユーザーまたは第三者との間において生じた取引、連絡または紛争等について一切責任を負いません。\n'
              '2. 当社は、本サービスに掲載される求人情報の正確性、完全性、有用性等について保証するものではありません。',
            ),

            _buildSection(
              '第7条（規約の変更）',
              '当社は、必要と判断した場合には、ユーザーに通知することなくいつでも本規約を変更することができるものとします。変更後の利用規約は、当社ウェブサイトに掲載したときから効力を生じるものとします。',
            ),

            _buildSection(
              '第8条（準拠法・裁判管轄）',
              '本規約の解釈にあたっては、日本法を準拠法とします。本サービスに関して紛争が生じた場合には、当社の本店所在地を管轄する裁判所を専属的合意管轄とします。',
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
