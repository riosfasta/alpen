import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../core/app_theme.dart';
import '../pages/admin/admin_add_announcement_page.dart';
import '../pages/news_detail_page.dart';
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

  @override
  void initState() {
    super.initState();
    future = MongoService.instance.findAnnouncements();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void refresh() => setState(() {
        visible = 5;
        future = MongoService.instance.findAnnouncements();
      });

  Future<void> _addAnnouncement() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminAddAnnouncementPage()),
    );
    if (changed == true) refresh();
  }

  Future<void> _editAnnouncement(Map<String, dynamic> item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminAddAnnouncementPage(announcement: item)),
    );
    if (changed == true) refresh();
  }

  Future<void> _deleteAnnouncement(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengumuman?'),
        content: Text('Pengumuman "${item['title'] ?? '-'}" akan dihapus permanen. Apakah Anda yakin?'),
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
      await MongoService.instance.deleteAnnouncement(item['_id'] as ObjectId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengumuman berhasil dihapus.')));
      refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengumuman gagal dihapus. Periksa koneksi database.')),
      );
    }
  }

  Future<void> _openAnnouncement(Map<String, dynamic> item) async {
    if (widget.adminMode) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsDetailPage(announcement: Map<String, dynamic>.from(item))),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          final items = (snapshot.data ?? []).where((item) {
            final term = search.text.trim().toLowerCase();
            return term.isEmpty || '${item['title']} ${item['body']}'.toLowerCase().contains(term);
          }).toList();
          final shown = items.take(visible).toList();

          return RefreshIndicator(
            onRefresh: () async {
              refresh();
              final current = future;
              if (current != null) await current;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              primary: false,
              children: [
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() => visible = 5),
                  decoration: InputDecoration(
                    hintText: widget.adminMode ? 'Cari pengumuman' : 'Cari informasi & pengumuman',
                    prefixIcon: const Icon(Icons.search, color: alpenGreen),
                    fillColor: const Color(0xFFF0F0F0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  ),
                ),
                if (widget.adminMode) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onAdd ?? _addAnnouncement,
                      icon: const Icon(Icons.add),
                      label: const Text('Buat Pengumuman'),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (items.isEmpty)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Belum ada pengumuman.')))
                else
                  ...shown.map(
                    (item) => _AnnouncementItem(
                      item: item,
                      adminMode: widget.adminMode,
                      onOpen: () => _openAnnouncement(item),
                      onEdit: () => _editAnnouncement(item),
                      onDelete: () => _deleteAnnouncement(item),
                    ),
                  ),
                if (items.length > visible)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => visible += 5),
                      icon: const Icon(Icons.expand_more),
                      label: Text(widget.adminMode ? 'Muat Selanjutnya' : 'Tampilkan Selengkapnya'),
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

class _AnnouncementItem extends StatelessWidget {
  const _AnnouncementItem({
    required this.item,
    required this.adminMode,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final bool adminMode;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD0D5DD)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Thumbnail(metadata: item['thumbnail']),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminMode ? '● ${item['status'] ?? 'Aktif'}' : 'Informasi',
                  style: const TextStyle(color: alpenGreen, fontSize: 12),
                ),
                Text(
                  '${item['title'] ?? '-'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${item['body'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Colors.grey, size: 19),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item['publishDate'] ?? '-'}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    if (!adminMode) const Icon(Icons.chevron_right_rounded, color: alpenBlue, size: 22),
                  ],
                ),
                if (adminMode)
                  Row(
                    children: [
                      TextButton(onPressed: onEdit, child: const Text('Edit')),
                      IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, color: Colors.red)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (adminMode) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: card,
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.metadata});

  final dynamic metadata;

  @override
  Widget build(BuildContext context) {
    final data = metadata is Map ? Map<String, dynamic>.from(metadata) : <String, dynamic>{};
    final path = data['path']?.toString();
    final exists = path != null && File(path).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: exists
          ? Image.file(File(path), width: 88, height: 88, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
          : _fallback(),
    );
  }

  Widget _fallback() => Container(
        width: 88,
        height: 88,
        color: alpenSoftBlue,
        child: const Icon(Icons.campaign_outlined, color: alpenBlue),
      );
}
