import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/navigation.dart';
import '../services/session_service.dart';
import '../widgets/alpen_mark.dart';
import 'death_report_page.dart';
import 'face_authentication_page.dart';
import 'login_page.dart';
import 'news_page.dart';
import 'notification_page.dart';
import 'status_report_page.dart';
import 'user_profile_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({
    super.key,
    required this.user,
    this.initialAuthenticated = false,
  });

  final Map<String, dynamic> user;
  final bool initialAuthenticated;

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int tab = 0;
  int statusRefreshToken = 0;
  late bool authenticatedInCurrentSession;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    authenticatedInCurrentSession = widget.initialAuthenticated;
    pages = [
      _homeTab(),
      _ApplicationTab(openReport: _openDeathReport),
      StatusReportPage(
        key: ValueKey('status-$statusRefreshToken'),
        user: widget.user,
      ),
      UserProfilePage(user: widget.user),
    ];
  }

  Widget _homeTab() => _HomeTab(
    name: widget.user['name'] ?? 'Pengguna',
    authenticated: authenticatedInCurrentSession,
    openReport: _openDeathReport,
    openAuthentication: _openAuthentication,
  );

  Future<void> _openDeathReport() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => DeathReportPage(user: widget.user)),
    );
    if (result == 'status' && mounted) {
      setState(() {
        statusRefreshToken++;
        pages[2] = StatusReportPage(
          key: ValueKey('status-$statusRefreshToken'),
          user: widget.user,
        );
        tab = 2;
      });
    }
  }

  Future<void> _openAuthentication() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => FaceAuthenticationPage(user: widget.user),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        authenticatedInCurrentSession = true;
        widget.user
          ..clear()
          ..addAll(result);
        pages[0] = _homeTab();
        pages[3] = UserProfilePage(user: widget.user);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(index: tab, children: pages),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      indicatorColor: alpenMint,
      onDestinationSelected: (value) => setState(() => tab = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Pengajuan',
        ),
        NavigationDestination(
          icon: Icon(Icons.track_changes_outlined),
          selectedIcon: Icon(Icons.track_changes),
          label: 'Status',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    ),
  );
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.name,
    required this.authenticated,
    required this.openReport,
    required this.openAuthentication,
  });

  final String name;
  final bool authenticated;
  final VoidCallback openReport;
  final VoidCallback openAuthentication;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AlpenMark(width: 112),
            IconButton(
              onPressed: () => pushPage(context, const NotificationPage()),
              icon: const Badge(
                child: Icon(Icons.notifications, color: alpenBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Halo, Selamat Datang, $name',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 18),
        const Text(
          'Layanan Kami',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: alpenGreen,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ServiceTile(
                label: 'Pelaporan Kematian',
                icon: Icons.assignment_rounded,
                color: alpenBlue,
                onTap: openReport,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ServiceTile(
                label: authenticated ? 'Sudah Autentikasi' : 'Autentikasi',
                icon: authenticated
                    ? Icons.verified_user_rounded
                    : Icons.account_circle_rounded,
                color: alpenGreen,
                onTap: openAuthentication,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Informasi & Pengumuman',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: alpenGreen,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          'Pembaruan Sistem Autentikasi Biometrik Akun',
          'Program Olahraga Lansia Setiap Minggu',
          'Pembaruan Mekanisme Pendaftaran Organisasi',
        ].map(_newsCard),
        Center(
          child: TextButton(
            onPressed: () => pushPage(context, const NewsPage()),
            child: const Text(
              'Lihat Semua ›',
              style: TextStyle(color: alpenGreen),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      height: 124,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _newsCard(String title) => Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    border: Border.all(color: const Color(0xFFEAECF0)),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    children: [
      Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: alpenMint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.campaign_outlined, color: alpenGreen),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sosialisasi',
              style: TextStyle(
                fontSize: 12,
                color: alpenBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            const Text(
              '02 Juni 2026',
              style: TextStyle(fontSize: 12, color: Color(0xFF98A2B3)),
            ),
          ],
        ),
      ),
    ],
  ),
);

class _ApplicationTab extends StatelessWidget {
  const _ApplicationTab({required this.openReport});

  final VoidCallback openReport;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_outlined, size: 60, color: alpenBlue),
          const SizedBox(height: 12),
          const Text(
            'Pengajuan Layanan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: openReport,
              child: const Text('Pelaporan Kematian'),
            ),
          ),
        ],
      ),
    ),
  );
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
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            await SessionService.clear();
            if (context.mounted)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
          },
          child: const Text('Log Out'),
        ),
      ),
    ],
  ),
);
