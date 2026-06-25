import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/announcement_feed.dart';
import 'admin_add_announcement_page.dart';

class AdminAnnouncementsPage extends StatelessWidget {
  const AdminAnnouncementsPage({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Informasi & Pengumuman', style: TextStyle(color: alpenGreen, fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      AnnouncementFeed(adminMode: true, onAdd: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddAnnouncementPage()))),
    ]),
  );
}
