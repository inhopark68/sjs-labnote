import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/app_database.dart'; // 네 파일 경로에 맞춰 조정
import 'scan_classifier.dart';

class ScanResolveService {
  final AppDatabase db;

  ScanResolveService(this.db);

  /// raw 스캔값을 받아서
  /// 1) 분류 → 2) 필요시 네트워크 조회 → 3) db.insertScan 저장
  /// 반환: 저장된 scan id
  Future<String> resolveAndSave(String raw) async {
    final hit = classifyScan(raw);

    switch (hit.kind) {
      case ScanKind.doi:
        final doi = hit.value;
        final crossref = await _fetchCrossref(doi);
        final title = _firstString(crossref, ['message', 'title']) ?? doi;
        final journal = _firstString(crossref, ['message', 'container-title']);
        final year = _issuedYear(crossref);

        final subtitle = _joinNotEmpty([journal, year]);

        return db.insertScan(
          kind: 'doi',
          rawScanValue: raw,
          identifier: doi,
          title: title,
          subtitle: subtitle,
          sourceUrl: 'https://doi.org/$doi',
          payloadJson: jsonEncode(crossref),
        );

      case ScanKind.isbn:
        final isbn = hit.value;
        final books = await _fetchGoogleBooks(isbn);
        final info = _firstMap(books, ['items', 0, 'volumeInfo']);

        final title = (info?['title'] as String?)?.trim();
        final authors = (info?['authors'] as List?)
            ?.whereType<String>()
            .toList();
        final subtitle = authors == null || authors.isEmpty
            ? null
            : authors.join(', ');
        final infoUrl = info?['infoLink'] as String?;

        return db.insertScan(
          kind: 'isbn',
          rawScanValue: raw,
          identifier: isbn,
          title: title?.isNotEmpty == true ? title! : isbn,
          subtitle: subtitle,
          sourceUrl: infoUrl,
          payloadJson: jsonEncode(books),
        );

      case ScanKind.reagentTag:
        final parsed = _parseKeyValueTag(raw);
        final title =
            (parsed['name'] ?? parsed['cat'] ?? parsed['pn'] ?? 'Reagent')
                .toString();
        final subtitle = parsed['vendor']?.toString();

        return db.insertScan(
          kind: 'reagent',
          rawScanValue: raw,
          identifier: (parsed['cat'] ?? parsed['pn'] ?? parsed['lot'])
              ?.toString(),
          title: title,
          subtitle: subtitle,
          payloadJson: jsonEncode(parsed),
        );

      case ScanKind.reagentCatalog:
        // 카탈로그 번호만으로는 벤더 자동 특정이 어려워서, “저장 + 후편집”을 권장
        return db.insertScan(
          kind: 'reagent',
          rawScanValue: raw,
          identifier: hit.value,
          title: hit.value,
          subtitle: 'Catalog (needs vendor)',
          payloadJson: jsonEncode({'catalog': hit.value}),
        );

      case ScanKind.eanUpc:
        final barcode = hit.value;
        final off = await _fetchOpenFoodFacts(barcode);

        final product = off?['product'] as Map<String, dynamic>?;
        final productName = product?['product_name']?.toString();
        final brands = product?['brands']?.toString();
        final url = product?['url']?.toString();

        return db.insertScan(
          kind: 'product',
          rawScanValue: raw,
          identifier: barcode,
          title: (productName != null && productName.trim().isNotEmpty)
              ? productName.trim()
              : barcode,
          subtitle: (brands != null && brands.trim().isNotEmpty)
              ? brands.trim()
              : null,
          sourceUrl: url,
          payloadJson: jsonEncode(
            off ?? {'not_found': true, 'barcode': barcode},
          ),
        );

      case ScanKind.url:
        return db.insertScan(
          kind: 'url',
          rawScanValue: raw,
          identifier: hit.value,
          title: hit.value,
          sourceUrl: hit.value,
        );

      case ScanKind.unknown:
        return db.insertScan(kind: 'unknown', rawScanValue: raw, title: raw);
    }
  }

  // -------------------------
  // Network fetchers
  // -------------------------

  Future<Map<String, dynamic>> _fetchCrossref(String doi) async {
    final encoded = Uri.encodeComponent(doi);
    final uri = Uri.parse('https://api.crossref.org/works/$encoded');

    final res = await http.get(
      uri,
      headers: {
        // Crossref는 User-Agent 권장
        'User-Agent': 'labnote/1.0 (mailto:you@example.com)',
      },
    );

    if (res.statusCode != 200) {
      return {'error': 'crossref', 'status': res.statusCode, 'doi': doi};
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _fetchGoogleBooks(String isbn) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn',
    );
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      return {'error': 'google_books', 'status': res.statusCode, 'isbn': isbn};
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> _fetchOpenFoodFacts(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.net/api/v2/product/$barcode',
    );
    final res = await http.get(uri);

    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // -------------------------
  // Helpers
  // -------------------------

  Map<String, dynamic> _parseKeyValueTag(String raw) {
    // 지원 형식 예:
    // "VENDOR=Thermo;CAT=AB123;LOT=0001;EXP=2026-10-31;NAME=Buffer"
    final out = <String, dynamic>{'raw': raw};

    final parts = raw
        .split(RegExp(r'[;\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);

    for (final p in parts) {
      final m = RegExp(r'^([A-Za-z_]+)\s*[:=]\s*(.+)$').firstMatch(p);
      if (m == null) continue;
      final k = m.group(1)!.toLowerCase();
      final v = m.group(2)!.trim();
      out[k] = v;
    }

    return out;
  }

  String? _issuedYear(Map<String, dynamic> crossref) {
    final msg = crossref['message'];
    if (msg is! Map) return null;

    final issued = msg['issued'];
    if (issued is! Map) return null;

    final dateParts = issued['date-parts'];
    if (dateParts is! List || dateParts.isEmpty) return null;

    final first = dateParts.first;
    if (first is! List || first.isEmpty) return null;

    final y = first.first;
    return y?.toString();
  }

  String? _firstString(Map<String, dynamic> json, List path) {
    dynamic cur = json;
    for (final p in path) {
      if (p is String) {
        if (cur is Map && cur.containsKey(p)) {
          cur = cur[p];
        } else {
          return null;
        }
      } else if (p is int) {
        if (cur is List && cur.length > p) {
          cur = cur[p];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }

    // Crossref의 title/container-title은 List인 경우가 많음
    if (cur is List) {
      final first = cur.where((e) => e != null).cast<dynamic>().toList();
      if (first.isEmpty) return null;
      return first.first.toString();
    }

    return cur?.toString();
  }

  Map<String, dynamic>? _firstMap(Map<String, dynamic> json, List path) {
    dynamic cur = json;
    for (final p in path) {
      if (p is String) {
        if (cur is Map && cur.containsKey(p)) {
          cur = cur[p];
        } else {
          return null;
        }
      } else if (p is int) {
        if (cur is List && cur.length > p) {
          cur = cur[p];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return cur is Map<String, dynamic>
        ? cur
        : (cur is Map ? cur.cast<String, dynamic>() : null);
  }

  String? _joinNotEmpty(List<String?> parts) {
    final items = parts
        .where((e) => e != null && e.trim().isNotEmpty)
        .cast<String>()
        .toList();
    if (items.isEmpty) return null;
    return items.join(' • ');
  }
}
