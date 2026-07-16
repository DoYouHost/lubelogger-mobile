import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/attachment.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../attachments/attachment_viewer.dart';

/// A record form's file-attachments editor: pick files, upload them right away
/// via [VehiclesRepository.uploadDocuments], and report the current list up
/// through [onChanged]. Existing attachments (when editing) show as removable
/// chips. Every record type except reminders supports files.
class AttachmentsField extends ConsumerStatefulWidget {
  const AttachmentsField({
    super.key,
    required this.initial,
    required this.enabled,
    required this.onChanged,
  });

  /// Attachments the record already has (empty when adding).
  final List<Attachment> initial;

  /// False while the owning form is submitting.
  final bool enabled;

  /// Called with the full up-to-date list after every add or remove.
  final ValueChanged<List<Attachment>> onChanged;

  @override
  ConsumerState<AttachmentsField> createState() => _AttachmentsFieldState();
}

class _AttachmentsFieldState extends ConsumerState<AttachmentsField> {
  late List<Attachment> _files = [...widget.initial];
  bool _uploading = false;
  String? _error;

  bool get _busy => _uploading || !widget.enabled;

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(allowMultiple: true);
    } on Object {
      if (mounted) setState(() => _error = l10n.attachmentUploadError);
      return;
    }
    if (result == null) return; // user cancelled

    final picked = [
      for (final f in result.files)
        if (f.path != null) (path: f.path!, name: f.name),
    ];
    if (picked.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final uploaded = await ref
          .read(vehiclesRepositoryProvider)
          .uploadDocuments(picked);
      if (!mounted) return;
      setState(() {
        _files = [..._files, ...uploaded];
        _uploading = false;
      });
      widget.onChanged(_files);
    } on Object {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = l10n.attachmentUploadError;
      });
    }
  }

  void _remove(Attachment file) {
    setState(() => _files = [..._files]..remove(file));
    widget.onChanged(_files);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.attachmentsLabel,
          style: TextStyle(
            fontFamily: DashTokens.fontUi,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: t.textSecondary,
          ),
        ),
        if (_files.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final f in _files) _chip(t, f)],
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file, size: 18),
            label: Text(l10n.attachmentAddButton),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: t.danger, fontFamily: DashTokens.fontUi),
          ),
        ],
      ],
    );
  }

  Widget _chip(DashTokens t, Attachment file) => Container(
    padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
    decoration: BoxDecoration(
      color: t.subCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: t.subCardBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => openAttachment(context, ref, file),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 15,
                  color: t.textTertiary,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          color: t.textTertiary,
          onPressed: _busy ? null : () => _remove(file),
        ),
      ],
    ),
  );
}
