import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/announcement_feed.dart';
import '../widgets/app_widgets.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});
  @override
  Widget build(BuildContext context) => FormScaffold(
    title: 'Informasi & Pengumuman',
    subtitle: 'Pengumuman terbaru dari administrator.',
    child: const AnnouncementFeed(),
  );
}
