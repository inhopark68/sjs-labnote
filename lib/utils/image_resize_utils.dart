import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

class ResizedImageResult {
  final List<int> bytes;
  final String extension;
  final int width;
  final int height;
  final String mimeType;

  ResizedImageResult({
    required this.bytes,
    required this.extension,
    required this.width,
    required this.height,
    required this.mimeType,
  });
}

Future<ResizedImageResult> resizeImageForNoteFigure(
  File file, {
  int maxWidth = 1200,
  int jpegQuality = 88,
}) async {
  final rawBytes = await file.readAsBytes();
  final decoded = img.decodeImage(rawBytes);

  if (decoded == null) {
    throw Exception('이미지를 읽을 수 없습니다.');
  }

  final baked = img.bakeOrientation(decoded);

  img.Image output = baked;
  if (baked.width > maxWidth) {
    output = img.copyResize(
      baked,
      width: maxWidth,
      interpolation: img.Interpolation.average,
    );
  }

  final jpgBytes = img.encodeJpg(output, quality: jpegQuality);

  return ResizedImageResult(
    bytes: jpgBytes,
    extension: '.jpg',
    width: output.width,
    height: output.height,
    mimeType: 'image/jpeg',
  );
}