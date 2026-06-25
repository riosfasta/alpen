import 'package:flutter/material.dart';

import '../core/navigation.dart';
import '../services/mongo_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/alpen_mark.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget { const ResetPasswordPage({super.key, required this.email}); final String email; @override State<ResetPasswordPage> createState() => _ResetPasswordPageState(); }
class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final password = TextEditingController(), confirm = TextEditingController(); bool waiting = false;
  Future<void> _save() async {
    if (password.text.length < 6) return showMessage(context, 'Kata sandi minimal 6 karakter.');
    if (password.text != confirm.text) return showMessage(context, 'Konfirmasi kata sandi tidak sama.');
    setState(() => waiting = true);
    try { await MongoService.instance.resetPassword(widget.email, password.text); if (!mounted) return; await successDialog(context, 'Kata Sandi Berhasil Diubah!', 'Silakan masuk menggunakan kata sandi baru Anda', actionLabel: 'Kembali ke Halaman Login'); if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false); }
    catch (error) { if (mounted) showMessage(context, friendlyError(error)); }
    finally { if (mounted) setState(() => waiting = false); }
  }
  @override void dispose() { password.dispose(); confirm.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AuthScaffold(showBack: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Center(child: AlpenMark()), const SizedBox(height: 34), const Text('Kata Sandi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
    AppField(label: 'Kata Sandi', controller: password, obscure: true), AppField(label: 'Konfirmasi Kata Sandi', controller: confirm, obscure: true), const SizedBox(height: 8), PrimaryButton(label: 'Simpan Kata Sandi Baru', waiting: waiting, onTap: _save),
  ]));
}
