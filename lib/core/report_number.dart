String reportNumberOf(Map<String, dynamic> report) {
  final letterNumber = report['letterNumber']?.toString().trim();
  if (letterNumber != null && letterNumber.isNotEmpty) return letterNumber;

  final id = report['_id']?.toString();
  if (id == null || id.isEmpty) return '-';
  return '#${id.length > 8 ? id.substring(0, 8) : id}';
}
