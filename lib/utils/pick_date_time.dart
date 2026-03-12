import 'package:flutter/material.dart';

Future<DateTime?> pickDateTime(
  BuildContext context, {
  DateTime? initialDateTime,
}) async {
  final now = DateTime.now();

  bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  late final DateTime base;

  if (initialDateTime == null) {
    base = now;
  } else {
    final isMidnight = initialDateTime.hour == 0 &&
        initialDateTime.minute == 0 &&
        initialDateTime.second == 0;

    if (sameDay(initialDateTime, now) && isMidnight) {
      base = DateTime(
        initialDateTime.year,
        initialDateTime.month,
        initialDateTime.day,
        now.hour,
        now.minute,
        now.second,
      );
    } else {
      base = initialDateTime;
    }
  }

  final date = await showDatePicker(
    context: context,
    initialDate: base,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (date == null) return null;
  if (!context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(base),
  );

  if (time == null) return null;

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
    base.second,
  );
}