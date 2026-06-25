import 'package:flutter/material.dart';

import '../core/navigation.dart';
import '../services/mongo_service.dart';
import '../services/session_service.dart';
import '../widgets/alpen_mark.dart';
import '../widgets/app_widgets.dart';
import 'personal_data_page.dart';

class RegisterPage extends StatefulWidget { const RegisterPage({super.key}); @override State<RegisterPage> createState() => _RegisterPageState(); }
class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController(), email = TextEditingController(), username = TextEditingController(), password = TextEditingController(), confirm = TextEditingController();
  bool waiting = false;
  Future<void> _submit() async {
    if ([name, email, username, password, confirm].any((item) => item.text.trim().isEmpty)) return showMessage(context, 'Semua data wajib diisi.');
    if (password.text != confirm.text) return showMessage(context, 'Konfirmasi kata sandi tidak sama.');
    setState(() => waiting = true);
    try { final user = await MongoService.instance.register(name: name.text, email: email.text, username: username.text, password: password.text); await SessionService.saveUser(user); if (mounted) replacePage(context, PersonalDataPage(user: user)); }
    catch (error) { if (mounted) showMessage(context, friendlyError(error)); }
    finally { if (mounted) setState(() => waiting = false); }
  }
  @override void dispose() { for (final item in [name, email, username, password, confirm]) { item.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) => AuthScaffold(showBack: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Center(child: AlpenMark()), const SizedBox(height: 20), const Text('Registrasi', style: TextStyle(color: Color(0xFF416F54), fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 13),
    AppField(label: 'Nama Lengkap', controller: name), AppField(label: 'Email', controller: email, keyboard: TextInputType.emailAddress), AppField(label: 'Nomor Pegawai', controller: username, keyboard: TextInputType.number), AppField(label: 'Kata Sandi', controller: password, obscure: true), AppField(label: 'Konfirmasi Kata Sandi', controller: confirm, obscure: true), const SizedBox(height: 8), PrimaryButton(label: 'Daftar', waiting: waiting, onTap: _submit), const SizedBox(height: 14), const Center(child: Text('Sudah punya akun? Masuk', style: TextStyle(color: Color(0xFF416F54)))),
  ]));
}
