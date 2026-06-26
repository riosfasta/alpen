import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/report_number.dart';
import '../../services/mongo_service.dart';
import 'admin_announcements_page.dart';
import 'admin_applications_page.dart';
import 'admin_profile_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int tab = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      _Dashboard(user: widget.user),
      const AdminApplicationsPage(),
      const AdminAnnouncementsPage(),
      AdminProfilePage(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: IndexedStack(index: tab, children: pages)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) => setState(() => tab = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.list_alt), label: 'List Ajuan'),
            NavigationDestination(icon: Icon(Icons.campaign), label: 'Pengumuman'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      );
}

class _Dashboard extends StatefulWidget {
  const _Dashboard({required this.user});

  final Map<String, dynamic> user;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  final List<Map<String, dynamic>> reports = [];
  bool loading = true;
  String? errorText;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (mounted) {
      setState(() {
        loading = reports.isEmpty;
        errorText = null;
      });
    }
    try {
      final next = await MongoService.instance.findAllDeathReports();
      if (!mounted) return;
      setState(() {
        reports
          ..clear()
          ..addAll(next);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorText = 'Data pengajuan tidak dapat dimuat.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int count(String status) => reports.where((report) => report['status']?.toString() == status).length;
    final totalReports = reports.length;
    final reSubmitted = reports.where((report) {
      final status = report['status']?.toString();
      return status == 'Diajukan Kembali' || status == 'Menunggu Verifikasi';
    }).length;
    final approved = count('Disetujui');
    final rejected = count('Ditolak');

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Halo, ${widget.user['name'] ?? 'Admin'}\nSelamat Datang Kembali',
                style: const TextStyle(fontSize: 18, color: Color(0xFF667085)),
              ),
              const Icon(Icons.notifications, color: alpenBlue),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Statistik', style: TextStyle(color: alpenGreen, fontSize: 16)),
          const SizedBox(height: 10),
          if (loading)
            const LinearProgressIndicator()
          else if (errorText != null)
            Text(errorText!)
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Stat('$totalReports', 'Total Pengajuan', alpenBlue, Icons.article_outlined),
                _Stat('$reSubmitted', 'Menunggu Verifikasi', const Color(0xFFE97520), Icons.watch_later_outlined),
                _Stat('$approved', 'Pengajuan Disetujui', alpenGreen, Icons.check_circle_outline),
                _Stat('$rejected', 'Pengajuan Ditolak', const Color(0xFF990000), Icons.cancel_outlined),
              ],
            ),
          const SizedBox(height: 25),
          const Text('Pengajuan Terbaru', style: TextStyle(color: alpenGreen, fontSize: 16)),
          const SizedBox(height: 10),
          if (loading)
            const SizedBox.shrink()
          else if (reports.isEmpty)
            const Text('Belum ada pengajuan.')
          else
            ...reports.take(5).map(
                  (report) => _Recent(
                    reportNumberOf(report),
                    '${report['reporterName'] ?? '-'}',
                    _dateText(report['createdAt']),
                    '${report['status'] ?? 'Pengajuan Baru'}',
                  ),
                ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.count, this.label, this.color, this.icon);

  final String count;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 180,
        child: Container(
          height: 124,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 9),
                    Text(
                      count,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Recent extends StatelessWidget {
  const _Recent(this.number, this.name, this.date, this.status);

  final String number;
  final String name;
  final String date;
  final String status;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD0D5DD)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(label: Text(number)),
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
                ],
              ),
            ),
            Text(
              status,
              style: TextStyle(
                color: status == 'Disetujui' ? alpenGreen : status == 'Ditolak' ? Colors.red : Colors.deepOrange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

String _dateText(dynamic value) {
  final date = value is DateTime ? value.toLocal() : DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
