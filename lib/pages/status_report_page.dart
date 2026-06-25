import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Center, Size, State;

import '../core/app_theme.dart';
import '../services/mongo_service.dart';
import 'report_detail_page.dart';

class StatusReportPage extends StatefulWidget {
  const StatusReportPage({super.key, required this.user});
  final Map<String, dynamic> user;
  @override
  State<StatusReportPage> createState() => _StatusReportPageState();
}

class _StatusReportPageState extends State<StatusReportPage> {
  late Future<List<Map<String, dynamic>>> reports;
  @override
  void initState() {
    super.initState();
    reports = MongoService.instance.findDeathReports(widget.user['_id'] as ObjectId);
  }

  Future<void> refresh() async {
    setState(() => reports = MongoService.instance.findDeathReports(widget.user['_id'] as ObjectId));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: reports,
    builder: (context, snapshot) => RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 42, 16, 24),
        children: [
          const Text('Status Pengajuan', style: TextStyle(color: alpenGreen, fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Pantau status laporan Anda secara real-time', style: TextStyle(color: Color(0xFF667085))),
          const SizedBox(height: 20),
          if (snapshot.connectionState == ConnectionState.waiting)
            const Center(child: CircularProgressIndicator())
          else if (snapshot.hasError)
            const Text('Data pengajuan tidak dapat dimuat.')
          else if (snapshot.data!.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: Column(children: [Icon(Icons.description_outlined, size: 60, color: Colors.grey), SizedBox(height: 12), Text('Belum ada pengajuan laporan')])))
          else
            ...snapshot.data!.map((report) => _ReportCard(report: report)),
        ],
      ),
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final Map<String, dynamic> report;
  @override
  Widget build(BuildContext context) {
    final status = report['status']?.toString() ?? 'Pengajuan Baru';
    final color = status == 'Ditolak' ? Colors.red : status == 'Disetujui' ? alpenGreen : Colors.deepOrange;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailPage(report: report))),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD0D5DD)), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Chip(label: Text('#${report['_id']?.toString().substring(0, 8) ?? '-'}')), Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 8),
          Text('${report['deceasedName'] ?? 'Almarhum'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text('Pelapor: ${report['reporterName'] ?? '-'}'),
          Text('Tanggal laporan: ${report['createdAt']?.toString().split(' ').first ?? '-'}', style: const TextStyle(color: Colors.grey)),
          const Align(alignment: Alignment.centerRight, child: Text('Lihat detail ›', style: TextStyle(color: alpenBlue, fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }
}
