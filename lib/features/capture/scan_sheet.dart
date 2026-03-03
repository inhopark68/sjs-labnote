import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanSheet extends StatefulWidget {
  const ScanSheet({super.key});

  @override
  State<ScanSheet> createState() => _ScanSheetState();
}

class _ScanSheetState extends State<ScanSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    _done = true;
    Navigator.pop(context, raw);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  const Expanded(child: Text('바코드/QR 스캔', style: TextStyle(fontWeight: FontWeight.w700))),
                  IconButton(onPressed: _controller.toggleTorch, icon: const Icon(Icons.flash_on)),
                  IconButton(onPressed: _controller.switchCamera, icon: const Icon(Icons.cameraswitch)),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('라벨/박스/장비 QR을 중앙에 맞추세요.'),
            ),
          ],
        ),
      ),
    );
  }
}
