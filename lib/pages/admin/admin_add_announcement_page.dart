import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/navigation.dart';
import '../../services/mongo_service.dart';
import '../../widgets/app_widgets.dart';

class AdminAddAnnouncementPage extends StatefulWidget { const AdminAddAnnouncementPage({super.key}); @override State<AdminAddAnnouncementPage> createState() => _AdminAddAnnouncementPageState(); }
class _AdminAddAnnouncementPageState extends State<AdminAddAnnouncementPage> {
  final title = TextEditingController(), start = TextEditingController(), end = TextEditingController(), body = TextEditingController();
  PlatformFile? thumbnail;
  bool waiting = false;
  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png']);
    if (result != null && result.files.isNotEmpty && mounted) setState(() => thumbnail = result.files.single);
  }
  Future<void> publish() async {
    if ([title, start, end, body].any((item) => item.text.trim().isEmpty) || thumbnail == null) return showMessage(context, 'Lengkapi data pengumuman dan upload thumbnail.');
    setState(() => waiting = true);
    try {
      await MongoService.instance.publishAnnouncement({'title': title.text.trim(), 'publishDate': start.text, 'endDate': end.text, 'thumbnail': {'name': thumbnail!.name, 'path': thumbnail!.path, 'size': thumbnail!.size, 'extension': thumbnail!.extension}, 'body': body.text.trim()});
      if (!mounted) return;
      await successDialog(context, 'Pengumuman Berhasil Dipublikasikan', 'Pengumuman telah berhasil diterbitkan dan tersedia untuk pengguna.', actionLabel: 'Selesai');
      if (mounted) Navigator.pop(context);
    } catch (error) { if (mounted) showMessage(context, friendlyError(error)); }
    finally { if (mounted) setState(() => waiting = false); }
  }
  @override void dispose() { for (final item in [title, start, end, body]) { item.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) => FormScaffold(title: 'Tambah Pengumuman', subtitle: '', child: Column(children: [
    AppField(label: 'Judul Pengumuman', controller: title, hint: 'contoh : Pengumuman A'), DateField(label: 'Tanggal Publish', controller: start), DateField(label: 'Tanggal Berakhir', controller: end), _ThumbnailUpload(file: thumbnail, onPick: _pickThumbnail), AppField(label: 'Isi Pengumuman', controller: body, hint: 'Tulis isi pengumuman...', maxLines: 7), Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batalkan'))), const SizedBox(width: 8), Expanded(child: PrimaryButton(label: 'Publish', waiting: waiting, onTap: publish))]),
  ]));
}
class _ThumbnailUpload extends StatelessWidget { const _ThumbnailUpload({required this.file, required this.onPick}); final PlatformFile? file; final VoidCallback onPick; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Upload Thumbnail', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)), Container(width: 38, height: 2, margin: const EdgeInsets.only(top: 5, bottom: 11), color: alpenBlue), InkWell(onTap: onPick, borderRadius: BorderRadius.circular(14), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD0D5DD)), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.upload, color: alpenGreen), const SizedBox(width: 10), Expanded(child: Text(file == null ? 'Pilih gambar JPG/JPEG/PNG' : file!.name, overflow: TextOverflow.ellipsis)), const Icon(Icons.image_outlined, color: alpenBlue)]))) ])); }
