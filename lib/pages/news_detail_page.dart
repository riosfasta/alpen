import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({super.key, required this.announcement});

  final Map<String, dynamic> announcement;

  @override
  Widget build(BuildContext context) {
    final title = announcement['title']?.toString() ?? 'Detail Pengumuman';
    final body = announcement['body']?.toString() ?? '-';
    final publishDate = announcement['publishDate']?.toString() ?? '-';
    final endDate = announcement['endDate']?.toString();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        title: const Text('Detail Pengumuman'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailThumbnail(metadata: announcement['thumbnail']),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, height: 1.15),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: Colors.grey, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      endDate == null || endDate.isEmpty ? publishDate : '$publishDate - $endDate',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                body,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailThumbnail extends StatelessWidget {
  const _DetailThumbnail({required this.metadata});

  final dynamic metadata;

  @override
  Widget build(BuildContext context) {
    final data = metadata is Map ? Map<String, dynamic>.from(metadata) : <String, dynamic>{};
    final path = data['path']?.toString();
    final exists = path != null && File(path).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: exists
          ? Image.file(
              File(path),
              width: double.infinity,
              height: 210,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() => Container(
        width: double.infinity,
        height: 210,
        decoration: BoxDecoration(
          color: alpenSoftBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.campaign_outlined, color: alpenBlue, size: 72),
      );
}
