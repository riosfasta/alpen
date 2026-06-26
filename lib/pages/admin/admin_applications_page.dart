import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../../core/app_theme.dart';
import '../../core/report_number.dart';
import '../../services/mongo_service.dart';
import 'admin_application_detail_page.dart';
import 'admin_edit_application_page.dart';

class AdminApplicationsPage extends StatefulWidget {
  const AdminApplicationsPage({super.key});

  @override
  State<AdminApplicationsPage> createState() => _AdminApplicationsPageState();
}

class _AdminApplicationsPageState extends State<AdminApplicationsPage> {
  final search = TextEditingController();
  final List<Map<String, dynamic>> reports = [];
  String filter = 'Semua';
  bool loading = true;
  String? errorText;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
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

  Future<void> _editReport(Map<String, dynamic> report) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminEditApplicationPage(report: report)),
    );
    if (changed == true) await refresh();
  }

  Future<void> _deleteReport(Map<String, dynamic> report) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengajuan?'),
        content: Text('Pengajuan ${reportNumberOf(report)} akan dihapus permanen. Apakah Anda yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final id = report['_id'] as ObjectId;
      await MongoService.instance.deleteDeathReport(id);
      if (!mounted) return;
      setState(() => reports.removeWhere((item) => item['_id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan berhasil dihapus.')));
      await refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error is StateError ? error.message : 'Pengajuan gagal dihapus. Periksa koneksi database.')),
      );
      await refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final term = search.text.trim().toLowerCase();
    final items = reports.where((report) {
      final status = report['status']?.toString() ?? 'Pengajuan Baru';
      final haystack = '${reportNumberOf(report)} ${report['_id']} ${report['reporterName']} ${report['deceasedName']} ${report['identityNumber']}'.toLowerCase();
      final matchText = term.isEmpty || haystack.contains(term);
      final matchStatus = filter == 'Semua' || (filter == 'Menunggu Verifikasi' && (status == 'Pengajuan Baru' || status == 'Sedang Ditinjau')) || status == filter;
      return matchText && matchStatus;
    }).toList();

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
        children: [
          const Text('Pengajuan Layanan', style: TextStyle(color: alpenGreen, fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari nama, NIP/NIK, atau nomor pengajuan',
              prefixIcon: const Icon(Icons.search, color: alpenGreen),
              fillColor: const Color(0xFFF0F0F0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Semua', 'Menunggu Verifikasi', 'Ditolak', 'Disetujui']
                .map(
                  (item) => ChoiceChip(
                    label: Text(item),
                    selected: filter == item,
                    selectedColor: alpenBlue,
                    labelStyle: TextStyle(color: filter == item ? Colors.white : Colors.black),
                    onSelected: (_) => setState(() => filter = item),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
          else if (errorText != null)
            Text(errorText!)
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 50),
              child: Center(child: Text('Tidak ada pengajuan yang sesuai.')),
            )
          else
            ...items.map(
              (report) => _ApplicationCard(
                report: report,
                onEdit: () => _editReport(report),
                onDelete: () => _deleteReport(report),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.report,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> report;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = report['status']?.toString() ?? 'Pengajuan Baru';
    final color = status == 'Ditolak' ? Colors.red : status == 'Disetujui' ? alpenGreen : Colors.deepOrange;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD0D5DD)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(label: Text(reportNumberOf(report))),
              Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(backgroundColor: alpenSoftBlue, child: Icon(Icons.person, color: alpenBlue)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pelapor', style: TextStyle(color: Colors.grey)),
                    Text('${report['reporterName'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('Almarhum', style: TextStyle(color: Colors.grey)),
                    Text('${report['deceasedName'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _dateText(report['createdAt']),
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminApplicationDetailPage(report: report)),
                    ),
                    child: const Text('Lihat Detail'),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, color: alpenBlue),
                      ),
                      IconButton(
                        tooltip: 'Hapus',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ],
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
}
