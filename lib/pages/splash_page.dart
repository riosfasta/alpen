import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'login_page.dart';
import 'admin/admin_home_page.dart';
import 'personal_data_page.dart';
import 'user_home_page.dart';
import '../services/session_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}
class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _openNextPage();
  }
  Future<void> _openNextPage() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = await SessionService.restoreUser();
    if (!mounted) return;
    final page = user == null
        ? const LoginPage()
        : user['role'] == 'admin'
            ? AdminHomePage(user: user)
            : user['profileCompleted'] == true
                ? UserHomePage(user: user)
                : PersonalDataPage(user: user);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(color: alpenBlue),
      child: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/splash_background.png', fit: BoxFit.cover)),
        Center(child: Image.asset('assets/images/splash_icon.png', width: 185, fit: BoxFit.contain)),
      ]),
    ),
  );
}
