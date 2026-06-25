import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// Run with MONGODB_URI and ADMIN_PASSWORD environment variables.
Future<void> main() async {
  final uri = Platform.environment['MONGODB_URI'];
  final password = Platform.environment['ADMIN_PASSWORD'];
  if (uri == null || password == null) {
    stderr.writeln('MONGODB_URI and ADMIN_PASSWORD are required.');
    exitCode = 64;
    return;
  }
  final db = await Db.create(uri);
  await db.open();
  try {
    final users = db.collection('users');
    final existing = await users.findOne(where.eq('username', 'admin'));
    if (existing != null) {
      stdout.writeln('Admin already exists; no change made.');
      return;
    }
    final salt = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    await users.insertOne({
      'name': 'Administrator',
      'username': 'admin',
      'email': 'rioswebdev@gmail.com',
      'role': 'admin',
      'salt': salt,
      'passwordHash': sha256.convert('$salt:$password'.codeUnits).toString(),
      'profileCompleted': true,
      'createdAt': DateTime.now().toUtc(),
    });
    stdout.writeln('Admin created.');
  } finally {
    await db.close();
  }
}
