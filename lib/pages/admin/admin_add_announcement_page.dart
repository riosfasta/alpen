import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../../core/app_theme.dart';
import '../../core/navigation.dart';
import '../../services/mongo_service.dart';
import '../../widgets/app_widgets.dart';

class AdminAddAnnouncementPage extends StatefulWidget {
  const AdminAddAnnouncementPage({super.key, this.announcement});

  final Map<String, dynamic>? announcement;

  @override
  State<AdminAddAnnouncementPage> createState() => _AdminAddAnnouncementPageState();
}

class _AdminAddAnnouncementPageState extends State<AdminAddAnnouncementPage> {
  final title = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();
  final body = TextEditingController();

  PlatformFile? thumbnail;
  Map<String, dynamic>? existingThumbnail;
  bool waiting = false;

  bool get isEdit => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    final data = widget.announcement;
    if (data != null) {
      title.text = data['title']?.toString() ?? '';
      start.text = data['publishDate']?.toString() ?? '';
      end.text = data['endDate']?.toString() ?? '';
      body.text = data['body']?.toString() ?? '';
      existingThumbnail = data['thumbnail'] is Map ? Map<String, dynamic>.from(data['thumbnail']) : null;
    }
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() => thumbnail = result.files.single);
    }
  }

  Future<void> save() async {
    final thumbnailMetadata = thumbnail == null
        ? existingThumbnail
        : {
            'name': thumbnail!.name,
            'path': thumbnail!.path,
            'size': thumbnail!.size,
            'extension': thumbnail!.extension,
          };

    if ([title, start, end, body].any((item) => item.text.trim().isEmpty) || thumbnailMetadata == null) {
      showMessage(context, 'Lengkapi data pengumuman dan upload thumbnail.');
      return;
    }

    setState(() => waiting = true);
    try {
      final values = {
        'title': title.text.trim(),
        'publishDate': start.text,
        'endDate': end.text,
        'thumbnail': thumbnailMetadata,
        'body': body.text.trim(),
      };

      if (isEdit) {
        await MongoService.instance.updateAnnouncement(widget.announcement!['_id'] as ObjectId, values);
      } else {
        await MongoService.instance.publishAnnouncement(values);
      }

      if (!mounted) return;
      await successDialog(
        context,
        isEdit ? 'Pengumuman Berhasil Diperbarui' : 'Pengumuman Berhasil Dipublikasikan',
        isEdit ? 'Perubahan pengumuman telah berhasil disimpan.' : 'Pengumuman telah berhasil diterbitkan dan tersedia untuk pengguna.',
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
    for (final item in [title, start, end, body]) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormScaffold(
        title: isEdit ? 'Edit Pengumuman' : 'Tambah Pengumuman',
        subtitle: '',
        child: Column(
          children: [
            AppField(label: 'Judul Pengumuman', controller: title, hint: 'contoh : Pengumuman A'),
            DateField(label: 'Tanggal Publish', controller: start),
            DateField(label: 'Tanggal Berakhir', controller: end),
            _ThumbnailUpload(
              file: thumbnail,
              existingName: existingThumbnail?['name']?.toString(),
              onPick: _pickThumbnail,
            ),
            AppField(label: 'Isi Pengumuman', controller: body, hint: 'Tulis isi pengumuman...', maxLines: 7),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
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
                ),
                const SizedBox(width: 8),
                Expanded(child: PrimaryButton(label: isEdit ? 'Simpan' : 'Publish', waiting: waiting, onTap: save)),
              ],
            ),
          ],
        ),
      );
}

class _ThumbnailUpload extends StatelessWidget {
  const _ThumbnailUpload({
    required this.file,
    required this.existingName,
    required this.onPick,
  });

  final PlatformFile? file;
  final String? existingName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final label = file?.name ?? existingName ?? 'Pilih gambar JPG/JPEG/PNG';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload Thumbnail', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
                  const Icon(Icons.upload, color: alpenGreen),
                  const SizedBox(width: 10),
                  Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.image_outlined, color: alpenBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
