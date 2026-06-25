import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;

import '../core/app_theme.dart';
import '../core/navigation.dart';
import '../services/mongo_service.dart';
import '../widgets/app_widgets.dart';
import 'user_home_page.dart';

class FamilyDataPage extends StatefulWidget {
  const FamilyDataPage({super.key, required this.user});
  final Map<String, dynamic> user;
  @override
  State<FamilyDataPage> createState() => _FamilyDataPageState();
}

class _FamilyDataPageState extends State<FamilyDataPage> {
  final spouse = TextEditingController(),
      spouseBirth = TextEditingController(),
      child = TextEditingController(),
      childBirth = TextEditingController();
  final children = <Map<String, String>>[];
  String spouseStatus = 'Hidup';
  bool waiting = false;
  PlatformFile? ktpFile;
  PlatformFile? kkFile;
  Future<void> _save() async {
    if ([spouse, spouseBirth].any((item) => item.text.trim().isEmpty) ||
        ktpFile == null ||
        kkFile == null)
      return showMessage(
        context,
        'Lengkapi data keluarga dan unggah dokumen KTP serta KK.',
      );
    if (child.text.trim().isNotEmpty || childBirth.text.trim().isNotEmpty) {
      return showMessage(
        context,
        'Tekan "Tambah Data Anak" terlebih dahulu untuk menyimpan data anak yang telah diisi.',
      );
    }
    setState(() => waiting = true);
    try {
      await MongoService.instance.updateFamily(widget.user['_id'] as ObjectId, {
        'spouseName': spouse.text.trim(),
        'spouseBirthDate': spouseBirth.text.trim(),
        'spouseStatus': spouseStatus,
        'children': children,
        'ktpDocument': _fileMetadata(ktpFile!),
        'kkDocument': _fileMetadata(kkFile!),
      });
      if (!mounted) return;
      await successDialog(
        context,
        'Profil Berhasil Disimpan',
        'Data profil Anda telah berhasil disimpan dan siap digunakan untuk layanan pada aplikasi ALPEN.',
        actionLabel: 'Masuk ke Beranda',
      );
      if (mounted)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => UserHomePage(user: widget.user)),
          (_) => false,
        );
    } catch (error) {
      if (mounted) showMessage(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => waiting = false);
    }
  }

  void _addChild() {
    if (child.text.trim().isEmpty || childBirth.text.trim().isEmpty)
      return showMessage(
        context,
        'Isi nama dan tanggal lahir anak terlebih dahulu.',
      );
    setState(() {
      children.add({
        'name': child.text.trim(),
        'birthDate': childBirth.text.trim(),
      });
      child.clear();
      childBirth.clear();
    });
  }

  Future<void> _pickDocument(bool isKtp) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    setState(() {
      if (isKtp) {
        ktpFile = result.files.single;
      } else {
        kkFile = result.files.single;
      }
    });
  }

  Map<String, dynamic> _fileMetadata(PlatformFile file) => {
    'name': file.name,
    'size': file.size,
    'path': file.path,
    'extension': file.extension,
  };
  @override
  void dispose() {
    for (final item in [spouse, spouseBirth, child, childBirth]) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormScaffold(
    title: 'Lengkapi Data Keluarga',
    subtitle: '',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Data Istri/Suami'),
        AppField(
          label: 'Nama Istri/Suami',
          controller: spouse,
          hint: 'Masukkan Nama Istri/Suami',
        ),
        DateField(label: 'Tanggal Lahir', controller: spouseBirth),
        _FamilyChoice(
          value: spouseStatus,
          onChanged: (value) => setState(() => spouseStatus = value),
        ),
        const _SectionTitle('Data Anak Pensiunan'),
        AppField(
          label: 'Nama Anak ${children.length + 1}',
          controller: child,
          hint: 'Masukkan Nama Anak Anda',
        ),
        DateField(label: 'Tanggal Lahir', controller: childBirth),
        if (children.isNotEmpty)
          ...children.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Chip(
                label: Text('${item['name']} — ${item['birthDate']}'),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () => setState(() => children.remove(item)),
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addChild,
            icon: const Icon(Icons.add_circle, size: 18),
            label: const Text('Tambah Data Anak'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: alpenGreen,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const _SectionTitle('Dokumen'),
        _DocumentUpload(
          label: 'Kartu Tanda Penduduk (KTP)',
          file: ktpFile,
          onPick: () => _pickDocument(true),
        ),
        _DocumentUpload(
          label: 'Kartu Keluarga (KK)',
          file: kkFile,
          onPick: () => _pickDocument(false),
        ),
        const SizedBox(height: 10),
        PrimaryButton(label: 'Selesai', waiting: waiting, onTap: _save),
      ],
    ),
  );
}

class _FamilyChoice extends StatelessWidget {
  const _FamilyChoice({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        Container(
          width: 38,
          height: 2,
          margin: const EdgeInsets.only(top: 5, bottom: 6),
          color: alpenBlue,
        ),
        Row(
          children: ['Hidup', 'Meninggal']
              .map(
                (option) => SizedBox(
                  width: 110,
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: alpenBlue,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: option,
                    groupValue: value,
                    onChanged: (item) {
                      if (item != null) onChanged(item);
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: const TextStyle(
        color: alpenGreen,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _DocumentUpload extends StatelessWidget {
  const _DocumentUpload({
    required this.label,
    required this.file,
    required this.onPick,
  });
  final String label;
  final PlatformFile? file;
  final VoidCallback onPick;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        Container(
          width: 38,
          height: 2,
          margin: const EdgeInsets.only(top: 5, bottom: 11),
          color: alpenBlue,
        ),
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
                const Icon(Icons.upload_file_outlined, color: alpenGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file == null
                        ? 'Pilih gambar JPG/JPEG'
                        : '${file!.name} (${(file!.size / 1024).ceil()} KB)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: file == null
                          ? const Color(0xFF767676)
                          : alpenGreen,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: alpenBlue),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
