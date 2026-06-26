import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';

class UploadedDocumentPreview extends StatelessWidget {
  const UploadedDocumentPreview({
    super.key,
    required this.label,
    required this.metadata,
  });

  static const _downloadsChannel = MethodChannel('alpen/downloads');

  final String label;
  final dynamic metadata;

  @override
  Widget build(BuildContext context) {
    final data = metadata is Map ? Map<String, dynamic>.from(metadata) : <String, dynamic>{};
    final name = data['name']?.toString() ?? '-';
    final path = data['path']?.toString();
    final extension = (data['extension']?.toString() ?? name.split('.').last).toLowerCase();
    final contentBase64 = data['contentBase64']?.toString();
    final fileExists = path != null && File(path).existsSync();
    final bytes = _decodeBase64(contentBase64);
    final isImage = ['jpg', 'jpeg', 'png'].contains(extension);
    final canShowImage = isImage && (bytes != null || fileExists);
    final canDownload = bytes != null || fileExists;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD0D5DD)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: alpenGreen, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (canShowImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: bytes != null
                  ? Image.memory(
                      bytes,
                      width: double.infinity,
                      height: 230,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _FileInfo(name: name, extension: extension, available: canDownload),
                    )
                  : Image.file(
                      File(path!),
                      width: double.infinity,
                      height: 230,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _FileInfo(name: name, extension: extension, available: canDownload),
                    ),
            )
          else
            _FileInfo(name: name, extension: extension, available: canDownload),
          if (canDownload) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _download(context, data),
                icon: const Icon(Icons.download_rounded),
                label: Text(extension == 'pdf' ? 'Download PDF' : 'Download File'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Uint8List? _decodeBase64(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _download(BuildContext context, Map<String, dynamic> data) async {
    try {
      final name = data['name']?.toString() ?? 'dokumen.pdf';
      final extension = (data['extension']?.toString() ?? name.split('.').last).toLowerCase();
      final mimeType = data['mimeType']?.toString() ?? (extension == 'pdf' ? 'application/pdf' : 'image/$extension');
      final contentBase64 = data['contentBase64']?.toString();
      final path = data['path']?.toString();
      final bytes = _decodeBase64(contentBase64) ?? (path == null ? null : await File(path).readAsBytes());
      if (bytes == null) throw StateError('File tidak tersedia.');

      final savedName = await _downloadsChannel.invokeMethod<String>('saveToDownloads', {
        'fileName': name,
        'mimeType': mimeType,
        'bytes': bytes,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File tersimpan di folder Download: ${savedName ?? name}')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File tidak dapat didownload. Pastikan dokumen tersedia.')),
        );
      }
    }
  }
}

class _FileInfo extends StatelessWidget {
  const _FileInfo({
    required this.name,
    required this.extension,
    required this.available,
  });

  final String name;
  final String extension;
  final bool available;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alpenSoftBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(extension == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file, color: alpenBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    available ? 'File tersedia untuk didownload.' : 'File belum tersedia untuk didownload.',
                    style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
