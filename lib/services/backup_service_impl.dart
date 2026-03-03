import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt;

import '../data/app_database.dart';
import 'backup_platform/backup_platform.dart';
import 'backup_service.dart';

class BackupServiceImpl implements BackupService {
  final NotesRepository db;

  BackupServiceImpl(this.db);

  // -------------------------
  // DB <-> JSON (plain)
  // -------------------------

  @override
  Future<String> exportToJson() async {
    final notes = await db.listNotes(query: '');

    final data = notes
        .map(
          (n) => {
            'id': n.id,
            'title': n.title,
            'body': n.body,
            'createdAt': n.createdAt.toIso8601String(),
            'updatedAt': n.updatedAt.toIso8601String(),
            'isPinned': n.isPinned,
            'isLocked': n.isLocked,
            'isDeleted': n.isDeleted,
            'project': n.project,
          },
        )
        .toList(growable: false);

    return jsonEncode(data);
  }

  @override
  Future<void> importFromJson(String json) async {
    final decoded = jsonDecode(json) as List<dynamic>;

    final notes = decoded
        .map((e) {
          final m = e as Map<String, dynamic>;
          return Note(
            id: m['id'] as String,
            title: (m['title'] ?? '') as String,
            body: (m['body'] ?? '') as String,
            createdAt: DateTime.parse(m['createdAt'] as String),
            updatedAt: DateTime.parse(m['updatedAt'] as String),
            isPinned: (m['isPinned'] ?? false) as bool,
            isLocked: (m['isLocked'] ?? false) as bool,
            isDeleted: (m['isDeleted'] ?? false) as bool,
            project: m['project'] as String?,
          );
        })
        .toList(growable: false);

    await db.replaceAllNotesFromBackup(notes);
  }

  // -------------------------
  // Encryption helpers (AES-256-CBC)
  // -------------------------

  Uint8List _randomBytes(int len) {
    final r = Random.secure();
    return Uint8List.fromList(List<int>.generate(len, (_) => r.nextInt(256)));
  }

  Uint8List _deriveKey32(String password, Uint8List salt16) {
    // 간단 버전: key = SHA256(utf8(password) + salt)
    final pw = utf8.encode(password);
    final bytes = <int>[...pw, ...salt16];
    final digest = crypto.sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes); // 32 bytes
  }

  String _encryptJson(String plainJson, String password) {
    final salt = _randomBytes(16);
    final iv = _randomBytes(16);
    final key = _deriveKey32(password, salt);

    final aes = encrypt.AES(
      encrypt.Key(key),
      mode: encrypt.AESMode.cbc,
      padding: 'PKCS7',
    );

    final encrypter = encrypt.Encrypter(aes);
    final encrypted = encrypter.encrypt(plainJson, iv: encrypt.IV(iv));

    final wrapper = <String, dynamic>{
      'version': 2,
      'encrypted': true,
      'cipher': 'AES-256-CBC',
      'salt': base64Encode(salt),
      'iv': base64Encode(iv),
      'data': encrypted.base64,
    };

    return jsonEncode(wrapper);
  }

  String _decryptJson(String wrappedJson, String password) {
    final obj = jsonDecode(wrappedJson);

    if (obj is! Map<String, dynamic> || obj['encrypted'] != true) {
      return wrappedJson; // 평문 백업
    }

    final salt = base64Decode(obj['salt'] as String);
    final iv = base64Decode(obj['iv'] as String);
    final dataB64 = obj['data'] as String;

    final key = _deriveKey32(password, Uint8List.fromList(salt));

    final aes = encrypt.AES(
      encrypt.Key(key),
      mode: encrypt.AESMode.cbc,
      padding: 'PKCS7',
    );

    final encrypter = encrypt.Encrypter(aes);

    try {
      return encrypter.decrypt64(
        dataB64,
        iv: encrypt.IV(Uint8List.fromList(iv)),
      );
    } catch (_) {
      throw StateError('비밀번호가 올바르지 않거나 백업 파일이 손상되었습니다.');
    }
  }

  // -------------------------
  // Platform I/O
  // -------------------------

  @override
  Future<void> exportBackup({String? password}) async {
    final plain = await exportToJson();
    final payload = (password != null && password.isNotEmpty)
        ? _encryptJson(plain, password)
        : plain;

    await BackupPlatform.exportJson(payload);
  }

  @override
  Future<String?> pickRawBackupText() async {
    return BackupPlatform.pickJsonText();
  }

  @override
  Future<void> importRawBackupText(String raw, {String? password}) async {
    final decoded = jsonDecode(raw);
    final isEncrypted =
        decoded is Map<String, dynamic> && decoded['encrypted'] == true;

    if (isEncrypted) {
      if (password == null || password.isEmpty) {
        throw StateError('암호화된 백업입니다. 비밀번호가 필요합니다.');
      }
      final plain = _decryptJson(raw, password);
      await importFromJson(plain);
      return;
    }

    await importFromJson(raw);
  }

  // -------------------------
  // Product-grade: PRE-RESTORE + always encrypted
  // -------------------------

  @override
  Future<void> safeImportWithPreBackup({
    required String rawBackupText,
    required String preBackupPassword,
    String? importPassword,
  }) async {
    // 1) 현재 데이터 자동 백업 (항상 암호화)
    final plain = await exportToJson();
    final encryptedPre = _encryptJson(plain, preBackupPassword);

    // 2) 파일명 PRE-RESTORE 접두어
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'PRE-RESTORE_labnote-backup-$ts.json';

    await BackupPlatform.exportJson(encryptedPre, fileNameOverride: fileName);

    // 3) 선택한 백업 복원
    await importRawBackupText(rawBackupText, password: importPassword);
  }
}