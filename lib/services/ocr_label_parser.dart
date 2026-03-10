class ParsedLabelInfo {
  final String? lotNumber;
  final String? catalogNumber;
  final String? company;
  final List<String> companyCandidates;

  const ParsedLabelInfo({
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

class OcrLabelParser {
  static final List<String> _knownCompanies = [
    'Thermo Fisher',
    'ThermoFisher',
    'Invitrogen',
    'Gibco',
    'Sigma',
    'Sigma-Aldrich',
    'Merck',
    'Bio-Rad',
    'Takara',
    'Promega',
    'Qiagen',
    'Abcam',
    'CST',
    'Cell Signaling Technology',
    'BD',
    'Corning',
    'Eppendorf',
    'Sartorius',
    'Roche',
    'GE Healthcare',
    'Cytiva',
    'Santa Cruz',
    'NEB',
    'New England Biolabs',
    'Bioneer',
    'Dyne Bio',
    'Elpis Biotech',
    'GenDEPOT',
  ];

  ParsedLabelInfo parse(String text) {
    final normalized = _normalize(text);

    final lot = _extractFirst(normalized, [
      RegExp(r'(?i)\b(?:lot|lot no|lot number|batch)\b[:\s\-]*([A-Z0-9\-_/\.]+)'),
      RegExp(r'(?i)\bL[/\s]?N\b[:\s\-]*([A-Z0-9\-_/\.]+)'),
    ]);

    final catalog = _extractFirst(normalized, [
      RegExp(r'(?i)\b(?:cat|cat no|catalog no|catalog number|product no|prod no|ref)\b[:\s#\-]*([A-Z0-9\-_/\.]+)'),
      RegExp(r'(?i)\bP[/\s]?N\b[:\s\-]*([A-Z0-9\-_/\.]+)'),
    ]);

    final companyCandidates = _extractCompanies(normalized);

    return ParsedLabelInfo(
      lotNumber: lot,
      catalogNumber: catalog,
      company: companyCandidates.isNotEmpty ? companyCandidates.first : null,
      companyCandidates: companyCandidates,
    );
  }

  String _normalize(String input) {
    return input
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();
  }

  String? _extractFirst(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = match.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  List<String> _extractCompanies(String text) {
    final found = <String>{};

    for (final company in _knownCompanies) {
      final pattern = RegExp(RegExp.escape(company), caseSensitive: false);
      if (pattern.hasMatch(text)) {
        found.add(company);
      }
    }

    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final line in lines.take(8)) {
      if (_looksLikeCompany(line)) {
        found.add(line);
      }
    }

    return found.toList(growable: false);
  }

  bool _looksLikeCompany(String line) {
    if (line.length < 3 || line.length > 40) return false;

    final lower = line.toLowerCase();

    const bannedKeywords = [
      'lot',
      'catalog',
      'product',
      'ref',
      'exp',
      'date',
      'barcode',
      'qr',
      'www.',
      'http',
    ];

    for (final keyword in bannedKeywords) {
      if (lower.contains(keyword)) return false;
    }

    final hasLetters = RegExp(r'[A-Za-z가-힣]').hasMatch(line);
    if (!hasLetters) return false;

    final tooManySymbols = RegExp(r'^[A-Z0-9\-_/\.\s]+$').hasMatch(line);
    if (tooManySymbols) return false;

    return true;
  }
}