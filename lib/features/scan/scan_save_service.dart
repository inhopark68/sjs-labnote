import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../db/app_db.dart';
import '../../db/daos/scanned_items_dao.dart';
import 'scan_classifier.dart';

class ScanSaveService {
  final ScannedItemsDao dao;
  ScanSaveService(this.dao);

  Future<int> handleScanAndSave(String raw) async {
    final hit = classifyScan(raw);

    switch (hit.kind) {
      case ScanKind.doi:
        final meta = await _fetchDoi(hit.value);
        return dao.insertItem(
          kind: 'doi',
          rawScanValue: raw,
          identifier: hit.value,
          title: meta.title ?? hit.value,
          subtitle: meta.subtitle,
          sourceUrl: 'https://doi.org/${hit.value}',
          payload: meta.raw,
        );

      case ScanKind.isbn:
        final meta = await _fetchIsbn(hit.value);
        return dao.insertItem(
          kind: 'isbn',
          rawScanValue: raw,
          identifier: hit.value,
          title: meta.title ?? hit.value,
          subtitle: meta.subtitle,
          sourceUrl: meta.infoUrl,
          payload: meta.raw,
        );

      case ScanKind.reagentTag:
        // 키-밸류면: 파싱해서 payload에 넣고, title/subtitle은 최소만 구성
        final parsed = _parseReagentTag(raw);
        return dao.insertItem(
          kind: 'reagent',
          rawScanValue: raw,
          identifier: parsed['cat'] ?? parsed['pn'] ?? parsed['lot'],
          title: parsed['name'] ?? (parsed['cat'] ?? 'Reagent'),
          subtitle: parsed['vendor'],
          payload: parsed,
        );

      case ScanKind.reagentCatalog:
        // 카탈로그 번호 추정: 네트워크로 “정답” 찾기 어렵기 때문에 일단 저장+후편집 UX 추천
        return dao.insertItem(
          kind: 'reagent',
          rawScanValue: raw,
          identifier: hit.value,
          title: hit.value,
          subtitle: 'Catalog (needs vendor)',
          payload: {'catalog': hit.value},
        );

      case ScanKind.eanUpc:
        final rawJson = await _fetchOpenFoodFacts(hit.value);
        final title = rawJson?['product']?['product_name']?.toString();
        final brand = rawJson?['product']?['brands']?.toString();
        return dao.insertItem(
          kind: 'product',
          rawScanValue: raw,
          identifier: hit.value,
          title: title?.isNotEmpty == true ? title! : hit.value,
          subtitle: brand,
          sourceUrl: rawJson?['product']?['url']?.toString(),
          payload: rawJson,
        );

      case ScanKind.url:
        return dao.insertItem(
          kind: 'url',
          rawScanValue: raw,
          identifier: raw,
          title: raw,
          sourceUrl: raw,
        );

      case ScanKind.unknown:
        return dao.insertItem(
          kind: 'unknown',
          rawScanValue: raw,
          identifier: null,
          title: raw,
        );
    }
  }

  // -------------------------
  // DOI: Crossref
  Future<_DoiMeta> _fetchDoi(String doi) async {
    final encoded = Uri.encodeComponent(doi);
    final uri = Uri.parse('https://api.crossref.org/works/$encoded');
    final res = await http.get(
      uri,
      headers: {'User-Agent': 'labnote/1.0 (mailto:you@example.com)'},
    );
    if (res.statusCode != 200) return _DoiMeta(raw: {'error': res.statusCode});

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final msg = (json['message'] as Map?)?.cast<String, dynamic>();

    final title = (msg?['title'] as List?)
        ?.cast<dynamic>()
        .firstOrNull
        ?.toString();
    final journal = (msg?['container-title'] as List?)
        ?.cast<dynamic>()
        .firstOrNull
        ?.toString();
    final year = (msg?['issued']?['date-parts'] as List?)
        ?.firstOrNull
        ?.firstOrNull
        ?.toString();

    return _DoiMeta(
      title: title,
      subtitle: [
        journal,
        year,
      ].where((e) => (e ?? '').toString().isNotEmpty).join(' • '),
      raw: json,
    );
  }

  // ISBN: Google Books
  Future<_BookMeta> _fetchIsbn(String isbn) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return _BookMeta(raw: {'error': res.statusCode});

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (json['items'] as List?)?.cast<dynamic>();
    final vol = items != null && items.isNotEmpty
        ? items.first as Map<String, dynamic>
        : null;
    final info = (vol?['volumeInfo'] as Map?)?.cast<String, dynamic>();

    final title = info?['title']?.toString();
    final authors = (info?['authors'] as List?)?.join(', ');
    final infoUrl = info?['infoLink']?.toString();

    return _BookMeta(
      title: title,
      subtitle: authors,
      infoUrl: infoUrl,
      raw: json,
    );
  }

  // EAN/UPC: Open Food Facts
  Future<Map<String, dynamic>?> _fetchOpenFoodFacts(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.net/api/v2/product/$barcode',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Map<String, dynamic> _parseReagentTag(String raw) {
    // 아주 단순 키-밸류 파서: "CAT=...;LOT=...;EXP=..." 형태 지원
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
}

class _DoiMeta {
  final String? title;
  final String? subtitle;
  final Map<String, dynamic> raw;
  _DoiMeta({this.title, this.subtitle, required this.raw});
}

class _BookMeta {
  final String? title;
  final String? subtitle;
  final String? infoUrl;
  final Map<String, dynamic> raw;
  _BookMeta({this.title, this.subtitle, this.infoUrl, required this.raw});
}

extension _FirstOrNull on List {
  dynamic get firstOrNull => isEmpty ? null : first;
}
