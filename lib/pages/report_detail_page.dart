import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/app_widgets.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key, required this.report});
  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final status = report['status']?.toString() ?? 'Pengajuan Baru';
    final rejected = status == 'Ditolak';
    return FormScaffold(title: 'Detail Pengajuan', subtitle: '', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Chip(label: Text('#${report['_id']?.toString().substring(0, 8) ?? '-'}')), _StatusChip(status: status)]),
      const SizedBox(height: 14),
      _DetailCard(title: 'Data Pelapor', rows: [['Nama Pelapor', '${report['reporterName'] ?? '-'}'], ['Tempat/Tanggal Lahir', '${report['reporterBirth'] ?? '-'}'], ['Jenis Kelamin', '${report['reporterGender'] ?? '-'}'], ['No Handphone', '${report['phone'] ?? '-'}']]),
      _DetailCard(title: 'Data Almarhum', rows: [['Nama Almarhum', '${report['deceasedName'] ?? '-'}'], ['Tempat/Tanggal Lahir', '${report['deceasedBirth'] ?? '-'}'], ['NIP/NIK', '${report['identityNumber'] ?? '-'}'], ['Hubungan Keluarga', '${report['relation'] ?? '-'}'], ['Tanggal Meninggal', '${report['deathDate'] ?? '-'}']]),
      _DetailCard(title: 'Dokumen', rows: [['Surat Keterangan Kematian', _documentName(report['certificate'])]]),
      const SizedBox(height: 18), const Text('Progres Pengajuan', style: TextStyle(color: alpenGreen, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 12),
      _TimelineStep(title: 'Pengajuan Baru', note: 'Laporan berhasil dikirim ke sistem.', active: true), _TimelineStep(title: 'Sedang Ditinjau', note: 'Menunggu pemeriksaan admin.', active: status == 'Sedang Ditinjau' || status == 'Disetujui' || rejected), _TimelineStep(title: rejected ? 'Pengajuan Ditolak' : status == 'Disetujui' ? 'Pengajuan Disetujui' : 'Menunggu Verifikasi', note: rejected ? 'Alasan: ${report['rejectionReason'] ?? 'Belum tersedia'}' : 'Status akan diperbarui oleh admin.', active: rejected || status == 'Disetujui'),
    ]));
  }
  String _documentName(dynamic value) => value is Map ? '${value['name'] ?? '-'}' : '-';
}
class _StatusChip extends StatelessWidget { const _StatusChip({required this.status}); final String status; @override Widget build(BuildContext context) { final color = status == 'Ditolak' ? Colors.red : status == 'Disetujui' ? alpenGreen : Colors.deepOrange; return Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700)); } }
class _DetailCard extends StatelessWidget { const _DetailCard({required this.title, required this.rows}); final String title; final List<List<String>> rows; @override Widget build(BuildContext context) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD0D5DD)), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: alpenGreen, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 8), ...rows.map((row) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(row[0], style: const TextStyle(color: Colors.grey))), Flexible(child: Text(row[1], textAlign: TextAlign.right))]))) ])); }
class _TimelineStep extends StatelessWidget { const _TimelineStep({required this.title, required this.note, required this.active}); final String title, note; final bool active; @override Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Column(children: [CircleAvatar(radius: 10, backgroundColor: active ? alpenBlue : Colors.white, child: Icon(active ? Icons.check : Icons.circle_outlined, color: active ? Colors.white : Colors.grey, size: 15)), Container(width: 1, height: 40, color: Colors.grey[300])]), const SizedBox(width: 12), Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: active ? alpenBlue : Colors.grey, fontSize: 16)), Text(note, style: const TextStyle(color: Color(0xFF667085)))])))]); }
