// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DbNotesTable extends DbNotes with TableInfo<$DbNotesTable, DbNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _legacyIdMeta =
      const VerificationMeta('legacyId');
  @override
  late final GeneratedColumn<String> legacyId = GeneratedColumn<String>(
      'legacy_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteDateMeta =
      const VerificationMeta('noteDate');
  @override
  late final GeneratedColumn<DateTime> noteDate = GeneratedColumn<DateTime>(
      'note_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isLockedMeta =
      const VerificationMeta('isLocked');
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
      'is_locked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_locked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _projectMeta =
      const VerificationMeta('project');
  @override
  late final GeneratedColumn<String> project = GeneratedColumn<String>(
      'project', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        legacyId,
        noteDate,
        title,
        body,
        createdAt,
        updatedAt,
        isPinned,
        isLocked,
        isDeleted,
        project
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_notes';
  @override
  VerificationContext validateIntegrity(Insertable<DbNote> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('legacy_id')) {
      context.handle(_legacyIdMeta,
          legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta));
    }
    if (data.containsKey('note_date')) {
      context.handle(_noteDateMeta,
          noteDate.isAcceptableOrUnknown(data['note_date']!, _noteDateMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('is_locked')) {
      context.handle(_isLockedMeta,
          isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('project')) {
      context.handle(_projectMeta,
          project.isAcceptableOrUnknown(data['project']!, _projectMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbNote(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      legacyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}legacy_id']),
      noteDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}note_date']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      isLocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_locked'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      project: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project']),
    );
  }

  @override
  $DbNotesTable createAlias(String alias) {
    return $DbNotesTable(attachedDatabase, alias);
  }
}

class DbNote extends DataClass implements Insertable<DbNote> {
  final int id;

  /// 구버전 text id 저장
  final String? legacyId;
  final DateTime? noteDate;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isLocked;
  final bool isDeleted;
  final String? project;
  const DbNote(
      {required this.id,
      this.legacyId,
      this.noteDate,
      required this.title,
      required this.body,
      required this.createdAt,
      required this.updatedAt,
      required this.isPinned,
      required this.isLocked,
      required this.isDeleted,
      this.project});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || legacyId != null) {
      map['legacy_id'] = Variable<String>(legacyId);
    }
    if (!nullToAbsent || noteDate != null) {
      map['note_date'] = Variable<DateTime>(noteDate);
    }
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_locked'] = Variable<bool>(isLocked);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || project != null) {
      map['project'] = Variable<String>(project);
    }
    return map;
  }

  DbNotesCompanion toCompanion(bool nullToAbsent) {
    return DbNotesCompanion(
      id: Value(id),
      legacyId: legacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyId),
      noteDate: noteDate == null && nullToAbsent
          ? const Value.absent()
          : Value(noteDate),
      title: Value(title),
      body: Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isPinned: Value(isPinned),
      isLocked: Value(isLocked),
      isDeleted: Value(isDeleted),
      project: project == null && nullToAbsent
          ? const Value.absent()
          : Value(project),
    );
  }

  factory DbNote.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbNote(
      id: serializer.fromJson<int>(json['id']),
      legacyId: serializer.fromJson<String?>(json['legacyId']),
      noteDate: serializer.fromJson<DateTime?>(json['noteDate']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      project: serializer.fromJson<String?>(json['project']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'legacyId': serializer.toJson<String?>(legacyId),
      'noteDate': serializer.toJson<DateTime?>(noteDate),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isLocked': serializer.toJson<bool>(isLocked),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'project': serializer.toJson<String?>(project),
    };
  }

  DbNote copyWith(
          {int? id,
          Value<String?> legacyId = const Value.absent(),
          Value<DateTime?> noteDate = const Value.absent(),
          String? title,
          String? body,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? isPinned,
          bool? isLocked,
          bool? isDeleted,
          Value<String?> project = const Value.absent()}) =>
      DbNote(
        id: id ?? this.id,
        legacyId: legacyId.present ? legacyId.value : this.legacyId,
        noteDate: noteDate.present ? noteDate.value : this.noteDate,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isPinned: isPinned ?? this.isPinned,
        isLocked: isLocked ?? this.isLocked,
        isDeleted: isDeleted ?? this.isDeleted,
        project: project.present ? project.value : this.project,
      );
  DbNote copyWithCompanion(DbNotesCompanion data) {
    return DbNote(
      id: data.id.present ? data.id.value : this.id,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
      noteDate: data.noteDate.present ? data.noteDate.value : this.noteDate,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      project: data.project.present ? data.project.value : this.project,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbNote(')
          ..write('id: $id, ')
          ..write('legacyId: $legacyId, ')
          ..write('noteDate: $noteDate, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPinned: $isPinned, ')
          ..write('isLocked: $isLocked, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('project: $project')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, legacyId, noteDate, title, body,
      createdAt, updatedAt, isPinned, isLocked, isDeleted, project);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbNote &&
          other.id == this.id &&
          other.legacyId == this.legacyId &&
          other.noteDate == this.noteDate &&
          other.title == this.title &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isPinned == this.isPinned &&
          other.isLocked == this.isLocked &&
          other.isDeleted == this.isDeleted &&
          other.project == this.project);
}

class DbNotesCompanion extends UpdateCompanion<DbNote> {
  final Value<int> id;
  final Value<String?> legacyId;
  final Value<DateTime?> noteDate;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isPinned;
  final Value<bool> isLocked;
  final Value<bool> isDeleted;
  final Value<String?> project;
  const DbNotesCompanion({
    this.id = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.noteDate = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.project = const Value.absent(),
  });
  DbNotesCompanion.insert({
    this.id = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.noteDate = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.project = const Value.absent(),
  });
  static Insertable<DbNote> custom({
    Expression<int>? id,
    Expression<String>? legacyId,
    Expression<DateTime>? noteDate,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isPinned,
    Expression<bool>? isLocked,
    Expression<bool>? isDeleted,
    Expression<String>? project,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (legacyId != null) 'legacy_id': legacyId,
      if (noteDate != null) 'note_date': noteDate,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isLocked != null) 'is_locked': isLocked,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (project != null) 'project': project,
    });
  }

  DbNotesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? legacyId,
      Value<DateTime?>? noteDate,
      Value<String>? title,
      Value<String>? body,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isPinned,
      Value<bool>? isLocked,
      Value<bool>? isDeleted,
      Value<String?>? project}) {
    return DbNotesCompanion(
      id: id ?? this.id,
      legacyId: legacyId ?? this.legacyId,
      noteDate: noteDate ?? this.noteDate,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      isDeleted: isDeleted ?? this.isDeleted,
      project: project ?? this.project,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<String>(legacyId.value);
    }
    if (noteDate.present) {
      map['note_date'] = Variable<DateTime>(noteDate.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (project.present) {
      map['project'] = Variable<String>(project.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbNotesCompanion(')
          ..write('id: $id, ')
          ..write('legacyId: $legacyId, ')
          ..write('noteDate: $noteDate, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPinned: $isPinned, ')
          ..write('isLocked: $isLocked, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('project: $project')
          ..write(')'))
        .toString();
  }
}

class $DbNoteReagentsTable extends DbNoteReagents
    with TableInfo<$DbNoteReagentsTable, DbNoteReagent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbNoteReagentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
      'note_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _catalogNumberMeta =
      const VerificationMeta('catalogNumber');
  @override
  late final GeneratedColumn<String> catalogNumber = GeneratedColumn<String>(
      'catalog_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lotNumberMeta =
      const VerificationMeta('lotNumber');
  @override
  late final GeneratedColumn<String> lotNumber = GeneratedColumn<String>(
      'lot_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyMeta =
      const VerificationMeta('company');
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
      'company', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, noteId, name, catalogNumber, lotNumber, company, memo, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_note_reagents';
  @override
  VerificationContext validateIntegrity(Insertable<DbNoteReagent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('catalog_number')) {
      context.handle(
          _catalogNumberMeta,
          catalogNumber.isAcceptableOrUnknown(
              data['catalog_number']!, _catalogNumberMeta));
    }
    if (data.containsKey('lot_number')) {
      context.handle(_lotNumberMeta,
          lotNumber.isAcceptableOrUnknown(data['lot_number']!, _lotNumberMeta));
    }
    if (data.containsKey('company')) {
      context.handle(_companyMeta,
          company.isAcceptableOrUnknown(data['company']!, _companyMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbNoteReagent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbNoteReagent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}note_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      catalogNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}catalog_number']),
      lotNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lot_number']),
      company: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company']),
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DbNoteReagentsTable createAlias(String alias) {
    return $DbNoteReagentsTable(attachedDatabase, alias);
  }
}

class DbNoteReagent extends DataClass implements Insertable<DbNoteReagent> {
  final String id;
  final int noteId;
  final String name;
  final String? catalogNumber;
  final String? lotNumber;
  final String? company;
  final String? memo;
  final DateTime createdAt;
  const DbNoteReagent(
      {required this.id,
      required this.noteId,
      required this.name,
      this.catalogNumber,
      this.lotNumber,
      this.company,
      this.memo,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<int>(noteId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || catalogNumber != null) {
      map['catalog_number'] = Variable<String>(catalogNumber);
    }
    if (!nullToAbsent || lotNumber != null) {
      map['lot_number'] = Variable<String>(lotNumber);
    }
    if (!nullToAbsent || company != null) {
      map['company'] = Variable<String>(company);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbNoteReagentsCompanion toCompanion(bool nullToAbsent) {
    return DbNoteReagentsCompanion(
      id: Value(id),
      noteId: Value(noteId),
      name: Value(name),
      catalogNumber: catalogNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogNumber),
      lotNumber: lotNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(lotNumber),
      company: company == null && nullToAbsent
          ? const Value.absent()
          : Value(company),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
    );
  }

  factory DbNoteReagent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbNoteReagent(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<int>(json['noteId']),
      name: serializer.fromJson<String>(json['name']),
      catalogNumber: serializer.fromJson<String?>(json['catalogNumber']),
      lotNumber: serializer.fromJson<String?>(json['lotNumber']),
      company: serializer.fromJson<String?>(json['company']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<int>(noteId),
      'name': serializer.toJson<String>(name),
      'catalogNumber': serializer.toJson<String?>(catalogNumber),
      'lotNumber': serializer.toJson<String?>(lotNumber),
      'company': serializer.toJson<String?>(company),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbNoteReagent copyWith(
          {String? id,
          int? noteId,
          String? name,
          Value<String?> catalogNumber = const Value.absent(),
          Value<String?> lotNumber = const Value.absent(),
          Value<String?> company = const Value.absent(),
          Value<String?> memo = const Value.absent(),
          DateTime? createdAt}) =>
      DbNoteReagent(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        name: name ?? this.name,
        catalogNumber:
            catalogNumber.present ? catalogNumber.value : this.catalogNumber,
        lotNumber: lotNumber.present ? lotNumber.value : this.lotNumber,
        company: company.present ? company.value : this.company,
        memo: memo.present ? memo.value : this.memo,
        createdAt: createdAt ?? this.createdAt,
      );
  DbNoteReagent copyWithCompanion(DbNoteReagentsCompanion data) {
    return DbNoteReagent(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      name: data.name.present ? data.name.value : this.name,
      catalogNumber: data.catalogNumber.present
          ? data.catalogNumber.value
          : this.catalogNumber,
      lotNumber: data.lotNumber.present ? data.lotNumber.value : this.lotNumber,
      company: data.company.present ? data.company.value : this.company,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbNoteReagent(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('name: $name, ')
          ..write('catalogNumber: $catalogNumber, ')
          ..write('lotNumber: $lotNumber, ')
          ..write('company: $company, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, noteId, name, catalogNumber, lotNumber, company, memo, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbNoteReagent &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.name == this.name &&
          other.catalogNumber == this.catalogNumber &&
          other.lotNumber == this.lotNumber &&
          other.company == this.company &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt);
}

class DbNoteReagentsCompanion extends UpdateCompanion<DbNoteReagent> {
  final Value<String> id;
  final Value<int> noteId;
  final Value<String> name;
  final Value<String?> catalogNumber;
  final Value<String?> lotNumber;
  final Value<String?> company;
  final Value<String?> memo;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DbNoteReagentsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.name = const Value.absent(),
    this.catalogNumber = const Value.absent(),
    this.lotNumber = const Value.absent(),
    this.company = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbNoteReagentsCompanion.insert({
    required String id,
    required int noteId,
    required String name,
    this.catalogNumber = const Value.absent(),
    this.lotNumber = const Value.absent(),
    this.company = const Value.absent(),
    this.memo = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        noteId = Value(noteId),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<DbNoteReagent> custom({
    Expression<String>? id,
    Expression<int>? noteId,
    Expression<String>? name,
    Expression<String>? catalogNumber,
    Expression<String>? lotNumber,
    Expression<String>? company,
    Expression<String>? memo,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (name != null) 'name': name,
      if (catalogNumber != null) 'catalog_number': catalogNumber,
      if (lotNumber != null) 'lot_number': lotNumber,
      if (company != null) 'company': company,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbNoteReagentsCompanion copyWith(
      {Value<String>? id,
      Value<int>? noteId,
      Value<String>? name,
      Value<String?>? catalogNumber,
      Value<String?>? lotNumber,
      Value<String?>? company,
      Value<String?>? memo,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DbNoteReagentsCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      name: name ?? this.name,
      catalogNumber: catalogNumber ?? this.catalogNumber,
      lotNumber: lotNumber ?? this.lotNumber,
      company: company ?? this.company,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (catalogNumber.present) {
      map['catalog_number'] = Variable<String>(catalogNumber.value);
    }
    if (lotNumber.present) {
      map['lot_number'] = Variable<String>(lotNumber.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbNoteReagentsCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('name: $name, ')
          ..write('catalogNumber: $catalogNumber, ')
          ..write('lotNumber: $lotNumber, ')
          ..write('company: $company, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbNoteMaterialsTable extends DbNoteMaterials
    with TableInfo<$DbNoteMaterialsTable, DbNoteMaterial> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbNoteMaterialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
      'note_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _catalogNumberMeta =
      const VerificationMeta('catalogNumber');
  @override
  late final GeneratedColumn<String> catalogNumber = GeneratedColumn<String>(
      'catalog_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lotNumberMeta =
      const VerificationMeta('lotNumber');
  @override
  late final GeneratedColumn<String> lotNumber = GeneratedColumn<String>(
      'lot_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyMeta =
      const VerificationMeta('company');
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
      'company', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, noteId, name, catalogNumber, lotNumber, company, memo, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_note_materials';
  @override
  VerificationContext validateIntegrity(Insertable<DbNoteMaterial> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('catalog_number')) {
      context.handle(
          _catalogNumberMeta,
          catalogNumber.isAcceptableOrUnknown(
              data['catalog_number']!, _catalogNumberMeta));
    }
    if (data.containsKey('lot_number')) {
      context.handle(_lotNumberMeta,
          lotNumber.isAcceptableOrUnknown(data['lot_number']!, _lotNumberMeta));
    }
    if (data.containsKey('company')) {
      context.handle(_companyMeta,
          company.isAcceptableOrUnknown(data['company']!, _companyMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbNoteMaterial map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbNoteMaterial(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}note_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      catalogNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}catalog_number']),
      lotNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lot_number']),
      company: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company']),
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DbNoteMaterialsTable createAlias(String alias) {
    return $DbNoteMaterialsTable(attachedDatabase, alias);
  }
}

class DbNoteMaterial extends DataClass implements Insertable<DbNoteMaterial> {
  final String id;
  final int noteId;
  final String name;
  final String? catalogNumber;
  final String? lotNumber;
  final String? company;
  final String? memo;
  final DateTime createdAt;
  const DbNoteMaterial(
      {required this.id,
      required this.noteId,
      required this.name,
      this.catalogNumber,
      this.lotNumber,
      this.company,
      this.memo,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<int>(noteId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || catalogNumber != null) {
      map['catalog_number'] = Variable<String>(catalogNumber);
    }
    if (!nullToAbsent || lotNumber != null) {
      map['lot_number'] = Variable<String>(lotNumber);
    }
    if (!nullToAbsent || company != null) {
      map['company'] = Variable<String>(company);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbNoteMaterialsCompanion toCompanion(bool nullToAbsent) {
    return DbNoteMaterialsCompanion(
      id: Value(id),
      noteId: Value(noteId),
      name: Value(name),
      catalogNumber: catalogNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogNumber),
      lotNumber: lotNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(lotNumber),
      company: company == null && nullToAbsent
          ? const Value.absent()
          : Value(company),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
    );
  }

  factory DbNoteMaterial.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbNoteMaterial(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<int>(json['noteId']),
      name: serializer.fromJson<String>(json['name']),
      catalogNumber: serializer.fromJson<String?>(json['catalogNumber']),
      lotNumber: serializer.fromJson<String?>(json['lotNumber']),
      company: serializer.fromJson<String?>(json['company']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<int>(noteId),
      'name': serializer.toJson<String>(name),
      'catalogNumber': serializer.toJson<String?>(catalogNumber),
      'lotNumber': serializer.toJson<String?>(lotNumber),
      'company': serializer.toJson<String?>(company),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbNoteMaterial copyWith(
          {String? id,
          int? noteId,
          String? name,
          Value<String?> catalogNumber = const Value.absent(),
          Value<String?> lotNumber = const Value.absent(),
          Value<String?> company = const Value.absent(),
          Value<String?> memo = const Value.absent(),
          DateTime? createdAt}) =>
      DbNoteMaterial(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        name: name ?? this.name,
        catalogNumber:
            catalogNumber.present ? catalogNumber.value : this.catalogNumber,
        lotNumber: lotNumber.present ? lotNumber.value : this.lotNumber,
        company: company.present ? company.value : this.company,
        memo: memo.present ? memo.value : this.memo,
        createdAt: createdAt ?? this.createdAt,
      );
  DbNoteMaterial copyWithCompanion(DbNoteMaterialsCompanion data) {
    return DbNoteMaterial(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      name: data.name.present ? data.name.value : this.name,
      catalogNumber: data.catalogNumber.present
          ? data.catalogNumber.value
          : this.catalogNumber,
      lotNumber: data.lotNumber.present ? data.lotNumber.value : this.lotNumber,
      company: data.company.present ? data.company.value : this.company,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbNoteMaterial(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('name: $name, ')
          ..write('catalogNumber: $catalogNumber, ')
          ..write('lotNumber: $lotNumber, ')
          ..write('company: $company, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, noteId, name, catalogNumber, lotNumber, company, memo, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbNoteMaterial &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.name == this.name &&
          other.catalogNumber == this.catalogNumber &&
          other.lotNumber == this.lotNumber &&
          other.company == this.company &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt);
}

class DbNoteMaterialsCompanion extends UpdateCompanion<DbNoteMaterial> {
  final Value<String> id;
  final Value<int> noteId;
  final Value<String> name;
  final Value<String?> catalogNumber;
  final Value<String?> lotNumber;
  final Value<String?> company;
  final Value<String?> memo;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DbNoteMaterialsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.name = const Value.absent(),
    this.catalogNumber = const Value.absent(),
    this.lotNumber = const Value.absent(),
    this.company = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbNoteMaterialsCompanion.insert({
    required String id,
    required int noteId,
    required String name,
    this.catalogNumber = const Value.absent(),
    this.lotNumber = const Value.absent(),
    this.company = const Value.absent(),
    this.memo = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        noteId = Value(noteId),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<DbNoteMaterial> custom({
    Expression<String>? id,
    Expression<int>? noteId,
    Expression<String>? name,
    Expression<String>? catalogNumber,
    Expression<String>? lotNumber,
    Expression<String>? company,
    Expression<String>? memo,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (name != null) 'name': name,
      if (catalogNumber != null) 'catalog_number': catalogNumber,
      if (lotNumber != null) 'lot_number': lotNumber,
      if (company != null) 'company': company,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbNoteMaterialsCompanion copyWith(
      {Value<String>? id,
      Value<int>? noteId,
      Value<String>? name,
      Value<String?>? catalogNumber,
      Value<String?>? lotNumber,
      Value<String?>? company,
      Value<String?>? memo,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DbNoteMaterialsCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      name: name ?? this.name,
      catalogNumber: catalogNumber ?? this.catalogNumber,
      lotNumber: lotNumber ?? this.lotNumber,
      company: company ?? this.company,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (catalogNumber.present) {
      map['catalog_number'] = Variable<String>(catalogNumber.value);
    }
    if (lotNumber.present) {
      map['lot_number'] = Variable<String>(lotNumber.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbNoteMaterialsCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('name: $name, ')
          ..write('catalogNumber: $catalogNumber, ')
          ..write('lotNumber: $lotNumber, ')
          ..write('company: $company, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbNoteReferencesTable extends DbNoteReferences
    with TableInfo<$DbNoteReferencesTable, DbNoteReference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbNoteReferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
      'note_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _doiMeta = const VerificationMeta('doi');
  @override
  late final GeneratedColumn<String> doi = GeneratedColumn<String>(
      'doi', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, noteId, doi, memo, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_note_references';
  @override
  VerificationContext validateIntegrity(Insertable<DbNoteReference> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('doi')) {
      context.handle(
          _doiMeta, doi.isAcceptableOrUnknown(data['doi']!, _doiMeta));
    } else if (isInserting) {
      context.missing(_doiMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbNoteReference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbNoteReference(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}note_id'])!,
      doi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doi'])!,
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DbNoteReferencesTable createAlias(String alias) {
    return $DbNoteReferencesTable(attachedDatabase, alias);
  }
}

class DbNoteReference extends DataClass implements Insertable<DbNoteReference> {
  final String id;
  final int noteId;
  final String doi;
  final String? memo;
  final DateTime createdAt;
  const DbNoteReference(
      {required this.id,
      required this.noteId,
      required this.doi,
      this.memo,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<int>(noteId);
    map['doi'] = Variable<String>(doi);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbNoteReferencesCompanion toCompanion(bool nullToAbsent) {
    return DbNoteReferencesCompanion(
      id: Value(id),
      noteId: Value(noteId),
      doi: Value(doi),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
    );
  }

  factory DbNoteReference.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbNoteReference(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<int>(json['noteId']),
      doi: serializer.fromJson<String>(json['doi']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<int>(noteId),
      'doi': serializer.toJson<String>(doi),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbNoteReference copyWith(
          {String? id,
          int? noteId,
          String? doi,
          Value<String?> memo = const Value.absent(),
          DateTime? createdAt}) =>
      DbNoteReference(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        doi: doi ?? this.doi,
        memo: memo.present ? memo.value : this.memo,
        createdAt: createdAt ?? this.createdAt,
      );
  DbNoteReference copyWithCompanion(DbNoteReferencesCompanion data) {
    return DbNoteReference(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      doi: data.doi.present ? data.doi.value : this.doi,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbNoteReference(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('doi: $doi, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, noteId, doi, memo, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbNoteReference &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.doi == this.doi &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt);
}

class DbNoteReferencesCompanion extends UpdateCompanion<DbNoteReference> {
  final Value<String> id;
  final Value<int> noteId;
  final Value<String> doi;
  final Value<String?> memo;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DbNoteReferencesCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.doi = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbNoteReferencesCompanion.insert({
    required String id,
    required int noteId,
    required String doi,
    this.memo = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        noteId = Value(noteId),
        doi = Value(doi),
        createdAt = Value(createdAt);
  static Insertable<DbNoteReference> custom({
    Expression<String>? id,
    Expression<int>? noteId,
    Expression<String>? doi,
    Expression<String>? memo,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (doi != null) 'doi': doi,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbNoteReferencesCompanion copyWith(
      {Value<String>? id,
      Value<int>? noteId,
      Value<String>? doi,
      Value<String?>? memo,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DbNoteReferencesCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      doi: doi ?? this.doi,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (doi.present) {
      map['doi'] = Variable<String>(doi.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbNoteReferencesCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('doi: $doi, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DbNotesTable dbNotes = $DbNotesTable(this);
  late final $DbNoteReagentsTable dbNoteReagents = $DbNoteReagentsTable(this);
  late final $DbNoteMaterialsTable dbNoteMaterials =
      $DbNoteMaterialsTable(this);
  late final $DbNoteReferencesTable dbNoteReferences =
      $DbNoteReferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [dbNotes, dbNoteReagents, dbNoteMaterials, dbNoteReferences];
}

typedef $$DbNotesTableCreateCompanionBuilder = DbNotesCompanion Function({
  Value<int> id,
  Value<String?> legacyId,
  Value<DateTime?> noteDate,
  Value<String> title,
  Value<String> body,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isPinned,
  Value<bool> isLocked,
  Value<bool> isDeleted,
  Value<String?> project,
});
typedef $$DbNotesTableUpdateCompanionBuilder = DbNotesCompanion Function({
  Value<int> id,
  Value<String?> legacyId,
  Value<DateTime?> noteDate,
  Value<String> title,
  Value<String> body,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isPinned,
  Value<bool> isLocked,
  Value<bool> isDeleted,
  Value<String?> project,
});

class $$DbNotesTableFilterComposer
    extends Composer<_$AppDatabase, $DbNotesTable> {
  $$DbNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get legacyId => $composableBuilder(
      column: $table.legacyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get noteDate => $composableBuilder(
      column: $table.noteDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLocked => $composableBuilder(
      column: $table.isLocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get project => $composableBuilder(
      column: $table.project, builder: (column) => ColumnFilters(column));
}

class $$DbNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $DbNotesTable> {
  $$DbNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get legacyId => $composableBuilder(
      column: $table.legacyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get noteDate => $composableBuilder(
      column: $table.noteDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLocked => $composableBuilder(
      column: $table.isLocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get project => $composableBuilder(
      column: $table.project, builder: (column) => ColumnOrderings(column));
}

class $$DbNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbNotesTable> {
  $$DbNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get legacyId =>
      $composableBuilder(column: $table.legacyId, builder: (column) => column);

  GeneratedColumn<DateTime> get noteDate =>
      $composableBuilder(column: $table.noteDate, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get project =>
      $composableBuilder(column: $table.project, builder: (column) => column);
}

class $$DbNotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbNotesTable,
    DbNote,
    $$DbNotesTableFilterComposer,
    $$DbNotesTableOrderingComposer,
    $$DbNotesTableAnnotationComposer,
    $$DbNotesTableCreateCompanionBuilder,
    $$DbNotesTableUpdateCompanionBuilder,
    (DbNote, BaseReferences<_$AppDatabase, $DbNotesTable, DbNote>),
    DbNote,
    PrefetchHooks Function()> {
  $$DbNotesTableTableManager(_$AppDatabase db, $DbNotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> legacyId = const Value.absent(),
            Value<DateTime?> noteDate = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<bool> isLocked = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<String?> project = const Value.absent(),
          }) =>
              DbNotesCompanion(
            id: id,
            legacyId: legacyId,
            noteDate: noteDate,
            title: title,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isPinned: isPinned,
            isLocked: isLocked,
            isDeleted: isDeleted,
            project: project,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> legacyId = const Value.absent(),
            Value<DateTime?> noteDate = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<bool> isLocked = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<String?> project = const Value.absent(),
          }) =>
              DbNotesCompanion.insert(
            id: id,
            legacyId: legacyId,
            noteDate: noteDate,
            title: title,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isPinned: isPinned,
            isLocked: isLocked,
            isDeleted: isDeleted,
            project: project,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbNotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbNotesTable,
    DbNote,
    $$DbNotesTableFilterComposer,
    $$DbNotesTableOrderingComposer,
    $$DbNotesTableAnnotationComposer,
    $$DbNotesTableCreateCompanionBuilder,
    $$DbNotesTableUpdateCompanionBuilder,
    (DbNote, BaseReferences<_$AppDatabase, $DbNotesTable, DbNote>),
    DbNote,
    PrefetchHooks Function()>;
typedef $$DbNoteReagentsTableCreateCompanionBuilder = DbNoteReagentsCompanion
    Function({
  required String id,
  required int noteId,
  required String name,
  Value<String?> catalogNumber,
  Value<String?> lotNumber,
  Value<String?> company,
  Value<String?> memo,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DbNoteReagentsTableUpdateCompanionBuilder = DbNoteReagentsCompanion
    Function({
  Value<String> id,
  Value<int> noteId,
  Value<String> name,
  Value<String?> catalogNumber,
  Value<String?> lotNumber,
  Value<String?> company,
  Value<String?> memo,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DbNoteReagentsTableFilterComposer
    extends Composer<_$AppDatabase, $DbNoteReagentsTable> {
  $$DbNoteReagentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get catalogNumber => $composableBuilder(
      column: $table.catalogNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lotNumber => $composableBuilder(
      column: $table.lotNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DbNoteReagentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbNoteReagentsTable> {
  $$DbNoteReagentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get catalogNumber => $composableBuilder(
      column: $table.catalogNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lotNumber => $composableBuilder(
      column: $table.lotNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DbNoteReagentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbNoteReagentsTable> {
  $$DbNoteReagentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get catalogNumber => $composableBuilder(
      column: $table.catalogNumber, builder: (column) => column);

  GeneratedColumn<String> get lotNumber =>
      $composableBuilder(column: $table.lotNumber, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DbNoteReagentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbNoteReagentsTable,
    DbNoteReagent,
    $$DbNoteReagentsTableFilterComposer,
    $$DbNoteReagentsTableOrderingComposer,
    $$DbNoteReagentsTableAnnotationComposer,
    $$DbNoteReagentsTableCreateCompanionBuilder,
    $$DbNoteReagentsTableUpdateCompanionBuilder,
    (
      DbNoteReagent,
      BaseReferences<_$AppDatabase, $DbNoteReagentsTable, DbNoteReagent>
    ),
    DbNoteReagent,
    PrefetchHooks Function()> {
  $$DbNoteReagentsTableTableManager(
      _$AppDatabase db, $DbNoteReagentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbNoteReagentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbNoteReagentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbNoteReagentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> noteId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> catalogNumber = const Value.absent(),
            Value<String?> lotNumber = const Value.absent(),
            Value<String?> company = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbNoteReagentsCompanion(
            id: id,
            noteId: noteId,
            name: name,
            catalogNumber: catalogNumber,
            lotNumber: lotNumber,
            company: company,
            memo: memo,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int noteId,
            required String name,
            Value<String?> catalogNumber = const Value.absent(),
            Value<String?> lotNumber = const Value.absent(),
            Value<String?> company = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DbNoteReagentsCompanion.insert(
            id: id,
            noteId: noteId,
            name: name,
            catalogNumber: catalogNumber,
            lotNumber: lotNumber,
            company: company,
            memo: memo,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbNoteReagentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbNoteReagentsTable,
    DbNoteReagent,
    $$DbNoteReagentsTableFilterComposer,
    $$DbNoteReagentsTableOrderingComposer,
    $$DbNoteReagentsTableAnnotationComposer,
    $$DbNoteReagentsTableCreateCompanionBuilder,
    $$DbNoteReagentsTableUpdateCompanionBuilder,
    (
      DbNoteReagent,
      BaseReferences<_$AppDatabase, $DbNoteReagentsTable, DbNoteReagent>
    ),
    DbNoteReagent,
    PrefetchHooks Function()>;
typedef $$DbNoteMaterialsTableCreateCompanionBuilder = DbNoteMaterialsCompanion
    Function({
  required String id,
  required int noteId,
  required String name,
  Value<String?> catalogNumber,
  Value<String?> lotNumber,
  Value<String?> company,
  Value<String?> memo,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DbNoteMaterialsTableUpdateCompanionBuilder = DbNoteMaterialsCompanion
    Function({
  Value<String> id,
  Value<int> noteId,
  Value<String> name,
  Value<String?> catalogNumber,
  Value<String?> lotNumber,
  Value<String?> company,
  Value<String?> memo,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DbNoteMaterialsTableFilterComposer
    extends Composer<_$AppDatabase, $DbNoteMaterialsTable> {
  $$DbNoteMaterialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get catalogNumber => $composableBuilder(
      column: $table.catalogNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lotNumber => $composableBuilder(
      column: $table.lotNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DbNoteMaterialsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbNoteMaterialsTable> {
  $$DbNoteMaterialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get catalogNumber => $composableBuilder(
      column: $table.catalogNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lotNumber => $composableBuilder(
      column: $table.lotNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DbNoteMaterialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbNoteMaterialsTable> {
  $$DbNoteMaterialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get catalogNumber => $composableBuilder(
      column: $table.catalogNumber, builder: (column) => column);

  GeneratedColumn<String> get lotNumber =>
      $composableBuilder(column: $table.lotNumber, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DbNoteMaterialsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbNoteMaterialsTable,
    DbNoteMaterial,
    $$DbNoteMaterialsTableFilterComposer,
    $$DbNoteMaterialsTableOrderingComposer,
    $$DbNoteMaterialsTableAnnotationComposer,
    $$DbNoteMaterialsTableCreateCompanionBuilder,
    $$DbNoteMaterialsTableUpdateCompanionBuilder,
    (
      DbNoteMaterial,
      BaseReferences<_$AppDatabase, $DbNoteMaterialsTable, DbNoteMaterial>
    ),
    DbNoteMaterial,
    PrefetchHooks Function()> {
  $$DbNoteMaterialsTableTableManager(
      _$AppDatabase db, $DbNoteMaterialsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbNoteMaterialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbNoteMaterialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbNoteMaterialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> noteId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> catalogNumber = const Value.absent(),
            Value<String?> lotNumber = const Value.absent(),
            Value<String?> company = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbNoteMaterialsCompanion(
            id: id,
            noteId: noteId,
            name: name,
            catalogNumber: catalogNumber,
            lotNumber: lotNumber,
            company: company,
            memo: memo,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int noteId,
            required String name,
            Value<String?> catalogNumber = const Value.absent(),
            Value<String?> lotNumber = const Value.absent(),
            Value<String?> company = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DbNoteMaterialsCompanion.insert(
            id: id,
            noteId: noteId,
            name: name,
            catalogNumber: catalogNumber,
            lotNumber: lotNumber,
            company: company,
            memo: memo,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbNoteMaterialsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbNoteMaterialsTable,
    DbNoteMaterial,
    $$DbNoteMaterialsTableFilterComposer,
    $$DbNoteMaterialsTableOrderingComposer,
    $$DbNoteMaterialsTableAnnotationComposer,
    $$DbNoteMaterialsTableCreateCompanionBuilder,
    $$DbNoteMaterialsTableUpdateCompanionBuilder,
    (
      DbNoteMaterial,
      BaseReferences<_$AppDatabase, $DbNoteMaterialsTable, DbNoteMaterial>
    ),
    DbNoteMaterial,
    PrefetchHooks Function()>;
typedef $$DbNoteReferencesTableCreateCompanionBuilder
    = DbNoteReferencesCompanion Function({
  required String id,
  required int noteId,
  required String doi,
  Value<String?> memo,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DbNoteReferencesTableUpdateCompanionBuilder
    = DbNoteReferencesCompanion Function({
  Value<String> id,
  Value<int> noteId,
  Value<String> doi,
  Value<String?> memo,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DbNoteReferencesTableFilterComposer
    extends Composer<_$AppDatabase, $DbNoteReferencesTable> {
  $$DbNoteReferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get doi => $composableBuilder(
      column: $table.doi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DbNoteReferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $DbNoteReferencesTable> {
  $$DbNoteReferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get doi => $composableBuilder(
      column: $table.doi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DbNoteReferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbNoteReferencesTable> {
  $$DbNoteReferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get doi =>
      $composableBuilder(column: $table.doi, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DbNoteReferencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbNoteReferencesTable,
    DbNoteReference,
    $$DbNoteReferencesTableFilterComposer,
    $$DbNoteReferencesTableOrderingComposer,
    $$DbNoteReferencesTableAnnotationComposer,
    $$DbNoteReferencesTableCreateCompanionBuilder,
    $$DbNoteReferencesTableUpdateCompanionBuilder,
    (
      DbNoteReference,
      BaseReferences<_$AppDatabase, $DbNoteReferencesTable, DbNoteReference>
    ),
    DbNoteReference,
    PrefetchHooks Function()> {
  $$DbNoteReferencesTableTableManager(
      _$AppDatabase db, $DbNoteReferencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbNoteReferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbNoteReferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbNoteReferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> noteId = const Value.absent(),
            Value<String> doi = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbNoteReferencesCompanion(
            id: id,
            noteId: noteId,
            doi: doi,
            memo: memo,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int noteId,
            required String doi,
            Value<String?> memo = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DbNoteReferencesCompanion.insert(
            id: id,
            noteId: noteId,
            doi: doi,
            memo: memo,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbNoteReferencesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbNoteReferencesTable,
    DbNoteReference,
    $$DbNoteReferencesTableFilterComposer,
    $$DbNoteReferencesTableOrderingComposer,
    $$DbNoteReferencesTableAnnotationComposer,
    $$DbNoteReferencesTableCreateCompanionBuilder,
    $$DbNoteReferencesTableUpdateCompanionBuilder,
    (
      DbNoteReference,
      BaseReferences<_$AppDatabase, $DbNoteReferencesTable, DbNoteReference>
    ),
    DbNoteReference,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DbNotesTableTableManager get dbNotes =>
      $$DbNotesTableTableManager(_db, _db.dbNotes);
  $$DbNoteReagentsTableTableManager get dbNoteReagents =>
      $$DbNoteReagentsTableTableManager(_db, _db.dbNoteReagents);
  $$DbNoteMaterialsTableTableManager get dbNoteMaterials =>
      $$DbNoteMaterialsTableTableManager(_db, _db.dbNoteMaterials);
  $$DbNoteReferencesTableTableManager get dbNoteReferences =>
      $$DbNoteReferencesTableTableManager(_db, _db.dbNoteReferences);
}
