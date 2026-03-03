import 'package:flutter/material.dart';
import 'package:labnote/models/attachment.dart';

class AttachmentsStrip extends StatelessWidget {
  final List<Attachment> items;
  final Future<void> Function()? onAddPhotoFromCamera;
  final Future<void> Function()? onAddPhotoFromGallery;
  final Future<void> Function(String attachmentId)? onDelete;

  const AttachmentsStrip({
    super.key,
    required this.items,
    this.onAddPhotoFromCamera,
    this.onAddPhotoFromGallery,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Attachments',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: '카메라',
              onPressed: onAddPhotoFromCamera == null
                  ? null
                  : () => onAddPhotoFromCamera!(),
              icon: const Icon(Icons.photo_camera),
            ),
            IconButton(
              tooltip: '갤러리',
              onPressed: onAddPhotoFromGallery == null
                  ? null
                  : () => onAddPhotoFromGallery!(),
              icon: const Icon(Icons.photo_library),
            ),
          ],
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('첨부파일이 없습니다.'),
          )
        else
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final a = items[i];
                return InputChip(
                  label: Text(
                    a.caption?.isNotEmpty == true ? a.caption! : a.type,
                  ),
                  onDeleted: onDelete == null ? null : () => onDelete!(a.id),
                );
              },
            ),
          ),
      ],
    );
  }
}
