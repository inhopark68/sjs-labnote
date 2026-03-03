import 'dart:convert';
<<<<<<< HEAD
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
=======
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt;
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3

import '../data/app_database.dart';
import 'backup_platform/backup_platform.dart';
import 'backup_service.dart';

class BackupServiceImpl implements BackupService {
<<<<<<< HEAD
  BackupServiceImpl(this.options, this.db);

  final BackupOptions options;
  final AppDatabase db;

  static const _formatVersion = 1;

  @override
  Future<Uint8List> exportZip() async {
    final rows = options.includeDeleted
        ? await db.allNoteRowsIncludingDeleted()
        : (await db.listNotes(query: '')).map((n) => _noteToRowLike(n)).toList();

    final notes = rows.map(_rowToJson).toList(growable: false);

    final notesJsonBytes = utf8.encode(jsonEncode({
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': notes,
    }));

    final checksum = sha256.convert(notesJsonBytes).toString();

    final manifestBytes = utf8.encode(jsonEncode({
      'formatVersion': _formatVersion,
      'file': 'notes.json',
      'sha256': checksum,
    }));

    final archive = Archive()
      ..addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes))
      ..addFile(ArchiveFile('notes.json', notesJsonBytes.length, notesJsonBytes));

    final zipped = ZipEncoder().encode(archive);
    if (zipped == null) {
      throw StateError('Failed to create zip');
    }
    return Uint8List.fromList(zipped);
  }

  @override
  Future<void> restoreZip(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final manifestFile = archive.files.firstWhere(
      (f) => f.name == 'manifest.json',
      orElse: () => throw StateError('manifest.json not found'),
    );
    final notesFile = archive.files.firstWhere(
      (f) => f.name == 'notes.json',
      orElse: () => throw StateError('notes.json not found'),
    );

    final manifest = jsonDecode(utf8.decode(manifestFile.content as List<int>))
        as Map<String, dynamic>;
    final expectedSha = manifest['sha256'] as String?;

    final notesBytes = Uint8List.fromList(notesFile.content as List<int>);
    final actualSha = sha256.convert(notesBytes).toString();

    if (expectedSha == null || expectedSha != actualSha) {
      throw StateError('Backup checksum mismatch (corrupted file)');
    }

    final payload =
        jsonDecode(utf8.decode(notesBytes)) as Map<String, dynamic>;
    final notesList = (payload['notes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final notes = notesList.map(_jsonToNote).toList(growable: false);

    // ✅ 전체 덮어쓰기 복원
    await db.replaceAllNotesFromBackup(notes);
  }

  // ----- JSON helpers -----

  Map<String, dynamic> _rowToJson(dynamic r) {
    // r이 DbNote일 수도, Note일 수도 있어서 아래처럼 공통 접근
    final id = (r is DbNote) ? r.id : (r as Note).id;
    final title = (r is DbNote) ? r.title : (r as Note).title;
    final body = (r is DbNote) ? r.body : (r as Note).body;
    final createdAt = (r is DbNote) ? r.createdAt : (r as Note).createdAt;
    final updatedAt = (r is DbNote) ? r.updatedAt : (r as Note).updatedAt;
    final isPinned = (r is DbNote) ? r.isPinned : (r as Note).isPinned;
    final isLocked = (r is DbNote) ? r.isLocked : (r as Note).isLocked;
    final isDeleted = (r is DbNote) ? r.isDeleted : (r as Note).isDeleted;
    final project = (r is DbNote) ? r.project : (r as Note).project;

    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'isLocked': isLocked,
      'isDeleted': isDeleted,
      'project': project,
    };
  }

  Note _jsonToNote(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        isPinned: (j['isPinned'] as bool?) ?? false,
        isLocked: (j['isLocked'] as bool?) ?? false,
        isDeleted: (j['isDeleted'] as bool?) ?? false,
        project: j['project'] as String?,
      );

  // listNotes가 Note를 주므로 includeDeleted=false일 때 rows로 맞추기용
  Note _noteToRowLike(Note n) => n;
}
=======
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
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
