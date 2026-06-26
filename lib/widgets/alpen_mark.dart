import 'package:flutter/material.dart';

/// Logo resmi ALPEN. Teks adalah bagian dari artwork asli, bukan widget tambahan.
class AlpenMark extends StatelessWidget {
  const AlpenMark({super.key, this.large = false, this.onDark = false, this.width});
  final bool large;
  final bool onDark;
  final double? width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/logo_alpen.png',
    width: width ?? (large ? 180 : 142),
    fit: BoxFit.contain,
  );
}
