import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../data/app_database.dart'; // 경로 맞춰 수정
import 'scan_resolve_service.dart';
import 'scan_detail_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _locked = false;
  bool _busy = false;

  Future<void> _handle(String raw) async {
    if (_locked || _busy) return;
    _locked = true;
    setState(() => _busy = true);

    try {
      final db = context.read<AppDatabase>();
      final service = ScanResolveService(db);

      final id = await service.resolveAndSave(raw);

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScanDetailPage(scanId: id)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('스캔 처리 실패: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
      // 약간의 딜레이 후 다시 스캔 허용(연속 감지 방지)
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _locked = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('스캔')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue;
              if (raw == null || raw.trim().isEmpty) return;

              _handle(raw.trim());
            },
          ),
          if (_busy)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(),
            ),
          const Positioned(left: 12, right: 12, bottom: 20, child: _HintCard()),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '우선순위: DOI/ISBN → 시약(QR 태그) → EAN/UPC\n'
          'QR/바코드를 프레임 안에 맞춰주세요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
