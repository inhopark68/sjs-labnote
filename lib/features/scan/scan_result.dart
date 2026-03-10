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

class ParsedScanFields {
  final String? lotNumber;
  final String? catalogNumber;
  final String? company;
  final List<String> companyCandidates;

  const ParsedScanFields({
    this.lotNumber,
    this.catalogNumber,
    this.company,
    this.companyCandidates = const [],
  });

  bool get hasAny =>
      (lotNumber?.isNotEmpty ?? false) ||
      (catalogNumber?.isNotEmpty ?? false) ||
      (company?.isNotEmpty ?? false) ||
      companyCandidates.isNotEmpty;
}

class ScanFromImageResult {
  final List<ScanCodeItem> codes;
  final String text;
  final ParsedScanFields parsed;

  const ScanFromImageResult({
    required this.codes,
    required this.text,
    required this.parsed,
  });

  bool get hasCodes => codes.isNotEmpty;
  bool get hasText => text.trim().isNotEmpty;
  bool get isEmpty => !hasCodes && !hasText && !parsed.hasAny;
}