import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dao/note_dao.dart';
import '../../repositories/reagent_repository_drift.dart';
import '../../services/attachment_storage.dart';
import '../../services/image_compressor.dart';

import 'note_sheet_vm.dart';

class NoteSheet extends StatelessWidget {
  const NoteSheet({super.key, this.noteId});

  final String? noteId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NoteSheetVm>(
      create: (ctx) => NoteSheetVm(
        ctx.read<NoteDao>(),
        ctx.read<AttachmentStorage>(),
        ctx.read<ImageCompressor>(),
        ctx.read<ReagentRepositoryDrift>(),
      )..init(noteId: noteId),
      child: const _NoteSheetBody(),
    );
  }
}

class _NoteSheetBody extends StatelessWidget {
  const _NoteSheetBody();

  void _toast(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NoteSheetVm>();

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '노트',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            if (vm.loading) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: vm.canEdit
                      ? () async {
                          try {
                            await vm.addPhotoFromCamera(
                              context,
                            ); // ✅ context 전달
                          } catch (e) {
                            _toast(context, e);
                          }
                        }
                      : null,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('카메라'),
                ),
                FilledButton.icon(
                  onPressed: vm.canEdit
                      ? () async {
                          try {
                            await vm.addPhotoFromGallery();
                          } catch (e) {
                            _toast(context, e);
                          }
                        }
                      : null,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('갤러리'),
                ),
                FilledButton.tonalIcon(
                  onPressed: vm.canEdit
                      ? () async {
                          try {
                            await vm.openOcrLabelFlowContinuous(context);
                          } catch (e) {
                            _toast(context, e);
                          }
                        }
                      : null,
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('라벨 OCR'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (vm.attachments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('첨부가 없습니다.'),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: vm.attachments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final a = vm.attachments[i];
                    return ListTile(
                      leading: const Icon(Icons.attachment),
                      title: Text(
                        a.caption?.isNotEmpty == true ? a.caption! : a.type,
                      ),
                      subtitle: Text(a.path),
                      trailing: IconButton(
                        tooltip: '삭제',
                        onPressed: vm.canEdit
                            ? () async {
                                try {
                                  await vm.deleteAttachmentById(a.id);
                                } catch (e) {
                                  _toast(context, e);
                                }
                              }
                            : null,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
