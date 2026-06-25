import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/alpen_mark.dart';
import '../core/navigation.dart';
import '../services/session_service.dart';
import '../widgets/announcement_feed.dart';
import 'death_report_page.dart';
import 'notification_page.dart';
import 'status_report_page.dart';
import 'news_page.dart';
import 'login_page.dart';
import 'user_profile_page.dart';

class UserHomePage extends StatefulWidget { const UserHomePage({super.key, required this.user}); final Map<String, dynamic> user; @override State<UserHomePage> createState() => _UserHomePageState(); }
class _UserHomePageState extends State<UserHomePage> {
  int tab = 0;
  late final List<Widget> pages;
  @override
  void initState() {
    super.initState();
    pages = [
      _HomeTab(name: widget.user['name'] ?? 'Pengguna', user: widget.user),
      _ApplicationTab(user: widget.user),
      StatusReportPage(user: widget.user),
      UserProfilePage(user: widget.user),
    ];
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, indicatorColor: alpenMint, onDestinationSelected: (value) => setState(() => tab = value), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'), NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Pengajuan'), NavigationDestination(icon: Icon(Icons.track_changes_outlined), selectedIcon: Icon(Icons.track_changes), label: 'Status'), NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
      ]),
    );
  }
}
class _HomeTab extends StatelessWidget { const _HomeTab({required this.name, required this.user}); final String name; final Map<String, dynamic> user; @override Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const AlpenMark(), IconButton(onPressed: () => pushPage(context, const NotificationPage()), icon: const Badge(child: Icon(Icons.notifications, color: alpenBlue)))]), const SizedBox(height: 20), Text('Halo, Selamat Datang, $name', style: const TextStyle(fontSize: 18, color: Colors.grey)), const SizedBox(height: 18),
  const Text('Layanan Kami', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: alpenGreen)), const SizedBox(height: 12), GestureDetector(onTap: () => pushPage(context, DeathReportPage(user: user)), child: _serviceCard()), const SizedBox(height: 18), const Text('Informasi & Pengumuman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: alpenGreen)), const SizedBox(height: 12), ...['Pembaruan Sistem Autentikasi Biometrik Akun', 'Program Olahraga Lansia Setiap Minggu', 'Pembaruan Mekanisme Pendaftaran Organisasi'].map(_newsCard), Center(child: TextButton(onPressed: () => pushPage(context, const NewsPage()), child: const Text('Lihat Semua  ›', style: TextStyle(color: alpenGreen)))),
  const SizedBox(height: 12),
  const AnnouncementFeed(),
]));
Widget _serviceCard() => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: alpenSoftBlue, borderRadius: BorderRadius.circular(18)), child: const Row(children: [CircleAvatar(radius: 25, backgroundColor: Colors.white, child: Icon(Icons.assignment_rounded, color: alpenBlue)), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pelaporan Kematian', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), SizedBox(height: 3), Text('Ajukan laporan secara mudah dan aman', style: TextStyle(fontSize: 12, color: Color(0xFF667085)))])), Icon(Icons.arrow_forward_ios_rounded, color: alpenBlue, size: 18)]));
Widget _newsCard(String title) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEAECF0)), borderRadius: BorderRadius.circular(16)), child: Row(children: [Container(width: 66, height: 66, decoration: BoxDecoration(color: alpenMint, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.campaign_outlined, color: alpenGreen)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Sosialisasi', style: TextStyle(fontSize: 12, color: alpenBlue, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 5), const Text('02 Juni 2026', style: TextStyle(fontSize: 12, color: Color(0xFF98A2B3)))]))])); }
class _ApplicationTab extends StatelessWidget { const _ApplicationTab({required this.user}); final Map<String, dynamic> user; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.description_outlined, size: 60, color: alpenBlue), const SizedBox(height: 12), const Text('Pengajuan Layanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 20), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => pushPage(context, DeathReportPage(user: user)), child: const Text('Pelaporan Kematian')))]))); }
class _ProfileTab extends StatelessWidget { const _ProfileTab({required this.user}); final Map<String, dynamic> user; @override Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Profil Anda', style: TextStyle(color: alpenBlue, fontSize: 21)), TextButton(onPressed: () => _logout(context), child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)))]), const Text('Data Pribadi', style: TextStyle(color: alpenGreen, fontSize: 16)), const SizedBox(height: 10), _dataCard([['Nama', user['name']?.toString() ?? '-'], ['Email', user['email']?.toString() ?? '-'], ['Nomor Handphone', '—'], ['Alamat Lengkap', '—'], ['Nama Bank', '—']]), const SizedBox(height: 16), const Text('Data Istri/Suami Pensiunan', style: TextStyle(color: alpenGreen, fontSize: 16)), const SizedBox(height: 10), _dataCard(const [['Nama Istri/Suami', '—'], ['Tanggal Lahir', '—'], ['Status', '—']]), const SizedBox(height: 16), const Text('Dokumen', style: TextStyle(color: alpenGreen, fontSize: 16)), const SizedBox(height: 8), const _DocumentRow('Kartu Tanda Penduduk (KTP)', 'KTP.pdf'), const _DocumentRow('Kartu Keluarga', 'KK.pdf')]));
Widget _dataCard(List<List<String>> items) => Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: alpenBlue), borderRadius: BorderRadius.circular(10)), child: Column(children: items.map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text('•  ${item[0]}')), Text(item[1], style: const TextStyle(color: alpenBlue))]))).toList()));
Future<void> _logout(BuildContext context) => showDialog<void>(context: context, builder: (_) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), icon: const CircleAvatar(radius: 34, backgroundColor: Color(0xFFFFDDDD), child: Icon(Icons.logout, color: Colors.red, size: 35)), title: const Text('Apakah Anda yakin Ingin Keluar?', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)))), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { await SessionService.clear(); if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false); }, child: const Text('Log Out')))])); }
class _DocumentRow extends StatelessWidget { const _DocumentRow(this.label, this.value); final String label, value; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(14), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD0D5DD)), borderRadius: BorderRadius.circular(14)), child: Row(children: [Text(value, style: const TextStyle(color: Colors.red)), const Spacer(), const Icon(Icons.visibility, color: alpenBlue)]))]); }
