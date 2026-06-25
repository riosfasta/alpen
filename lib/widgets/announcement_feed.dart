import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/mongo_service.dart';

class AnnouncementFeed extends StatefulWidget {
  const AnnouncementFeed({super.key, this.adminMode = false, this.onAdd});
  final bool adminMode;
  final VoidCallback? onAdd;
  @override
  State<AnnouncementFeed> createState() => _AnnouncementFeedState();
}

class _AnnouncementFeedState extends State<AnnouncementFeed> {
  final search = TextEditingController();
  Future<List<Map<String, dynamic>>>? future;
  int visible = 5;
  @override void initState() { super.initState(); future = MongoService.instance.findAnnouncements(); }
  @override void dispose() { search.dispose(); super.dispose(); }
  void refresh() => setState(() { visible = 5; future = MongoService.instance.findAnnouncements(); });
  @override Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(future: future, builder: (context, snapshot) {
    final items = (snapshot.data ?? []).where((item) { final term = search.text.trim().toLowerCase(); return term.isEmpty || '${item['title']} ${item['body']}'.toLowerCase().contains(term); }).toList();
    final shown = items.take(visible).toList();
    return RefreshIndicator(onRefresh: () async { refresh(); final current = future; if (current != null) await current; }, child: ListView(physics: const AlwaysScrollableScrollPhysics(), shrinkWrap: true, primary: false, children: [
      TextField(controller: search, onChanged: (_) => setState(() => visible = 5), decoration: InputDecoration(hintText: widget.adminMode ? 'Cari pengumuman' : 'Cari informasi & pengumuman', prefixIcon: const Icon(Icons.search, color: alpenGreen), fillColor: const Color(0xFFF0F0F0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none))),
      if (widget.adminMode) ...[const SizedBox(height: 10), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: widget.onAdd, icon: const Icon(Icons.add), label: const Text('Buat Pengumuman')))],
      const SizedBox(height: 14),
      if (snapshot.connectionState == ConnectionState.waiting) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())) else if (items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Belum ada pengumuman.'))) else ...shown.map((item) => _AnnouncementItem(item: item, adminMode: widget.adminMode)),
      if (items.length > visible) Center(child: TextButton.icon(onPressed: () => setState(() => visible += 5), icon: const Icon(Icons.expand_more), label: Text(widget.adminMode ? 'Muat Selanjutnya' : 'Tampilkan Selengkapnya'))),
    ]));
  });
}
class _AnnouncementItem extends StatelessWidget {
  const _AnnouncementItem({required this.item, required this.adminMode});
  final Map<String, dynamic> item;
  final bool adminMode;
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(9), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD0D5DD)), borderRadius: BorderRadius.circular(12)), child: Row(children: [_Thumbnail(metadata: item['thumbnail']), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(adminMode ? '● ${item['status'] ?? 'Aktif'}' : 'Sosialisasi', style: const TextStyle(color: alpenGreen, fontSize: 12)), Text('${item['title'] ?? '-'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), Text('${item['body'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 5), Text('▣  ${item['publishDate'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 12)), if (adminMode) Row(children: [TextButton(onPressed: () {}, child: const Text('Edit')), IconButton(onPressed: () {}, icon: const Icon(Icons.delete, color: Colors.red))])]))]));
}
class _Thumbnail extends StatelessWidget { const _Thumbnail({required this.metadata}); final dynamic metadata; @override Widget build(BuildContext context) { final data = metadata is Map ? Map<String, dynamic>.from(metadata) : <String, dynamic>{}; final path = data['path']?.toString(); final exists = path != null && File(path).existsSync(); return ClipRRect(borderRadius: BorderRadius.circular(8), child: exists ? Image.file(File(path), width: 88, height: 88, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()) : _fallback()); } Widget _fallback() => Container(width: 88, height: 88, color: alpenSoftBlue, child: const Icon(Icons.campaign_outlined, color: alpenBlue)); }
