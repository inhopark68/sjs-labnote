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

  ReagentDraft copyWith({
    String? name,
    String? company,
    String? catalogNumber,
    String? lotNumber,
    String? memo,
  }) {
    return ReagentDraft(
      name: name ?? this.name,
      company: company ?? this.company,
      catalogNumber: catalogNumber ?? this.catalogNumber,
      lotNumber: lotNumber ?? this.lotNumber,
      memo: memo ?? this.memo,
    );
  }
}