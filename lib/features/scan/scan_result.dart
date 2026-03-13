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

  bool get isEmpty =>
      (lotNumber == null || lotNumber!.trim().isEmpty) &&
      (catalogNumber == null || catalogNumber!.trim().isEmpty) &&
      (company == null || company!.trim().isEmpty) &&
      companyCandidates.isEmpty;
}

class ScanFromImageResult {
  final List<ScanCodeItem> codes;
  final String text;
  final ParsedScanFields parsed;

  const ScanFromImageResult({
    this.codes = const [],
    this.text = '',
    this.parsed = const ParsedScanFields(),
  });

  bool get isEmpty => codes.isEmpty && text.trim().isEmpty && parsed.isEmpty;
}