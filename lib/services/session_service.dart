import 'package:shared_preferences/shared_preferences.dart';

import 'mongo_service.dart';

class SessionService {
  static const _emailKey = 'signed_in_email';

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final email = user['email']?.toString();
    if (email == null || email.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_emailKey, email);
  }

  static Future<Map<String, dynamic>?> restoreUser() async {
    final preferences = await SharedPreferences.getInstance();
    final email = preferences.getString(_emailKey);
    if (email == null || email.isEmpty) return null;
    try {
      final user = await MongoService.instance.findUserByEmail(email);
      if (user == null) await clear();
      return user;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_emailKey);
  }

}
