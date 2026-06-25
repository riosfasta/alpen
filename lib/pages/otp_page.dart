import 'dart:math';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/navigation.dart';
import '../services/mongo_service.dart';
import '../services/otp_mailer.dart';
import '../widgets/alpen_mark.dart';
import '../widgets/app_widgets.dart';
import 'reset_password_page.dart';

class OtpPage extends StatefulWidget { const OtpPage({super.key}); @override State<OtpPage> createState() => _OtpPageState(); }
class _OtpPageState extends State<OtpPage> {
  final email = TextEditingController(), code = TextEditingController();
  bool sent = false, waiting = false; String? developmentCode;
  Future<void> _send() async {
    final address = email.text.trim().toLowerCase();
    if (address.isEmpty) return showMessage(context, 'Masukkan email yang terdaftar.');
    setState(() => waiting = true);
    try {
      if (!await MongoService.instance.emailExists(address)) { if (mounted) showMessage(context, 'Email belum terdaftar.'); return; }
      final otp = (1000 + Random.secure().nextInt(9000)).toString();
      await MongoService.instance.saveOtp(address, otp);
      final delivered = await OtpMailer.send(address, otp);
      const showOtp = bool.fromEnvironment('SHOW_OTP', defaultValue: false);
      if (!delivered && !showOtp) { if (mounted) showMessage(context, 'Layanan email belum dikonfigurasi. Hubungi administrator.'); return; }
      if (mounted) setState(() { sent = true; developmentCode = showOtp ? otp : null; });
    } catch (error) { if (mounted) showMessage(context, friendlyError(error)); }
    finally { if (mounted) setState(() => waiting = false); }
  }
  Future<void> _verify() async {
    if (code.text.trim().length != 4) return showMessage(context, 'Masukkan 4 digit kode OTP.');
    setState(() => waiting = true);
    try { final valid = await MongoService.instance.verifyOtp(email.text.trim().toLowerCase(), code.text.trim()); if (!mounted) return; if (!valid) return showMessage(context, 'Kode OTP salah atau sudah kedaluwarsa.'); replacePage(context, ResetPasswordPage(email: email.text.trim().toLowerCase())); }
    catch (error) { if (mounted) showMessage(context, friendlyError(error)); }
    finally { if (mounted) setState(() => waiting = false); }
  }
  @override void dispose() { email.dispose(); code.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AuthScaffold(showBack: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Center(child: AlpenMark()), const SizedBox(height: 34), Text(sent ? 'Lupa Kata Sandi' : 'Lupa Kata Sandi', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 7),
    if (!sent) AppField(label: 'Email', controller: email, keyboard: TextInputType.emailAddress) else ...[Text('Email terdaftar ${email.text}', style: const TextStyle(color: Color(0xFF667085))), const SizedBox(height: 18), OtpCodeInput(onChanged: (value) => code.text = value), const SizedBox(height: 16), const Center(child: Text('Masukkan kode yang dikirim ke email anda', style: TextStyle(color: alpenBlue, fontSize: 12))), const SizedBox(height: 18)],
    if (developmentCode != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('Mode pengembangan — OTP: $developmentCode', style: const TextStyle(color: Colors.orange))),
    PrimaryButton(label: sent ? 'Verifikasi Sekarang' : 'Kirim OTP', waiting: waiting, onTap: sent ? _verify : _send),
    if (sent) Padding(padding: const EdgeInsets.only(top: 16), child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(onPressed: waiting ? null : _send, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEAEAEA), foregroundColor: alpenGreen, elevation: 0), icon: const Icon(Icons.restart_alt_rounded), label: const Text('Kirim Ulang OTP')))),
  ]));
}
