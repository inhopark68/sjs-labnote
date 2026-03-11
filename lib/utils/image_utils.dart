import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

Future<File> compressImageToTargetMb({
  required File inputFile,
  required double targetMb,
  required Directory outputDir,
  String filePrefix = 'img_',
}) async {
  final targetBytes = (targetMb * 1024 * 1024).round();

  final inputBytes = await inputFile.readAsBytes();
  final decoded = img.decodeImage(inputBytes);
  if (decoded == null) return inputFile;

  final outPath = p.join(
    outputDir.path,
    '$filePrefix${DateTime.now().millisecondsSinceEpoch}.jpg',
  );

  if (inputBytes.length <= targetBytes) {
    final jpg = img.encodeJpg(decoded, quality: 95);
    final f = File(outPath);
    await f.writeAsBytes(jpg, flush: true);
    return f;
  }

  img.Image working = decoded;

  for (int resizeStep = 0; resizeStep < 10; resizeStep++) {
    final best = bestJpegUnderBytes(working, targetBytes);
    if (best != null) {
      final f = File(outPath);
      await f.writeAsBytes(best, flush: true);
      return f;
    }

    final w = working.width;
    final h = working.height;

    if (w <= 320 || h <= 320) break;

    const scale = 0.88;
    final newW = max(320, (w * scale).round());
    final newH = max(320, (h * scale).round());

    working = img.copyResize(
      working,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.average,
    );
  }

  final fallback = img.encodeJpg(working, quality: 20);
  final f = File(outPath);
  await f.writeAsBytes(fallback, flush: true);
  return f;
}

List<int>? bestJpegUnderBytes(img.Image working, int targetBytes) {
  int lo = 5;
  int hi = 95;
  List<int>? best;

  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    final jpg = img.encodeJpg(working, quality: mid);

    if (jpg.length <= targetBytes) {
      best = jpg;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }

  return best;
}