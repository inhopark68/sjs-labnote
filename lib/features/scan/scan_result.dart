class ScanCodeItem {
  final String? rawValue;
  final String? displayValue;
  final String format;

  const ScanCodeItem({
    required this.rawValue,
    required this.displayValue,
    required this.format,
  });
}

class ScanFromImageResult {
  final List<ScanCodeItem> codes;
  final String text;

  const ScanFromImageResult({
    required this.codes,
    required this.text,
  });

  bool get hasCodes => codes.isNotEmpty;
  bool get hasText => text.trim().isNotEmpty;
}