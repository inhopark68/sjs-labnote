class OcrExtractResult {
  final List<String> lotCandidates;
  final List<String> expRawCandidates;
  final List<DateTime> expDateCandidates;

  OcrExtractResult({
    required this.lotCandidates,
    required this.expRawCandidates,
    required this.expDateCandidates,
  });
}

// --- public: main entry ---
OcrExtractResult extractLotAndExpCandidates(
  String ocrText, {
  int maxLots = 5,
  int maxExps = 5,
  DateTime? now,
}) {
  final text = _normalizeOcrText(ocrText);
  final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  final lots = _extractLotCandidates(lines, maxLots: maxLots);

  final expRaw = <String>[];
  final expDates = <DateTime>[];
  final seenRaw = <String>{};
  final seenDate = <String>{};

  for (final line in lines) {
    final candidates = _findDateLikeSubstrings(line);
    for (final c in candidates) {
      final raw = c.trim();
      if (raw.isEmpty) continue;
      if (!seenRaw.add(raw)) continue;

      final parsed = parseExpToDate(raw, now: now);
      if (parsed != null) {
        final key = parsed.toIso8601String().substring(0, 10);
        if (seenDate.add(key)) {
          expRaw.add(raw);
          expDates.add(parsed);
        }
      }
    }
  }

  final zipped = List.generate(expDates.length, (i) => (expDates[i], expRaw[i]));
  zipped.sort((a, b) => b.$1.compareTo(a.$1));
  final expDatesSorted = zipped.map((e) => e.$1).toList();
  final expRawSorted = zipped.map((e) => e.$2).toList();

  return OcrExtractResult(
    lotCandidates: lots.take(maxLots).toList(),
    expRawCandidates: expRawSorted.take(maxExps).toList(),
    expDateCandidates: expDatesSorted.take(maxExps).toList(),
  );
}

DateTime? parseExpToDate(String raw, {DateTime? now}) {
  final s0 = raw.trim();
  if (s0.isEmpty) return null;

  var s = s0
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('.', '/')
      .replaceAll('-', '/')
      .trim();

  final ymd = RegExp(r'^(\d{4})/(\d{1,2})/(\d{1,2})$').firstMatch(s);
  if (ymd != null) {
    return _safeDate(int.parse(ymd.group(1)!), int.parse(ymd.group(2)!), int.parse(ymd.group(3)!));
  }

  final dmy = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(s);
  if (dmy != null) {
    return _safeDate(int.parse(dmy.group(3)!), int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
  }

  final dmy2 = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2})$').firstMatch(s);
  if (dmy2 != null) {
    final yy = int.parse(dmy2.group(3)!);
    final y = _expand2DigitYear(yy, now: now);
    return _safeDate(y, int.parse(dmy2.group(2)!), int.parse(dmy2.group(1)!));
  }

  final ym = RegExp(r'^(\d{4})/(\d{1,2})$').firstMatch(s);
  if (ym != null) {
    final y = int.parse(ym.group(1)!);
    final m = int.parse(ym.group(2)!);
    final last = _lastDayOfMonth(y, m);
    return _safeDate(y, m, last);
  }

  final my = RegExp(r'^(\d{1,2})/(\d{4})$').firstMatch(s);
  if (my != null) {
    final m = int.parse(my.group(1)!);
    final y = int.parse(my.group(2)!);
    final last = _lastDayOfMonth(y, m);
    return _safeDate(y, m, last);
  }

  final sMonth = s0.replaceAll(RegExp(r'[\.\-\/]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final tokens = sMonth.split(' ');
  if (tokens.length >= 3) {
    final ddMonYyyy = RegExp(r'^\d{1,2}$').hasMatch(tokens[0]) &&
        _monthFromToken(tokens[1]) != null &&
        RegExp(r'^\d{4}$').hasMatch(tokens[2]);
    if (ddMonYyyy) {
      return _safeDate(int.parse(tokens[2]), _monthFromToken(tokens[1])!, int.parse(tokens[0]));
    }

    final monDdYyyy = _monthFromToken(tokens[0]) != null &&
        RegExp(r'^\d{1,2}$').hasMatch(tokens[1]) &&
        RegExp(r'^\d{4}$').hasMatch(tokens[2]);
    if (monDdYyyy) {
      return _safeDate(int.parse(tokens[2]), _monthFromToken(tokens[0])!, int.parse(tokens[1]));
    }
  }

  return null;
}

List<String> suggestReagentNameCandidates(String ocrText, {int max = 5}) {
  final text = _normalizeOcrText(ocrText);
  final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  final bad = RegExp(r'\b(LOT|BATCH|EXP|USE BY|BEST BEFORE|MFG|DATE|CAT|CATALOG|REF|SERIAL|SN)\b',
      caseSensitive: false);

  bool looksLikeName(String s) {
    if (s.length < 4 || s.length > 60) return false;
    if (bad.hasMatch(s)) return false;
    final letters = RegExp(r'[A-Za-z]').allMatches(s).length;
    if (letters < 3) return false;
    if (s.contains('http') || s.contains('www')) return false;
    if (s.toLowerCase().contains('for research use')) return false;
    return true;
  }

  final out = <String>[];
  final seen = <String>{};
  for (final s in lines.take(12)) {
    if (looksLikeName(s) && seen.add(s)) out.add(s);
    if (out.length >= max) return out;
  }
  for (final s in lines.skip(12)) {
    if (looksLikeName(s) && seen.add(s)) out.add(s);
    if (out.length >= max) break;
  }
  return out.take(max).toList();
}

// --- internals ---
String _normalizeOcrText(String s) {
  return s.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceAll(RegExp(r'[ \t]+'), ' ').trim();
}

List<String> _extractLotCandidates(List<String> lines, {int maxLots = 5}) {
  final candidates = <String>[];
  final seen = <String>{};

  final kw = RegExp(r'\b(LOT|Lot|BATCH|Batch|Batch#|Lot#|LOT#|Lot No|LOT NO|LN)\b');
  for (final line in lines) {
    if (!kw.hasMatch(line)) continue;
    final after = line.split(RegExp(r'[:#]')).skip(1).join(':').trim();
    final fromAfter = _pickLotLikeToken(after);
    if (fromAfter != null && seen.add(fromAfter)) candidates.add(fromAfter);

    final token = _pickLotLikeToken(line);
    if (token != null && seen.add(token)) candidates.add(token);

    if (candidates.length >= maxLots) return candidates;
  }

  for (final line in lines) {
    final token = _pickLotLikeToken(line);
    if (token != null && seen.add(token)) candidates.add(token);
    if (candidates.length >= maxLots) break;
  }
  return candidates;
}

String? _pickLotLikeToken(String s) {
  final cleaned = s.replaceAll(RegExp(r'[\(\)\[\]\{\},;]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleaned.isEmpty) return null;
  final tokens = cleaned.split(' ');

  const stop = {'LOT','Lot','BATCH','Batch','NO','No','NO.','No.','EXP','Exp','USE','BY','Best','Before'};
  for (final t in tokens) {
    if (stop.contains(t)) continue;
    if (!RegExp(r'^[A-Za-z0-9\-_]{3,20}$').hasMatch(t)) continue;

    final hasAlpha = RegExp(r'[A-Za-z]').hasMatch(t);
    final hasDigit = RegExp(r'\d').hasMatch(t);
    if (hasDigit && (hasAlpha || t.length >= 5)) return t;
  }
  return null;
}

List<String> _findDateLikeSubstrings(String line) {
  final out = <String>[];
  final ymd = RegExp(r'\b(20\d{2})[.\-\/](\d{1,2})[.\-\/](\d{1,2})\b');
  out.addAll(ymd.allMatches(line).map((m) => m.group(0)!).toList());

  final dmy = RegExp(r'\b(\d{1,2})[.\-\/](\d{1,2})[.\-\/](20\d{2})\b');
  out.addAll(dmy.allMatches(line).map((m) => m.group(0)!).toList());

  final my = RegExp(r'\b(\d{1,2})[.\-\/](20\d{2})\b');
  out.addAll(my.allMatches(line).map((m) => m.group(0)!).toList());

  final ym = RegExp(r'\b(20\d{2})[.\-\/](\d{1,2})\b');
  out.addAll(ym.allMatches(line).map((m) => m.group(0)!).toList());

  final monthName = RegExp(
    r'\b(\d{1,2})\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\s*(20\d{2})\b',
    caseSensitive: false,
  );
  out.addAll(monthName.allMatches(line).map((m) => m.group(0)!).toList());

  final monthName2 = RegExp(
    r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\s*(\d{1,2})\s*(20\d{2})\b',
    caseSensitive: false,
  );
  out.addAll(monthName2.allMatches(line).map((m) => m.group(0)!).toList());

  return out;
}

int _expand2DigitYear(int yy, {DateTime? now}) {
  final base = (now ?? DateTime.now()).year;
  final century = (base ~/ 100) * 100;
  final cand1 = century + yy;
  final cand2 = (century - 100) + yy;
  final d1 = (cand1 - base).abs();
  final d2 = (cand2 - base).abs();
  if (d1 < d2) return cand1;
  if (d2 < d1) return cand2;
  return cand1 >= base ? cand1 : cand2;
}

int _lastDayOfMonth(int year, int month) {
  final next = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return next.subtract(const Duration(days: 1)).day;
}

DateTime? _safeDate(int year, int month, int day) {
  if (year < 1900 || year > 2200) return null;
  if (month < 1 || month > 12) return null;
  final last = _lastDayOfMonth(year, month);
  if (day < 1 || day > last) return null;
  return DateTime(year, month, day);
}

int? _monthFromToken(String token) {
  final t = token.trim().toLowerCase();
  const map = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };
  return map[t];
}
