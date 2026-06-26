import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/navigation.dart';
import '../services/mongo_service.dart';
import '../widgets/app_widgets.dart';

class DeathReportPage extends StatefulWidget {
  const DeathReportPage({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<DeathReportPage> createState() => _DeathReportPageState();
}

class _DeathReportPageState extends State<DeathReportPage> {
  final reporter = TextEditingController();
  final reporterBirth = TextEditingController();
  final phone = TextEditingController();
  final deceased = TextEditingController();
  final deceasedBirth = TextEditingController();
  final identity = TextEditingController();
  final deathDate = TextEditingController();

  String gender = 'Pria';
  String relation = 'Suami';
  bool waiting = false;
  PlatformFile? certificateFile;

  Future<void> _submit() async {
    final emptyRequiredField = [
      reporter,
      reporterBirth,
      phone,
      deceased,
      deceasedBirth,
      identity,
      deathDate,
    ].any((controller) => controller.text.trim().isEmpty);

    if (emptyRequiredField || certificateFile == null) {
      showMessage(context, 'Lengkapi semua data pengajuan dan unggah surat keterangan kematian.');
      return;
    }

    if (certificateFile!.size > 5 * 1024 * 1024) {
      showMessage(context, 'Ukuran file maksimal 5MB.');
      return;
    }

    setState(() => waiting = true);
    try {
      final certificate = await _fileMetadata(certificateFile!);
      await MongoService.instance.submitDeathReport({
        'userId': widget.user['_id'],
        'reporterName': reporter.text,
        'reporterBirth': reporterBirth.text,
        'reporterGender': gender,
        'phone': phone.text,
        'deceasedName': deceased.text,
        'deceasedBirth': deceasedBirth.text,
        'identityNumber': identity.text,
        'relation': relation,
        'deathDate': deathDate.text,
        'certificate': certificate,
      });
      if (!mounted) return;
      await successDialog(
        context,
        'Laporan Berhasil Dikirim',
        'Laporan Anda telah berhasil dikirim dan akan diproses dalam 1–5 hari kerja. Pantau progres melalui menu status.',
        actionLabel: 'Lihat Status',
        onAction: () => Navigator.pop(context),
      );
      if (mounted) Navigator.pop(context, 'status');
    } catch (error) {
      if (mounted) showMessage(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => waiting = false);
    }
  }

  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() => certificateFile = result.files.single);
    }
  }

  Future<Map<String, dynamic>> _fileMetadata(PlatformFile file) async {
    final bytes = file.bytes ?? (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) throw StateError('File tidak dapat dibaca.');
    final extension = file.extension?.toLowerCase() ?? file.name.split('.').last.toLowerCase();
    return {
      'name': file.name,
      'size': file.size,
      'path': file.path,
      'extension': extension,
      'mimeType': extension == 'pdf' ? 'application/pdf' : 'image/$extension',
      'contentBase64': base64Encode(bytes),
    };
  }

  @override
  void dispose() {
    for (final controller in [reporter, reporterBirth, phone, deceased, deceasedBirth, identity, deathDate]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormScaffold(
        title: 'Pelaporan Kematian',
        subtitle: '',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Heading('Data Pengajuan'),
            const _Subheading('Data Pelapor'),
            AppField(label: 'Nama Pelapor', controller: reporter, hint: 'Masukkan Nama Lengkap Pelapor'),
            DateField(label: 'Tanggal Lahir', controller: reporterBirth),
            _RadioGroup(
              label: 'Jenis Kelamin',
              value: gender,
              values: const ['Pria', 'Wanita'],
              onChanged: (value) => setState(() => gender = value),
            ),
            AppField(label: 'Nomor Handphone', controller: phone, hint: 'Masukkan No Handphone', keyboard: TextInputType.phone),
            const _Subheading('Data Almarhum'),
            AppField(label: 'Nama Almarhum', controller: deceased, hint: 'Masukkan Nama Lengkap Almarhum'),
            DateField(label: 'Tanggal Lahir', controller: deceasedBirth),
            AppField(label: 'Nomor Induk Pegawai / NIK', controller: identity, hint: 'Masukkan NIP/NIK'),
            _RadioGroup(
              label: 'Hubungan Keluarga',
              value: relation,
              values: const ['Suami', 'Istri', 'Anak'],
              onChanged: (value) => setState(() => relation = value),
            ),
            DateField(label: 'Tanggal Meninggal', controller: deathDate),
            const _Subheading('Dokumen'),
            _CertificateUpload(file: certificateFile, onPick: _pickCertificate),
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Text('Format PDF/JPG/PNG, maksimal 5MB', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
            ),
            PrimaryButton(label: 'Kirim Laporan', waiting: waiting, onTap: _submit),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
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
          ],
        ),
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(color: alpenGreen, fontSize: 20, fontWeight: FontWeight.w800)),
      );
}

class _Subheading extends StatelessWidget {
  const _Subheading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(color: alpenBlue, fontSize: 16, fontWeight: FontWeight.w700)),
      );
}

class _RadioGroup extends StatelessWidget {
  const _RadioGroup({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Container(width: 38, height: 2, margin: const EdgeInsets.only(top: 5, bottom: 6), color: alpenBlue),
            Wrap(
              children: values
                  .map(
                    (item) => SizedBox(
                      width: 120,
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(item),
                        value: item,
                        groupValue: value,
                        activeColor: alpenBlue,
                        onChanged: (choice) {
                          if (choice != null) onChanged(choice);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
}

class _CertificateUpload extends StatelessWidget {
  const _CertificateUpload({required this.file, required this.onPick});

  final PlatformFile? file;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Surat Keterangan Kematian', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Container(width: 38, height: 2, margin: const EdgeInsets.only(top: 5, bottom: 11), color: alpenBlue),
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD0D5DD)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file_outlined, color: alpenBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      file == null ? 'Pilih file surat keterangan kematian' : '${file!.name} (${(file!.size / 1024).ceil()} KB)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: alpenBlue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      );
}
