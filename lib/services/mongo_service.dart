import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  MongoService._();
  static final instance = MongoService._();

  // Koneksi MongoDB yang sudah ada dipertahankan.
  static const _uri =
      'mongodb+srv://taspen_username:WLtJOI5Cz9PFwtg4@taspen.th8aleg.mongodb.net/';

  Future<T> _withDb<T>(Future<T> Function(Db db) action) async {
    final db = await Db.create(_uri);
    try {
      await db.open();
      return await action(db);
    } finally {
      await db.close();
    }
  }

  String hash(String password, String salt) =>
      sha256.convert('$salt:$password'.codeUnits).toString();

  Future<Map<String, dynamic>?> login(String identity, String password) =>
      _withDb((db) async {
        final user = await db.collection('users').findOne(
          where.eq('email', identity.trim().toLowerCase()).or(
                where.eq('username', identity.trim()),
              ),
        );
        if (user == null || user['passwordHash'] != hash(password, user['salt'])) {
          return null;
        }
        return user;
      });

  Future<Map<String, dynamic>?> findUserByEmail(String email) => _withDb(
        (db) => db.collection('users').findOne(
              where.eq('email', email.trim().toLowerCase()),
            ),
      );

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String username,
    required String password,
  }) => _withDb((db) async {
    final users = db.collection('users');
    final exists = await users.findOne(
      where.eq('email', email.trim().toLowerCase()).or(
            where.eq('username', username.trim()),
          ),
    );
    if (exists != null) throw StateError('Email atau username sudah terdaftar.');
    final salt = _salt();
    final user = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'username': username.trim(),
      'role': 'user',
      'salt': salt,
      'passwordHash': hash(password, salt),
      'profileCompleted': false,
      'createdAt': DateTime.now().toUtc(),
    };
    final result = await users.insertOne(user);
    user['_id'] = result.id;
    return user;
  });

  Future<bool> emailExists(String email) => _withDb((db) async =>
      await db.collection('users').findOne(where.eq('email', email)) != null);

  Future<void> saveOtp(String email, String code) => _withDb((db) async {
    final otps = db.collection('password_otps');
    await otps.remove(where.eq('email', email));
    await otps.insertOne({
      'email': email,
      'codeHash': hash(code, email),
      'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 10)),
      'createdAt': DateTime.now().toUtc(),
    });
  });

  Future<bool> verifyOtp(String email, String code) => _withDb((db) async {
    final otp = await db.collection('password_otps').findOne(where.eq('email', email));
    return otp != null &&
        otp['expiresAt'].isAfter(DateTime.now().toUtc()) &&
        otp['codeHash'] == hash(code, email);
  });

  Future<void> resetPassword(String email, String password) => _withDb((db) async {
    final salt = _salt();
    await db.collection('users').updateOne(
      where.eq('email', email),
      modify.set('salt', salt).set('passwordHash', hash(password, salt)),
    );
    await db.collection('password_otps').remove(where.eq('email', email));
  });

  Future<void> updateProfile(ObjectId id, Map<String, dynamic> values) => _withDb(
        (db) => db.collection('users').updateOne(where.id(id), modify.set('profile', values)),
      );

  Future<void> updateFamily(ObjectId id, Map<String, dynamic> values) => _withDb(
        (db) => db.collection('users').updateOne(
              where.id(id),
              modify.set('family', values).set('profileCompleted', true),
            ),
      );

  Future<void> submitDeathReport(Map<String, dynamic> values) => _withDb((db) async {
    await db.collection('death_reports').insertOne({
      ...values,
      'status': 'Pengajuan Baru',
      'createdAt': DateTime.now().toUtc(),
    });
  });

  Future<List<Map<String, dynamic>>> findDeathReports(ObjectId userId) => _withDb(
        (db) => db
            .collection('death_reports')
            .find(where.eq('userId', userId).sortBy('createdAt', descending: true))
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );

  Future<List<Map<String, dynamic>>> findAllDeathReports() => _withDb(
        (db) => db
            .collection('death_reports')
            .find(where.sortBy('createdAt', descending: true))
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );

  Future<void> updateDeathReport(ObjectId id, {required String status, String? rejectionReason}) => _withDb((db) async {
    final update = modify.set('status', status);
    if (rejectionReason != null) update.set('rejectionReason', rejectionReason);
    await db.collection('death_reports').updateOne(where.id(id), update);
  });

  Future<void> publishAnnouncement(Map<String, dynamic> values) => _withDb((db) => db.collection('announcements').insertOne({...values, 'status': 'Aktif', 'createdAt': DateTime.now().toUtc()}));

  Future<List<Map<String, dynamic>>> findAnnouncements() => _withDb(
        (db) => db
            .collection('announcements')
            .find(where.sortBy('createdAt', descending: true))
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );

  String _salt() => List.generate(
        24,
        (_) => Random.secure().nextInt(36).toRadixString(36),
      ).join();
}
