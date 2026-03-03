import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// 사진 용량을 줄이기 위한 리사이즈/압축 서비스 (웹/모바일 공용)
class ImageCompressor {
  final int maxSide;
  final int jpegQuality;

  const ImageCompressor({this.maxSide = 2000, this.jpegQuality = 80});

  /// 어떤 플랫폼이든 bytes만 있으면 동작
  Future<List<int>?> compressToJpegBytes(Uint8List inputBytes) async {
    try {
      final decoded = img.decodeImage(inputBytes);
      if (decoded == null) return null;

      final oriented = img.bakeOrientation(decoded);

      final w = oriented.width;
      final h = oriented.height;
      final longSide = w > h ? w : h;

      img.Image out = oriented;
      if (longSide > maxSide) {
        final scale = maxSide / longSide;
        final newW = (w * scale).round();
        final newH = (h * scale).round();
        out = img.copyResize(
          oriented,
          width: newW,
          height: newH,
          interpolation: img.Interpolation.average,
        );
      }

      return img.encodeJpg(out, quality: jpegQuality);
    } catch (_) {
      return null;
    }
  }
}
