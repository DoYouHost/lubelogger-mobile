/// A free-text note from `GET /api/vehicle/notes`. Has no date or cost — just a
/// title ([description]), a body ([noteText]) and a [pinned] flag. The bool
/// arrives as the string "True"/"False" on the wire.
class NoteRecord {
  const NoteRecord({
    required this.description,
    required this.noteText,
    required this.pinned,
  });

  factory NoteRecord.fromJson(Map<String, dynamic> json) => NoteRecord(
        description: (json['description'] as String?) ?? '',
        noteText: (json['noteText'] as String?) ?? '',
        pinned: _toBool(json['pinned']),
      );

  final String description;
  final String noteText;
  final bool pinned;

  static bool _toBool(Object? v) => switch (v) {
        final bool b => b,
        final String s => s.toLowerCase() == 'true',
        _ => false,
      };
}
