import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class NoteBodySection extends StatelessWidget {
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool enabled;
  final List<quill.EmbedBuilder> embedBuilders;
  final VoidCallback onInsertImage;
  final VoidCallback? onDeleteImage;

  const NoteBodySection({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.enabled,
    required this.embedBuilders,
    required this.onInsertImage,
    this.onDeleteImage,
  });

  Widget _editorHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '연구내용',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (onDeleteImage != null)
          IconButton(
            tooltip: '선택 이미지 삭제',
            onPressed: onDeleteImage,
            icon: const Icon(Icons.delete_outline),
          ),
        IconButton(
          tooltip: '이미지 삽입',
          onPressed: onInsertImage,
          icon: const Icon(Icons.add_photo_alternate),
        ),
      ],
    );
  }

  Widget _buildQuillEditor() {
    controller.readOnly = !enabled;

    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: quill.QuillEditor(
        controller: controller,
        focusNode: focusNode,
        scrollController: scrollController,
        config: quill.QuillEditorConfig(
          placeholder: '연구내용을 입력하세요',
          expands: false,
          padding: EdgeInsets.zero,
          embedBuilders: embedBuilders,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _editorHeader(context),
        _buildQuillEditor(),
      ],
    );
  }
}