import 'package:app_util/app_util.dart';

import 'attachment.dart';
import 'extra_field.dart';

/// A free-text note from `GET /api/vehicle/notes`. Has no date or cost — just a
/// title ([description]), a body ([noteText]) and a [pinned] flag. The bool
/// arrives as the string "True"/"False" on the wire.
class NoteRecord {
  const NoteRecord({
    required this.id,
    required this.description,
    required this.noteText,
    required this.pinned,
    required this.tags,
    this.files = const [],
    this.extraFields = const [],
  });

  factory NoteRecord.fromJson(Map<String, dynamic> json) => NoteRecord(
        id: toInt(json['id']),
        description: (json['description'] as String?) ?? '',
        noteText: (json['noteText'] as String?) ?? '',
        pinned: toBoolOrFalse(json['pinned']),
        tags: (json['tags'] as String?) ?? '',
        files: Attachment.listFrom(json['files']),
        extraFields: ExtraField.listFrom(json['extraFields']),
      );

  final int id;
  final String description;
  final String noteText;
  final bool pinned;
  final String tags;
  final List<Attachment> files;

  final List<ExtraField> extraFields;
}
