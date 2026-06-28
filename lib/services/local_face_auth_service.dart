import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalFaceAuthService {
  LocalFaceAuthService._();
  static final instance = LocalFaceAuthService._();

  String _safeUserId(Object? userId) {
    final raw = userId?.toString() ?? 'unknown';
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String _pathKey(Object? userId) => 'face_reference_path_${_safeUserId(userId)}';
  String _identityKey(Object? userId) =>
      'face_reference_identity_${_safeUserId(userId)}';
  String _embeddingKey(Object? userId) =>
      'face_reference_embedding_${_safeUserId(userId)}';

  Future<File?> referenceImage(Object? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_pathKey(userId));
    if (path == null || path.isEmpty) return null;

    final file = File(path);
    if (await file.exists()) return file;

    await prefs.remove(_pathKey(userId));
    await prefs.remove(_identityKey(userId));
    await prefs.remove(_embeddingKey(userId));
    return null;
  }

  Future<bool> hasReferenceFor(Object? userId) async =>
      await referenceImage(userId) != null;

  Future<Map<String, dynamic>?> referenceIdentityData(Object? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_identityKey(userId));
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  Future<List<double>?> referenceEmbedding(Object? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_embeddingKey(userId));
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.map((item) => (item as num).toDouble()).toList();
    }
    return null;
  }

  Future<File> saveReferenceImage({
    required Object? userId,
    required File image,
    required Map<String, dynamic> identityData,
    required List<double> embedding,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final faceDirectory = Directory('${directory.path}${Platform.pathSeparator}face_auth');
    if (!await faceDirectory.exists()) {
      await faceDirectory.create(recursive: true);
    }

    final safeId = _safeUserId(userId);
    final extension = image.path.split('.').last.toLowerCase();
    final target = File(
      '${faceDirectory.path}${Platform.pathSeparator}reference_$safeId.${extension == 'png' ? 'png' : 'jpg'}',
    );
    final saved = await image.copy(target.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pathKey(userId), saved.path);
    await prefs.setString(_identityKey(userId), jsonEncode(identityData));
    await prefs.setString(_embeddingKey(userId), jsonEncode(embedding));

    return saved;
  }
}
