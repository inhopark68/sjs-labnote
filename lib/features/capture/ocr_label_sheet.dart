import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/ocr_extract.dart';
import 'text_recognizer_service.dart';

// ✅ Windows 카메라 페이지
import '../camera/camera_capture_page.dart';

class OcrReagentResult {
  final String name;
  final String? vendor;
  final String? catalogNo;
  final String? lot;
  final DateTime? expDate;

  // ✅ bytes 기반 (웹/모바일 공통)
  final Uint8List rawPhotoBytes;
  final String? originalName;

  final String? ocrText;

  const OcrReagentResult({
    required this.name,
    this.vendor,
    this.catalogNo,
    this.lot,
    this.expDate,
    required this.rawPhotoBytes,
    this.originalName,
    this.ocrText,
  });
}

class OcrLabelSheet extends StatefulWidget {
  final Future<void> Function(OcrReagentResult result)? onSubmit;
  final bool continuousMode;

  const OcrLabelSheet({super.key, this.onSubmit, this.continuousMode = false});

  @override
  State<OcrLabelSheet> createState() => _OcrLabelSheetState();
}

class _OcrLabelSheetState extends State<OcrLabelSheet> {
  final _picker = ImagePicker();
  final _recognizer = createTextRecognizerService();

  final _name = TextEditingController();
  final _vendor = TextEditingController();
  final _cat = TextEditingController();

  final _lotManual = TextEditingController();
  final _expManual = TextEditingController();

  bool _busy = false;

  // ✅ path 대신 bytes로 보관
  Uint8List? _photoBytes;
  String? _photoName;
  String? _ocrText;

  List<String> _nameCandidates = [];
  List<String> _lotCandidates = [];
  List<String> _expRawCandidates = [];
  List<DateTime> _expDateCandidates = [];

  String? _selectedLot;
  DateTime? _selectedExp;

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void dispose() {
    _name.dispose();
    _vendor.dispose();
    _cat.dispose();
    _lotManual.dispose();
    _expManual.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    // ✅ Windows: camera_windows로 촬영 -> bytes 기반 OCR
    if (_isWindows) {
      final Uint8List? bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => const CameraCapturePage()),
      );
      if (bytes == null) return;
      await _runOcrBytes(bytes, originalName: 'camera.jpg');
      return;
    }

    // ✅ Mobile: image_picker camera
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (x == null) return;
    await _runOcr(x);
  }

  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    await _runOcr(x);
  }

  Future<void> _resetUiForNewRun() async {
    setState(() {
      _busy = true;
      _photoBytes = null;
      _photoName = null;
      _ocrText = null;

      _nameCandidates = [];
      _lotCandidates = [];
      _expRawCandidates = [];
      _expDateCandidates = [];
      _selectedLot = null;
      _selectedExp = null;
    });
  }

  Future<void> _runOcr(XFile file) async {
    await _resetUiForNewRun();

    try {
      final bytes = await file.readAsBytes();
      final name = _safeXFileName(file);

      setState(() {
        _photoBytes = bytes;
        _photoName = name;
      });

      // ✅ 웹이면 OCR 미지원 안내
      if (kIsWeb) {
        setState(() {
          _ocrText = '';
          _nameCandidates = [];
          _lotCandidates = [];
          _expRawCandidates = [];
          _expDateCandidates = [];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('웹(Chrome)에서는 MLKit OCR을 지원하지 않습니다. 모바일에서 사용하세요.'),
            ),
          );
        }
        return;
      }

      // ✅ IO(모바일/데스크톱)에서만 MLKit 수행: file.path 사용
      final text = await _recognizer.recognizeFromFilePath(file.path);
      await _applyOcrText(text ?? '');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ✅ Windows용: bytes -> 임시 파일 저장 -> recognizeFromFilePath
  Future<void> _runOcrBytes(Uint8List bytes, {String? originalName}) async {
    await _resetUiForNewRun();

    try {
      setState(() {
        _photoBytes = bytes;
        _photoName = originalName;
      });

      // ✅ 웹이면 OCR 미지원 안내
      if (kIsWeb) {
        setState(() {
          _ocrText = '';
          _nameCandidates = [];
          _lotCandidates = [];
          _expRawCandidates = [];
          _expDateCandidates = [];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('웹(Chrome)에서는 MLKit OCR을 지원하지 않습니다. 모바일에서 사용하세요.'),
            ),
          );
        }
        return;
      }

      final tempPath = await _recognizer.writeTempImageBytes(
        bytes: bytes,
        suggestedName: originalName ?? 'ocr.jpg',
      );

      final text = await _recognizer.recognizeFromFilePath(tempPath);
      await _applyOcrText(text ?? '');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyOcrText(String ocr) async {
    final extracted = extractLotAndExpCandidates(ocr, maxLots: 5, maxExps: 5);
    final nameCands = suggestReagentNameCandidates(ocr, max: 5);

    setState(() {
      _ocrText = ocr;
      _nameCandidates = nameCands;
      _lotCandidates = extracted.lotCandidates;
      _expRawCandidates = extracted.expRawCandidates;
      _expDateCandidates = extracted.expDateCandidates;

      if (_lotCandidates.isNotEmpty) {
        _selectedLot = _lotCandidates.first;
        _lotManual.text = _selectedLot!;
      }
      if (_expDateCandidates.isNotEmpty) {
        _selectedExp = _expDateCandidates.first;
        _expManual.text = _fmtDate(_selectedExp!);
      }
      if (_name.text.trim().isEmpty && _nameCandidates.isNotEmpty) {
        _name.text = _nameCandidates.first;
      }
    });
  }

  Future<void> _submit({required bool closeAfter}) async {
    final name = _name.text.trim();
    if (name.isEmpty || _photoBytes == null) return;

    final lot = (_selectedLot?.trim().isNotEmpty == true)
        ? _selectedLot!.trim()
        : (_lotManual.text.trim().isEmpty ? null : _lotManual.text.trim());

    DateTime? exp = _selectedExp;
    if (exp == null && _expManual.text.trim().isNotEmpty) {
      exp = parseExpToDate(_expManual.text.trim());
    }

    final result = OcrReagentResult(
      name: name,
      vendor: _vendor.text.trim().isEmpty ? null : _vendor.text.trim(),
      catalogNo: _cat.text.trim().isEmpty ? null : _cat.text.trim(),
      lot: lot,
      expDate: exp,
      rawPhotoBytes: _photoBytes!,
      originalName: _photoName,
      ocrText: _ocrText,
    );

    if (widget.onSubmit != null) {
      await widget.onSubmit!(result);
    } else {
      Navigator.pop(context, result);
      return;
    }

    if (closeAfter) {
      Navigator.pop(context);
    } else {
      setState(() {
        _photoBytes = null;
        _photoName = null;
        _ocrText = null;
        _lotCandidates = [];
        _expRawCandidates = [];
        _expDateCandidates = [];
        _selectedLot = null;
        _selectedExp = null;
        _lotManual.clear();
        _expManual.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Material(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '라벨 OCR (시약)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: '시약 이름 *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_nameCandidates.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _nameCandidates.map((s) {
                      final selected = _name.text.trim() == s.trim();
                      return ChoiceChip(
                        label: Text(s, overflow: TextOverflow.ellipsis),
                        selected: selected,
                        onSelected: (_) => setState(() => _name.text = s),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _vendor,
                        decoration: const InputDecoration(
                          labelText: '제조사(옵션)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _cat,
                        decoration: const InputDecoration(
                          labelText: 'Catalog #(옵션)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _takePhoto,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('라벨 촬영'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('갤러리'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                if (_busy) const Center(child: CircularProgressIndicator()),

                if (_photoBytes != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _photoBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Text(
                  'LOT',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                if (_lotCandidates.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _lotCandidates.map((lot) {
                      final selected = lot == _selectedLot;
                      return ChoiceChip(
                        label: Text(lot),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _selectedLot = lot;
                          _lotManual.text = lot;
                        }),
                      );
                    }).toList(),
                  )
                else
                  const Text('후보 없음 → 수동 입력'),

                const SizedBox(height: 8),
                TextField(
                  controller: _lotManual,
                  decoration: const InputDecoration(
                    labelText: 'LOT 수동 입력(옵션)',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'EXP',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                if (_expDateCandidates.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_expDateCandidates.length, (i) {
                      final dt = _expDateCandidates[i];
                      final raw = i < _expRawCandidates.length
                          ? _expRawCandidates[i]
                          : _fmtDate(dt);
                      final selected = dt == _selectedExp;
                      return ChoiceChip(
                        label: Text('$raw → ${_fmtDate(dt)}'),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _selectedExp = dt;
                          _expManual.text = _fmtDate(dt);
                        }),
                      );
                    }),
                  )
                else
                  const Text('후보 없음 → 수동 입력'),

                const SizedBox(height: 8),
                TextField(
                  controller: _expManual,
                  decoration: const InputDecoration(
                    labelText: 'EXP 수동 입력(옵션)',
                    hintText: '2026-10-31 또는 10/2026',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    if (widget.continuousMode)
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              (_name.text.trim().isEmpty ||
                                  _busy ||
                                  _photoBytes == null)
                              ? null
                              : () => _submit(closeAfter: false),
                          child: const Text('저장 후 다음 스캔'),
                        ),
                      ),
                    if (widget.continuousMode) const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            (_name.text.trim().isEmpty ||
                                _busy ||
                                _photoBytes == null)
                            ? null
                            : () => _submit(closeAfter: true),
                        child: Text(widget.continuousMode ? '완료' : '등록'),
                      ),
                    ),
                  ],
                ),

                if ((_ocrText ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'OCR 텍스트(참고)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _ocrText!,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? _safeXFileName(XFile f) {
    try {
      final dynamic d = f;
      return d.name as String?;
    } catch (_) {
      return null;
    }
  }
}
