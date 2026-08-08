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
        id: _toInt(json['id']),
        description: (json['description'] as String?) ?? '',
        noteText: (json['noteText'] as String?) ?? '',
        pinned: _toBool(json['pinned']),
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

  static int _toInt(Object? v) => switch (v) {
        final num n => n.toInt(),
        final String s => int.tryParse(s) ?? 0,
        _ => 0,
      };

  static bool _toBool(Object? v) => switch (v) {
        final bool b => b,
        final String s => s.toLowerCase() == 'true',
        _ => false,
      };
}
