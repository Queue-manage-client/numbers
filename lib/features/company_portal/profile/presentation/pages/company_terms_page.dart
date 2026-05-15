// company_portal/profile/presentation/pages/company_terms_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/theme/app_theme.dart';


class CompanyTermsPage extends StatelessWidget {
  const CompanyTermsPage({super.key});

  static const _userTerms = [
    ('第1条（適用）', '本利用規約（以下「法人規約」といいます。）は、当社が提供する本サービスを利用して、企業情報、求人情報、インターン情報、アルバイト情報その他の情報を掲載し、又は法人向け機能を利用する法人、団体又は個人事業主（以下「法人会員」といいます。）に適用されます。\n法人会員は、法人規約、法人契約条項及びプライバシーポリシーに同意のうえ、本サービスを利用するものとします。'),
    ('第2条（法人向けサービス）', '当社は法人会員に対し、主として以下の機能を提供します。\n(1) 企業情報、求人情報、インターン情報、アルバイト情報等の掲載\n(2) スワイプ画面、検索画面、地図画面等への表示\n(3) AI提案対象としての表示\n(4) 利用者とのDM機能\n(5) チャット機能\n(6) 管理画面、請求画面その他当社所定の機能'),
    ('第3条（登録・審査）', '法人会員は、当社所定の方法により登録申請を行うものとします。\n当社は、審査の結果、登録を承認しない場合があります。'),
    ('第4条（掲載情報の責任）', '法人会員は、本サービスに掲載する企業情報、募集情報、雇用条件等一切の情報について責任を負うものとします。\n虚偽表示、誇大表示、架空求人等をしてはなりません。'),
    ('第5条（利用者への対応）', '法人会員は、本サービスを通じて接触した利用者に対し、誠実かつ適法に対応するものとします。'),
    ('第6条（利用料金）', '法人会員は、法人契約条項に定める料金、事務手数料、支払方法、最低利用期間、更新条件その他の条件に従い、利用料金を支払うものとします。'),
    ('第7条（禁止事項）', '(1) 虚偽又は不正確な求人掲載\n(2) 実在しない求人、採用意思のない募集\n(3) 法令違反の募集又は不当な労働条件表示\n(4) 差別的取扱い、ハラスメント、迷惑行為\n(5) 利用者情報の目的外利用又は無断提供\n(6) 本サービス運営を妨害する行為'),
    ('第8条（知的財産権・掲載素材）', '法人会員が当社に提供した素材について、当社が本サービスの運営に必要な範囲で使用できることを許諾するものとします。'),
    ('第9条（掲載停止・利用停止）', '当社は、法人会員が法人規約、法人契約条項又は法令に違反した場合、必要な措置を講じることができます。'),
    ('第10条（免責）', '当社は、法人会員による募集、採用、面談等の結果を保証しません。'),
    ('第11条（契約終了後）', '契約終了後も、未払金支払義務、損害賠償義務、秘密保持義務等は有効に存続するものとします。'),
    ('第12条（準拠法・管轄）', '法人規約は日本法に準拠します。'),
  ];

  static const _contractTerms = [
    ('第1条（目的）', '本契約条項は、法人会員が本サービスの有料プラン、掲載プラン、広告プラン、オプションプランその他有償サービスを利用する場合の条件を定めるものとします。'),
    ('第2条（契約成立）', '法人会員が当社所定の方法により申込みを行い、当社がこれを承諾した時点で、当該プランに関する個別契約が成立するものとします。'),
    ('第3条（初回事務手数料）', '法人会員は、いずれのプランを選択した場合であっても、初回に限り、事務手数料として1,000円（税抜）を支払うものとします。'),
    ('第4条（プラン内容）', '(1) 通常プラン：月額9,999円（税抜）、最低利用期間6か月\n(2) 特別プラン：月額8,999円（税抜）、最低利用期間12か月\n(3) 商工会プラン：月額1,000円（税抜）、最低利用期間36か月\n(4) トライアルプラン：3か月無料、終了後は特別プランへ自動移行'),
    ('第5条（支払方法）', '(1) 自動引落し\n(2) 銀行振込\n(3) アプリ内サブスクリプション\n(4) クレジットカード\n(5) その他当社所定の方法'),
    ('第6条（契約期間）', '各プランの最低利用期間は第4条に定めるとおりとし、解約の申出がない限り自動更新されるものとします。'),
    ('第9条（中途解約）', '月額支払の場合、最低利用期間内の中途解約はできないものとします。最低利用期間経過後は当社所定の手続で解約可能です。'),
    ('第11条（料金不払）', '支払期日までに料金を支払わない場合、当社は掲載停止、利用停止、契約解除その他必要な措置を講じることができます。'),
    ('第13条（返金）', '既に支払われた利用料金、初回事務手数料その他の金員は、法令上返金が必要な場合を除き返金しません。'),
    ('第20条（免責）', '当社は、当社に故意又は重過失がある場合を除き、逸失利益、特別損害、間接損害について責任を負いません。'),
    ('第21条（準拠法・管轄）', '本契約条項は日本法に準拠します。'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          title: const Text('法人向け規約'),
          bottom: const TabBar(
            indicatorColor: ColorPalette.primaryColor,
            labelColor: ColorPalette.primaryColor,
            unselectedLabelColor: ColorPalette.neutral500,
            tabs: [
              Tab(text: '利用規約'),
              Tab(text: '契約条項'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList('NBS~New Business Swipe~ 利用規約（法人向け）', _userTerms),
            _buildList('NBS~New Business Swipe~ 法人契約条項', _contractTerms),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String header, List<(String, String)> sections) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacePalette.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header, style: TextStylePalette.smHeader),
          const SizedBox(height: SpacePalette.sm),
          Text('制定日・施行日：2026年4月2日', style: TextStylePalette.smSubText),
          const SizedBox(height: SpacePalette.lg),
          for (final (title, content) in sections) ...[
            Text(title, style: TextStylePalette.smTitle),
            const SizedBox(height: SpacePalette.sm),
            Text(content, style: TextStylePalette.subText),
            const SizedBox(height: SpacePalette.lg),
          ],
        ],
      ),
    );
  }
}
