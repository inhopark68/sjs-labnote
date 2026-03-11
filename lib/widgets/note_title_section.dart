import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class NoteTitleSection extends StatelessWidget {
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool enabled;

  const NoteTitleSection({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    controller.readOnly = !enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '연구제목',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: quill.QuillEditor(
            controller: controller,
            focusNode: focusNode,
            scrollController: scrollController,
            config: const quill.QuillEditorConfig(
              placeholder: '연구제목을 입력하세요',
              expands: false,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}