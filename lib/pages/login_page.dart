import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/navigation.dart';
import '../services/mongo_service.dart';
import '../services/session_service.dart';
import '../widgets/alpen_mark.dart';
import '../widgets/app_widgets.dart';
import 'admin/admin_home_page.dart';
import 'otp_page.dart';
import 'personal_data_page.dart';
import 'register_page.dart';
import 'user_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final identity = TextEditingController();
  final password = TextEditingController();
  bool waiting = false;
  Future<void> _login() async {
    if (identity.text.trim().isEmpty || password.text.isEmpty) return showMessage(context, 'Lengkapi email/username dan kata sandi.');
    setState(() => waiting = true);
    try {
      final user = await MongoService.instance.login(identity.text, password.text);
      if (!mounted) return;
      if (user == null) return showMessage(context, 'Email/username atau kata sandi tidak sesuai.');
      Widget page;
      if (user['role'] == 'admin') {
        await SessionService.saveUser(user);
        page = AdminHomePage(user: user);
      } else if (user['profileCompleted'] != true) {
        await SessionService.saveUser(user);
        page = PersonalDataPage(user: user);
      } else {
        await SessionService.saveUser(user);
        page = UserHomePage(user: user);
      }
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => page), (_) => false);
    } catch (error) { if (mounted) showMessage(context, friendlyError(error)); }
    finally { if (mounted) setState(() => waiting = false); }
  }
  @override void dispose() { identity.dispose(); password.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AuthScaffold(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Center(child: AlpenMark()),
    const SizedBox(height: 18),
    const Text('Login', style: TextStyle(color: alpenGreen, fontSize: 20, fontWeight: FontWeight.w800)),
    const SizedBox(height: 13),
    AppField(label: 'Email', controller: identity),
    AppField(label: 'Kata Sandi', controller: password, obscure: true),
    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => pushPage(context, const OtpPage()), child: const Text('Lupa kata sandi?', style: TextStyle(color: alpenGreen, fontWeight: FontWeight.w700)))),
    const SizedBox(height: 12),
    PrimaryButton(label: 'Masuk', waiting: waiting, onTap: _login),
    const SizedBox(height: 18),
    Center(child: Wrap(children: [const Text('Belum punya akun? '), GestureDetector(onTap: () => pushPage(context, const RegisterPage()), child: const Text('Daftar', style: TextStyle(color: alpenBlue, fontWeight: FontWeight.w800)))])),
  ]));
}
