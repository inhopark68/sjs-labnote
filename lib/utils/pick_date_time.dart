import 'package:flutter/material.dart';

Future<DateTime?> pickDateTime(
  BuildContext context, {
  DateTime? initialDateTime,
}) async {
  final base = initialDateTime ?? DateTime.now();

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