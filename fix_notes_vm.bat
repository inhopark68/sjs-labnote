@echo off
REM ============================
REM 1️⃣ 임시 저장 (선택)
REM ============================
git stash push -m "WIP: notes_vm fix"

REM ============================
REM 2️⃣ 충돌 파일 정리
REM lib/viewmodels/notes_vm.dart 내용을 고정 버전으로 덮어쓰기
REM ============================
echo Fixing notes_vm.dart...
(
echo import 'dart:async';
echo import 'package:flutter/foundation.dart';
echo import '../data/app_database.dart;';
echo.
echo class NoteListItem {
echo.  final String id;
echo.  final String title;
echo.  final String body;
echo.  final bool isPinned;
echo.  final DateTime updatedAt;
echo.
echo.  NoteListItem({
echo.    required this.id,
echo.    required this.title,
echo.    required this.body,
echo.    required this.isPinned,
echo.    required this.updatedAt,
echo.  });
echo.
echo.  factory NoteListItem.fromNote(Note n) => NoteListItem(
echo.    id: n.id,
echo.    title: n.title,
echo.    body: n.body,
echo.    isPinned: n.isPinned,
echo.    updatedAt: n.updatedAt,
echo.  );
echo.
echo.  String get bodyPreview {
echo.    final s = body.replaceAll('\n', ' ').trim();
echo.    return s.length <= 80 ? s : '%s'.substring(0,80) + '…';
echo.  }
echo }
) > lib\viewmodels\notes_vm.dart

REM ============================
REM 3️⃣ Git에 추가 및 커밋
REM ============================
git add lib/viewmodels/notes_vm.dart
git add .gitignore
git add .

git commit -m "Fix notes_vm: initialize final fields and provide bodyPreview"

REM ============================
REM 4️⃣ Flutter 빌드
REM ============================
flutter clean
flutter pub get
flutter build windows

REM ============================
REM 5️⃣ stash 복원 (필요시)
REM ============================
git stash pop