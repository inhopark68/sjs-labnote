import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:labnote/data/app_database.dart';

import 'backup_platform/download_file.dart' as dl;
import 'backup_service.dart';

class BackupServiceImpl implements BackupService {
  final AppDatabase db;
  BackupServiceImpl(this.db);

  static const int _kPbkdf2Iter = 100000;
  static const int _kSaltLen = 16;
  static const int _kNonceLen = 12; // GCM 권장 12 bytes

  // -----------------------
  // EXPORT
  // -----------------------
  @override
  Future<Uint8List> exportBackup({String? password}) async {
    final rows = await db.allNoteRowsIncludingDeleted();

    // 1) "평문 백업 payload"
    final plainPayload = <String, dynamic>{
      'version': 2,
      'ts': DateTime.now().toIso8601String(),
      'encrypted': false,
      'notes': rows.map(_dbRowToJson).toList(growable: false),
    };

    final isEncrypted = password != null && password.isNotEmpty;

    String outJson;
    String filename;

    if (!isEncrypted) {
      outJson = jsonEncode(plainPayload);
      filename = _makeFilename(encrypted: false);
    } else {
      // 2) 평문 payload JSON을 암호화해 "컨테이너 JSON" 생성
      final plainJson = jsonEncode(plainPayload);
      final container = _encryptToContainerJson(plainJson, password!);
      outJson = jsonEncode(container);
      filename = _makeFilename(encrypted: true);
    }

    final bytes = Uint8List.fromList(utf8.encode(outJson));

    if (kIsWeb) {
      await dl.downloadBytes(
        bytes: bytes,
        filename: filename,
        mime: 'application/json',
      );
    }

    return bytes;
  }

  // ✅ DbNote.id(int) 기반 + legacyId 포함(선택)
  Map<String, dynamic> _dbRowToJson(DbNote r) => <String, dynamic>{
        // 하위호환을 위해 id는 숫자로 저장
        'id': r.id,
        // 구버전 id가 있으면 같이 저장(선택)
        if (r.legacyId != null) 'legacyId': r.legacyId,
        'title': r.title,
        'body': r.body,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
        'isPinned': r.isPinned,
        'isLocked': r.isLocked,
        'isDeleted': r.isDeleted,
        'project': r.project,
        'noteDate': r.noteDate?.toIso8601String(),
      };

  String _makeFilename({required bool encrypted}) {
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    return encrypted ? 'labnote-backup-$ts.enc.json' : 'labnote-backup-$ts.json';
  }

  // -----------------------
  // PICK (IMPORT SOURCE)
  // -----------------------
  @override
  Future<String?> pickRawBackupText() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return null;

    final f = result.files.single;

    // 웹/모바일 공통: bytes가 있으면 바로 사용
    if (f.bytes != null) {
      return utf8.decode(f.bytes!, allowMalformed: true);
    }

    // ✅ 웹에서는 path 읽기 불가 → null 처리
    if (kIsWeb) return null;

    // 모바일/데스크탑인데 path가 없으면 실패
    if (f.path == null) return null;

    throw Exception('이 환경에서는 path 기반 파일 읽기가 지원되지 않습니다.');
  }

  // -----------------------
  // SAFE IMPORT (PRE-RESTORE + IMPORT)
  // -----------------------
  @override
  Future<void> safeImportWithPreBackup({
    required String rawBackupText,
    required String preBackupPassword,
    String? importPassword,
  }) async {
    // PRE-RESTORE 백업을 먼저 생성 (웹이면 다운로드됨)
    await exportBackup(password: preBackupPassword);

    // 실제 import
    await _import(rawBackupText: rawBackupText, importPassword: importPassword);
  }

  Future<void> _import({
    required String rawBackupText,
    required String? importPassword,
  }) async {
    // 1) 먼저 "바깥 JSON" 파싱
    Map<String, dynamic> root;
    try {
      final obj = jsonDecode(rawBackupText);
      if (obj is! Map<String, dynamic>) {
        throw Exception('백업 루트가 Map이 아닙니다.');
      }
      root = obj;
    } catch (e) {
      throw Exception('백업 파일 형식이 올바르지 않습니다: $e');
    }

    final version = root['version'];
    if (version != 2) throw Exception('지원하지 않는 백업 버전입니다: $version');

    final encryptedFlag = root['encrypted'] == true;

    // 2) encrypted면 복호화해서 "평문 payload" 획득
    Map<String, dynamic> plainPayload;
    if (!encryptedFlag) {
      plainPayload = root; // 이미 평문 payload
    } else {
      if (importPassword == null || importPassword.isEmpty) {
        throw Exception('암호화된 백업은 비밀번호가 필요합니다.');
      }
      final plainJson = _decryptContainerToPlainJson(root, importPassword);
      final obj = jsonDecode(plainJson);
      if (obj is! Map<String, dynamic>) {
        throw Exception('복호화 결과가 올바르지 않습니다.');
      }
      plainPayload = obj;
    }

    // 3) notes -> List<Note> 변환
    final notesAny = plainPayload['notes'];
    if (notesAny is! List) throw Exception('notes가 List가 아닙니다.');

    final notes = <Note>[];

    for (final e in notesAny) {
      if (e is! Map) continue;
      final m = e.cast<String, dynamic>();

      // ✅ 하위호환: id는 int 또는 string일 수 있음
      final legacyId = _parseLegacyId(m['legacyId']) ?? _parseLegacyId(m['id']);
      // 현재 스키마는 autoIncrement id를 새로 발급하므로, Note.id는 "더미"로 채움(0)
      // (AppDatabase.replaceAllNotesFromBackup에서 id는 쓰지 않도록 구현되어 있어야 함)
      const generatedId = 0;

      final createdAt =
          DateTime.tryParse((m['createdAt'] as String?) ?? '') ?? DateTime.now();
      final updatedAt =
          DateTime.tryParse((m['updatedAt'] as String?) ?? '') ?? DateTime.now();

      final noteDate =
          DateTime.tryParse((m['noteDate'] as String?) ?? '');

      notes.add(
        Note(
          id: generatedId,
          legacyId: legacyId,
          title: (m['title'] as String?) ?? '',
          body: (m['body'] as String?) ?? '',
          createdAt: createdAt,
          updatedAt: updatedAt,
          isPinned: (m['isPinned'] as bool?) ?? false,
          isLocked: (m['isLocked'] as bool?) ?? false,
          isDeleted: (m['isDeleted'] as bool?) ?? false,
          project: m['project'] as String?,
          noteDate: noteDate,
        ),
      );
    }

    // 4) 전체 교체 복원
    await db.replaceAllNotesFromBackup(notes);

    if (kDebugMode) {
      debugPrint('Import complete: notes=${notes.length}, encrypted=$encryptedFlag');
    }
  }

  /// id/legacyId 필드가 int/String 무엇이든 String?로 정규화
  String? _parseLegacyId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v.toString();
    if (v is num) return v.toInt().toString();
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    return v.toString();
  }

  // =========================================================
  // Encryption helpers: AES-256-GCM + PBKDF2(HMAC-SHA256)
  // =========================================================

  Map<String, dynamic> _encryptToContainerJson(String plainJson, String password) {
    final salt = _randomBytes(_kSaltLen);
    final nonce = _randomBytes(_kNonceLen);

    final keyBytes = _pbkdf2HmacSha256(
      password: password,
      salt: salt,
      iterations: _kPbkdf2Iter,
      dkLen: 32, // AES-256
    );

    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt.IV(Uint8List.fromList(nonce));

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encrypt(plainJson, iv: iv);

    return <String, dynamic>{
      'version': 2,
      'ts': DateTime.now().toIso8601String(),
      'encrypted': true,
      'alg': 'AES-256-GCM',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iter': _kPbkdf2Iter,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': encrypted.base64,
    };
  }

  String _decryptContainerToPlainJson(Map<String, dynamic> container, String password) {
    final iter = (container['iter'] as num?)?.toInt() ?? _kPbkdf2Iter;

    final saltB64 = container['salt'] as String?;
    final nonceB64 = container['nonce'] as String?;
    final cipherB64 = container['ciphertext'] as String?;

    if (saltB64 == null || nonceB64 == null || cipherB64 == null) {
      throw Exception('암호화 백업 필수 필드(salt/nonce/ciphertext)가 없습니다.');
    }

    final salt = base64Decode(saltB64);
    final nonce = base64Decode(nonceB64);

    final keyBytes = _pbkdf2HmacSha256(
      password: password,
      salt: salt,
      iterations: iter,
      dkLen: 32,
    );

    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt.IV(Uint8List.fromList(nonce));

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    try {
      return encrypter.decrypt64(cipherB64, iv: iv);
    } catch (_) {
      throw Exception('비밀번호가 올바르지 않거나 백업이 손상되었습니다.');
    }
  }

  List<int> _randomBytes(int len) {
    final r = Random.secure();
    return List<int>.generate(len, (_) => r.nextInt(256), growable: false);
  }

  /// PBKDF2-HMAC-SHA256 (간단 구현)
  List<int> _pbkdf2HmacSha256({
    required String password,
    required List<int> salt,
    required int iterations,
    required int dkLen,
  }) {
    final pwBytes = utf8.encode(password);
    final hLen = 32; // sha256 output
    final l = (dkLen / hLen).ceil();

    final out = BytesBuilder(copy: false);

    for (var i = 1; i <= l; i++) {
      final block = _pbkdf2Block(pwBytes, salt, iterations, i);
      out.add(block);
    }

    final dk = out.toBytes();
    return dk.sublist(0, dkLen);
  }

  List<int> _pbkdf2Block(List<int> pw, List<int> salt, int iter, int blockIndex) {
    // U1 = PRF(P, S || INT_32_BE(i))
    final si = BytesBuilder(copy: false)
      ..add(salt)
      ..add(_int32be(blockIndex));
    var u = _hmacSha256(pw, si.toBytes());
    final t = List<int>.from(u);

    for (var j = 2; j <= iter; j++) {
      u = _hmacSha256(pw, u);
      for (var k = 0; k < t.length; k++) {
        t[k] ^= u[k];
      }
    }
    return t;
  }

  List<int> _hmacSha256(List<int> key, List<int> msg) {
    final h = crypto.Hmac(crypto.sha256, key);
    return h.convert(msg).bytes;
  }

  List<int> _int32be(int i) => <int>[
        (i >> 24) & 0xff,
        (i >> 16) & 0xff,
        (i >> 8) & 0xff,
        i & 0xff,
      ];
}