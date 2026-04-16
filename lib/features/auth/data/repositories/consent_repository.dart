import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsentRepository {
  final SupabaseClient _supabase;

  ConsentRepository(this._supabase);

  /// 外部API（ipify）からグローバルIPアドレスを取得
  Future<String?> _getIpAddress() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ip'] as String?;
      }
    } catch (e) {
      debugPrint('IP取得エラー: $e');
    }
    return null;
  }

  /// 端末情報を取得
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return {
          'platform': 'web',
          'browser': webInfo.browserName.name,
          'user_agent': webInfo.userAgent,
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'os_version': 'Android ${androidInfo.version.release}',
          'sdk_int': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'device_name': iosInfo.name,
          'os_version': 'iOS ${iosInfo.systemVersion}',
        };
      }
    } catch (e) {
      debugPrint('端末情報取得エラー: $e');
    }
    return {'platform': 'unknown'};
  }

  /// 同意記録を保存
  /// [userId] ユーザーID
  /// [companyId] 企業ID（法人登録時のみ）
  /// [agreementTypes] 同意する規約の種類リスト（'terms', 'privacy', 'company_contract'）
  /// [agreementVersion] 規約バージョン
  Future<void> saveConsentLogs({
    required String userId,
    String? companyId,
    required List<String> agreementTypes,
    required String agreementVersion,
  }) async {
    final ipAddress = await _getIpAddress();
    final deviceInfo = await _getDeviceInfo();

    final logs = agreementTypes.map((type) => {
      'user_id': userId,
      'company_id': companyId,
      'agreement_type': type,
      'agreement_version': agreementVersion,
      'ip_address': ipAddress,
      'device_info': deviceInfo,
    }).toList();

    await _supabase.from('consent_logs').insert(logs);
  }
}
