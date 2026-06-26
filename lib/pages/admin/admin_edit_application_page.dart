import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../../core/app_theme.dart';
import '../../core/navigation.dart';
import '../../core/report_number.dart';
import '../../services/mongo_service.dart';
import '../../widgets/app_widgets.dart';

class AdminEditApplicationPage extends StatefulWidget {
  const AdminEditApplicationPage({super.key, required this.report});

  final Map<String, dynamic> report;

  @override
  State<AdminEditApplicationPage> createState() => _AdminEditApplicationPageState();
}

class _AdminEditApplicationPageState extends State<AdminEditApplicationPage> {
  final reporter = TextEditingController();
  final reporterBirth = TextEditingController();
  final phone = TextEditingController();
  final deceased = TextEditingController();
  final deceasedBirth = TextEditingController();
  final identity = TextEditingController();
  final deathDate = TextEditingController();

  String gender = 'Pria';
  String relation = 'Suami';
  String status = 'Pengajuan Baru';
  bool waiting = false;

  @override
  void initState() {
    super.initState();
    final report = widget.report;
    reporter.text = report['reporterName']?.toString() ?? '';
    reporterBirth.text = report['reporterBirth']?.toString() ?? '';
    phone.text = report['phone']?.toString() ?? '';
    deceased.text = report['deceasedName']?.toString() ?? '';
    deceasedBirth.text = report['deceasedBirth']?.toString() ?? '';
    identity.text = report['identityNumber']?.toString() ?? '';
    deathDate.text = report['deathDate']?.toString() ?? '';
    gender = report['reporterGender']?.toString() ?? 'Pria';
    relation = report['relation']?.toString() ?? 'Suami';
    status = report['status']?.toString() ?? 'Pengajuan Baru';
  }

  Future<void> save() async {
    final empty = [reporter, reporterBirth, phone, deceased, deceasedBirth, identity, deathDate].any((item) => item.text.trim().isEmpty);
    if (empty) {
      showMessage(context, 'Lengkapi semua data pengajuan.');
      return;
    }

    setState(() => waiting = true);
    try {
      await MongoService.instance.updateDeathReportData(widget.report['_id'] as ObjectId, {
        'reporterName': reporter.text.trim(),
        'reporterBirth': reporterBirth.text.trim(),
        'reporterGender': gender,
        'phone': phone.text.trim(),
        'deceasedName': deceased.text.trim(),
        'deceasedBirth': deceasedBirth.text.trim(),
        'identityNumber': identity.text.trim(),
        'relation': relation,
        'deathDate': deathDate.text.trim(),
        'status': status,
      });
      if (!mounted) return;
      await successDialog(
        context,
        'Pengajuan Berhasil Diperbarui',
        'Data pengajuan ${reportNumberOf(widget.report)} telah berhasil disimpan.',
        actionLabel: 'Selesai',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => waiting = false);
    }
  }

  @override
  void dispose() {
    for (final item in [reporter, reporterBirth, phone, deceased, deceasedBirth, identity, deathDate]) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormScaffold(
        title: 'Edit Pengajuan',
        subtitle: reportNumberOf(widget.report),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Data Pelapor'),
            AppField(label: 'Nama Pelapor', controller: reporter, hint: 'Masukkan Nama Pelapor'),
            DateField(label: 'Tanggal Lahir Pelapor', controller: reporterBirth),
            _OptionField(label: 'Jenis Kelamin', value: gender, items: const ['Pria', 'Wanita'], onChanged: (value) => setState(() => gender = value)),
            AppField(label: 'Nomor Handphone', controller: phone, hint: 'Masukkan Nomor Handphone', keyboard: TextInputType.phone),
            const _SectionTitle('Data Almarhum'),
            AppField(label: 'Nama Almarhum', controller: deceased, hint: 'Masukkan Nama Almarhum'),
            DateField(label: 'Tanggal Lahir Almarhum', controller: deceasedBirth),
            AppField(label: 'NIP/NIK', controller: identity, hint: 'Masukkan NIP/NIK'),
            _OptionField(label: 'Hubungan Keluarga', value: relation, items: const ['Suami', 'Istri', 'Anak'], onChanged: (value) => setState(() => relation = value)),
            DateField(label: 'Tanggal Meninggal', controller: deathDate),
            _OptionField(
              label: 'Status Pengajuan',
              value: status,
              items: const ['Pengajuan Baru', 'Sedang Ditinjau', 'Disetujui', 'Ditolak', 'Diajukan Kembali', 'Menunggu Verifikasi'],
              onChanged: (value) => setState(() => status = value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Batalkan'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: PrimaryButton(label: 'Simpan', waiting: waiting, onTap: save)),
              ],
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(color: alpenGreen, fontSize: 18, fontWeight: FontWeight.w800)),
      );
}

class _OptionField extends StatelessWidget {
  const _OptionField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF282828), fontSize: 16)),
            Container(width: 38, height: 2, margin: const EdgeInsets.only(top: 5, bottom: 11), color: alpenBlue),
            DropdownButtonFormField<String>(
              value: items.contains(value) ? value : items.first,
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: (choice) {
                if (choice != null) onChanged(choice);
              },
            ),
          ],
        ),
      );
}
