import 'dart:convert';

import 'package:http/http.dart' as http;

/// Pengiriman OTP langsung melalui Sendcorex REST API.
class OtpMailer {
  static const _endpoint = 'https://graph.sendcorex.com/v3.0/mail/send';
  static const _apiKey = String.fromEnvironment(
    'SENDCOREX_API_KEY',
    defaultValue: 'D.S.B.aNj6cvtSDuzo4FHl9a3xVgVDVavgepuv17BDkHi4ISpYbPMV3sD79y9lBmBl',
  );
  static const _from = 'hello.user@sendcorex.com';
  static const _senderName = 'ALPEN';

  static bool get configured => _apiKey.isNotEmpty;

  static Future<bool> send(String recipient, String code) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'to': recipient,
        'subject': 'Kode OTP Reset Kata Sandi ALPEN',
        'body': '<h2>Kode OTP ALPEN: $code</h2><p>Kode berlaku selama 10 menit.</p>',
        'from': _from,
        'senderName': _senderName,
      }),
    ).timeout(const Duration(seconds: 30));
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
