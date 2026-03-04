// lib/services/reagent_recognizer.dart
class ReagentHit {
  final String name;
  final double score;
  const ReagentHit(this.name, this.score);
}

class ReagentRecognizer {
  static final _casRegex = RegExp(r'\b\d{2,7}-\d{2}-\d\b');

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  /// OCR 텍스트에서 "시약 후보 줄"을 뽑아냅니다.
  static List<String> extractCandidates(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final out = <String>{};

    for (final line in lines) {
      final lower = line.toLowerCase();

      // CAS가 있으면 강한 후보
      if (_casRegex.hasMatch(line)) out.add(line);

      // 시약/라벨에서 흔한 단서
      final looksLike =
          lower.contains('cat') ||
          lower.contains('sku') ||
          lower.contains('sigma') ||
          lower.contains('tci') ||
          lower.contains('thermo') ||
          lower.contains('fisher') ||
          lower.contains('merck') ||
          lower.contains('invitrogen') ||
          lower.contains('mM'.toLowerCase()) ||
          lower.contains('mg/ml') ||
          lower.contains('%') ||
          lower.contains('buffer') ||
          lower.contains('acid') ||
          lower.contains('chloride') ||
          lower.contains('sulfate') ||
          lower.contains('ph ') ||
          lower.contains('pbs') ||
          lower.contains('tris');

      if (looksLike && line.length >= 4 && line.length <= 140) {
        out.add(line);
      }
    }

    return out.toList();
  }

  static int _levenshtein(String a, String b) {
    final la = a.length, lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;

    final dp = List.generate(la + 1, (_) => List<int>.filled(lb + 1, 0));
    for (var i = 0; i <= la; i++) dp[i][0] = i;
    for (var j = 0; j <= lb; j++) dp[0][j] = j;

    for (var i = 1; i <= la; i++) {
      for (var j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        final x = dp[i - 1][j] + 1;
        final y = dp[i][j - 1] + 1;
        final z = dp[i - 1][j - 1] + cost;
        dp[i][j] = (x < y ? (x < z ? x : z) : (y < z ? y : z));
      }
    }
    return dp[la][lb];
  }

  /// OCR 후보들과 시약명 목록을 매칭해서 점수 높은 순으로 반환
  static List<ReagentHit> match(
    List<String> candidates,
    List<String> reagentNames, {
    int maxHits = 20,
  }) {
    final results = <String, double>{};

    final rn = <String, String>{
      for (final r in reagentNames) r: _norm(r),
    };

    for (final c in candidates) {
      final cn = _norm(c);
      if (cn.isEmpty) continue;

      for (final entry in rn.entries) {
        final name = entry.key;
        final normName = entry.value;
        if (normName.isEmpty) continue;

        // 1) 부분일치(빠르고 정확)
        if (cn.contains(normName) || normName.contains(cn)) {
          results[name] = (results[name] ?? 0).clamp(0, 1);
          results[name] = (results[name] ?? 0) < 0.95 ? 0.95 : results[name]!;
          continue;
        }

        // 2) 퍼지 매칭(길이 짧은건 오탐 많아서 제한)
        if (cn.length >= 6 && normName.length >= 6) {
          final dist = _levenshtein(cn, normName);
          final maxLen = cn.length > normName.length ? cn.length : normName.length;
          final score = 1.0 - (dist / maxLen);
          if (score >= 0.82) {
            final prev = results[name] ?? 0.0;
            if (score > prev) results[name] = score;
          }
        }
      }
    }

    final hits = results.entries
        .map((e) => ReagentHit(e.key, e.value))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    if (hits.length > maxHits) return hits.sublist(0, maxHits);
    return hits;
  }
}