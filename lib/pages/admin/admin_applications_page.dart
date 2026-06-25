import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../services/mongo_service.dart';
import 'admin_application_detail_page.dart';

class AdminApplicationsPage extends StatefulWidget {
  const AdminApplicationsPage({super.key});
  @override
  State<AdminApplicationsPage> createState() => _AdminApplicationsPageState();
}

class _AdminApplicationsPageState extends State<AdminApplicationsPage> {
  final search = TextEditingController();
  late Future<List<Map<String, dynamic>>> reports;
  String filter = 'Semua';
  @override void initState() { super.initState(); reports = MongoService.instance.findAllDeathReports(); }
  @override void dispose() { search.dispose(); super.dispose(); }
  Future<void> refresh() async => setState(() => reports = MongoService.instance.findAllDeathReports());
  @override Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: reports,
    builder: (context, snapshot) {
      final term = search.text.trim().toLowerCase();
      final items = (snapshot.data ?? []).where((report) {
        final status = report['status']?.toString() ?? 'Pengajuan Baru';
        final haystack = '${report['_id']} ${report['reporterName']} ${report['deceasedName']} ${report['identityNumber']}'.toLowerCase();
        final matchText = term.isEmpty || haystack.contains(term);
        final matchStatus = filter == 'Semua' || (filter == 'Menunggu Verifikasi' && (status == 'Pengajuan Baru' || status == 'Sedang Ditinjau')) || status == filter;
        return matchText && matchStatus;
      }).toList();
      return RefreshIndicator(onRefresh: refresh, child: ListView(padding: const EdgeInsets.fromLTRB(16, 32, 16, 24), children: [
        const Text('Pengajuan Layanan', style: TextStyle(color: alpenGreen, fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
        TextField(controller: search, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'Cari nama, NIP/NIK, atau nomor pengajuan', prefixIcon: const Icon(Icons.search, color: alpenGreen), fillColor: const Color(0xFFF0F0F0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none))), const SizedBox(height: 12),
        Wrap(spacing: 8, children: ['Semua', 'Menunggu Verifikasi', 'Ditolak', 'Disetujui'].map((item) => ChoiceChip(label: Text(item), selected: filter == item, selectedColor: alpenBlue, labelStyle: TextStyle(color: filter == item ? Colors.white : Colors.black), onSelected: (_) => setState(() => filter = item))).toList()), const SizedBox(height: 12),
        if (snapshot.connectionState == ConnectionState.waiting) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())) else if (snapshot.hasError) const Text('Data pengajuan tidak dapat dimuat.') else if (items.isEmpty) const Padding(padding: EdgeInsets.only(top: 50), child: Center(child: Text('Tidak ada pengajuan yang sesuai.'))) else ...items.map((report) => _ApplicationCard(report: report)),
      ]));
    },
  );
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.report});
  final Map<String, dynamic> report;
  @override Widget build(BuildContext context) {
    final status = report['status']?.toString() ?? 'Pengajuan Baru';
    final color = status == 'Ditolak' ? Colors.red : status == 'Disetujui' ? alpenGreen : Colors.deepOrange;
    return Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD0D5DD)), borderRadius: BorderRadius.circular(10)), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Chip(label: Text('#${report['_id']?.toString().substring(0, 8) ?? '-'}')), Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700))]),
      Row(children: [const CircleAvatar(backgroundColor: alpenSoftBlue, child: Icon(Icons.person, color: alpenBlue)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Pelapor', style: TextStyle(color: Colors.grey)), Text('${report['reporterName'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Text('Almarhum', style: TextStyle(color: Colors.grey)), Text('${report['deceasedName'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700))])), ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminApplicationDetailPage(report: report))), child: const Text('Lihat Detail'))]),
    ]));
  }
}
