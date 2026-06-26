import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/mongo_service.dart';
import '../services/session_service.dart';
import 'login_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.user});
  final Map<String, dynamic> user;
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<Map<String, dynamic>?> _userFuture;
  @override
  void initState() {
    super.initState();
    _userFuture = MongoService.instance.findUserByEmail(widget.user['email']?.toString() ?? '');
  }

  Future<void> _refresh() async {
    setState(() => _userFuture = MongoService.instance.findUserByEmail(widget.user['email']?.toString() ?? ''));
    await _userFuture;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: _userFuture,
    builder: (context, snapshot) {
      final user = snapshot.data ?? widget.user;
      final profile = Map<String, dynamic>.from(user['profile'] as Map? ?? const {});
      final family = Map<String, dynamic>.from(user['family'] as Map? ?? const {});
      return RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Profil Anda', style: TextStyle(color: alpenBlue, fontSize: 21)),
            TextButton(onPressed: () => _logout(context), child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800))),
          ]),
          if (snapshot.connectionState == ConnectionState.waiting) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          const _Heading('Data Pribadi'),
          _InfoCard(rows: [
            ['Nama', _value(profile['name'], user['name'])],
            ['Nomor Induk Pegawai (NIP)', _value(profile['employeeNumber'], user['username'])],
            ['Email', _value(profile['email'], user['email'])],
            ['Nomor HP', _value(profile['phone'])],
            ['Alamat Lengkap', _value(profile['address'])],
            ['Tanggal Lahir', _value(profile['birthDate'])],
            ['Jenis Kelamin', _value(profile['gender'])],
            ['Status Pernikahan', _value(profile['maritalStatus'])],
            ['Nama Bank', _value(profile['bankName'])],
            ['No Rekening', _value(profile['accountNumber'])],
            ['Nama Pemilik Rekening', _value(profile['accountOwner'])],
          ]),
          const SizedBox(height: 18),
          const _Heading('Data Istri/Suami Pensiunan'),
          _InfoCard(rows: [
            ['Nama Istri/Suami', _value(family['spouseName'])],
            ['Tanggal Lahir', _value(family['spouseBirthDate'])],
            ['Status', _value(family['spouseStatus'])],
          ]),
          const SizedBox(height: 18),
          const _Heading('Data Anak Pensiunan'),
          _ChildrenCard(children: family['children']),
          const SizedBox(height: 18),
          const _Heading('Dokumen'),
          _DocumentPreview(label: 'Kartu Tanda Penduduk (KTP)', metadata: family['ktpDocument']),
          _DocumentPreview(label: 'Kartu Keluarga (KK)', metadata: family['kkDocument']),
          ]),
        ),
      );
    },
  );

  String _value(dynamic value, [dynamic fallback]) {
    final result = value ?? fallback;
    return result == null || result.toString().trim().isEmpty ? '-' : result.toString();
  }
}

class _Heading extends StatelessWidget { const _Heading(this.text); final String text; @override Widget build(BuildContext context) => Text(text, style: const TextStyle(color: alpenGreen, fontSize: 16)); }
class _InfoCard extends StatelessWidget { const _InfoCard({required this.rows}); final List<List<String>> rows; @override Widget build(BuildContext context) => Container(width: double.infinity, margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: alpenBlue), borderRadius: BorderRadius.circular(10)), child: Column(children: rows.map((row) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text('• ${row[0]}')), Flexible(child: Text(row[1], textAlign: TextAlign.right, style: const TextStyle(color: alpenBlue)))]))).toList())); }
class _ChildrenCard extends StatelessWidget { const _ChildrenCard({required this.children}); final dynamic children; @override Widget build(BuildContext context) { final items = children is List ? children : const []; if (items.isEmpty) return const _InfoCard(rows: [['Data Anak', '-']]); return _InfoCard(rows: List.generate(items.length, (index) { final child = Map<String, dynamic>.from(items[index] as Map); return ['Anak ${index + 1}', '${child['name'] ?? '-'} (${child['birthDate'] ?? '-'})']; })); } }
class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.label, required this.metadata});
  final String label;
  final dynamic metadata;
  @override
  Widget build(BuildContext context) {
    final data = metadata is Map ? Map<String, dynamic>.from(metadata) : <String, dynamic>{};
    final path = data['path']?.toString();
    final name = data['name']?.toString() ?? 'Belum ada dokumen';
    final image = path != null && RegExp(r'\.(jpg|jpeg)$', caseSensitive: false).hasMatch(path) && File(path).existsSync();
    return Padding(padding: const EdgeInsets.only(top: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD0D5DD)), borderRadius: BorderRadius.circular(12)), child: image ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(path), height: 210, width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _fileLabel(name))) : _fileLabel(name)),
    ]));
  }
  Widget _fileLabel(String name) => Row(children: [const Icon(Icons.picture_as_pdf, color: alpenBlue), const SizedBox(width: 10), Expanded(child: Text(name)), const Icon(Icons.visibility, color: alpenBlue)]);
}
Future<void> _logout(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xFFFFDDDD),
          child: Icon(Icons.question_mark, color: Colors.red, size: 38),
        ),
        title: const Text(
          'Apakah Anda yakin Ingin Keluar dari akun ini?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Center(
              child: Text('Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await SessionService.clear();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
                }
              },
              child: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
