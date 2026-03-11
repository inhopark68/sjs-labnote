import 'package:flutter/material.dart';

class ResearchTitleField extends StatelessWidget {
  const ResearchTitleField({
    super.key,
    required this.controller,
    required this.ocrSupported,
    required this.runOcrAndReturnText,
    this.label = '연구제목',
    this.hintText = '연구제목을 입력하세요',
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool ocrSupported;
  final Future<String?> Function() runOcrAndReturnText;
  final String label;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  static List<String> _extractCandidates(String rawText) {
    return rawText
        .split('\n')
        .map((e) => e.trim())
        .map((e) => e.replaceAll(RegExp(r'\s+'), ' '))
        .where((e) => e.isNotEmpty)
        .where((e) => e.length >= 2)
        .toSet()
        .toList();
  }

  static Future<String?> _showTitleOcrPicker(
    BuildContext context,
    String rawText,
  ) async {
    final candidates = _extractCandidates(rawText);

    if (candidates.isEmpty) return null;

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('연구제목으로 넣을 문장을 선택하세요'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: candidates.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final text = candidates[index];
                return ListTile(
                  title: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(context, text),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleOcr(BuildContext context) async {
    if (!ocrSupported || !enabled) return;

    final rawText = await runOcrAndReturnText();
    if (rawText == null || rawText.trim().isEmpty) return;

    if (!context.mounted) return;

    final selected = await _showTitleOcrPicker(context, rawText);
    if (selected == null || selected.trim().isEmpty) return;

    final titleText = selected.replaceAll('\n', ' ').trim();

    controller.text = titleText;
    controller.selection = TextSelection.collapsed(
      offset: titleText.length,
    );

    onChanged?.call(titleText);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          maxLines: 1,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: ocrSupported
                ? IconButton(
                    tooltip: 'OCR로 제목 입력',
                    icon: const Icon(Icons.text_snippet_outlined),
                    onPressed: () => _handleOcr(context),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}