enum ScanKind {
  doi,
  isbn,
  reagentTag, // LOT=, CAT=, EXP= 같은 키-밸류 QR
  reagentCatalog, // 카탈로그 번호처럼 보이는 문자열(휴리스틱)
  eanUpc,
  url,
  unknown,
}

class ScanHit {
  final ScanKind kind;
  final String value; // 정규화된 값(doi/isbn/barcode 등)

  const ScanHit(this.kind, this.value);
}

ScanHit classifyScan(String raw) {
  final s = raw.trim();

  // 1) DOI (최우선)
  final doi = _extractDoi(s);
  if (doi != null) return ScanHit(ScanKind.doi, doi);

  // 2) ISBN
  final isbn = _extractIsbn(s);
  if (isbn != null) return ScanHit(ScanKind.isbn, isbn);

  // 3) 시약 태그 (키-밸류)
  if (_hasReagentTag(s)) return ScanHit(ScanKind.reagentTag, s);

  // 4) EAN/UPC
  final ean = _extractEanUpc(s);
  if (ean != null) return ScanHit(ScanKind.eanUpc, ean);

  // 5) URL (fallback)
  if (s.startsWith('http://') || s.startsWith('https://')) {
    return ScanHit(ScanKind.url, s);
  }

  // 6) 시약 카탈로그 번호 추정(마지막)
  if (_looksLikeReagentCatalog(s)) return ScanHit(ScanKind.reagentCatalog, s);

  return ScanHit(ScanKind.unknown, s);
}

String? _extractDoi(String s) {
  // DOI URL 형태
  final m1 = RegExp(
    r'(?:https?://(?:dx\.)?doi\.org/)(10\.\d{4,9}/\S+)',
    caseSensitive: false,
  ).firstMatch(s);
  if (m1 != null) return m1.group(1);

  // 순수 DOI
  final m2 = RegExp(r'^(10\.\d{4,9}/\S+)$').firstMatch(s);
  return m2?.group(1);
}

String? _extractIsbn(String s) {
  final cleaned = s.toUpperCase().replaceAll(RegExp(r'[^0-9X]'), '');
  if (cleaned.length == 10 || cleaned.length == 13) return cleaned;
  return null;
}

bool _hasReagentTag(String s) {
  return RegExp(
    r'(LOT|CAT|PN|EXP|MFG|VENDOR|NAME)\s*[:=]',
    caseSensitive: false,
  ).hasMatch(s);
}

String? _extractEanUpc(String s) {
  final m = RegExp(r'^\d{8}$|^\d{12}$|^\d{13}$|^\d{14}$').firstMatch(s);
  return m?.group(0);
}

bool _looksLikeReagentCatalog(String s) {
  if (s.length < 4 || s.length > 30) return false;
  if (s.contains(' ')) return false;
  final hasAlpha = RegExp(r'[A-Za-z]').hasMatch(s);
  final hasDigit = RegExp(r'\d').hasMatch(s);
  return hasAlpha && hasDigit;
}
