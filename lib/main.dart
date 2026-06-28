import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlpenApp());
}

class AlpenApp extends StatelessWidget {
  const AlpenApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ALPEN',
    theme: AlpenTheme.light,
    home: const SplashPage(),
  );
}
