class ReagentDraft {
  final String name;
  final String? company;
  final String? catalogNumber;
  final String? lotNumber;
  final String? memo;

  const ReagentDraft({
    required this.name,
    this.company,
    this.catalogNumber,
    this.lotNumber,
    this.memo,
  });
}