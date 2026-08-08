import 'attachment.dart';
import 'extra_field.dart';

/// One odometer reading from `GET /api/vehicle/odometerrecords`. Monthly
/// distance is derived from a combined timeline of readings (gas + odometer),
/// not per-record spans. Values are in the server's raw stored distance unit.
///
/// [initialOdometer] (the record's starting mileage, used server-side to
/// compute distance since the previous reading) is carried so the edit form can
/// preserve it — the update endpoint requires it.
class OdometerRecord {
  const OdometerRecord({
    required this.id,
    required this.date,
    required this.odometer,
    required this.initialOdometer,
    required this.notes,
    required this.tags,
    this.files = const [],
    this.extraFields = const [],
    this.equipmentRecordId = '',
  });

  factory OdometerRecord.fromJson(Map<String, dynamic> json) => OdometerRecord(
        id: _toInt(json['id']),
        date: json['date'] is String
            ? DateTime.tryParse(json['date'] as String)
            : null,
        odometer: _toDouble(json['odometer']),
        initialOdometer: _toDouble(json['initialOdometer']),
        notes: (json['notes'] as String?) ?? '',
        tags: (json['tags'] as String?) ?? '',
        files: Attachment.listFrom(json['files']),
        extraFields: ExtraField.listFrom(json['extraFields']),
        equipmentRecordId: _toIdList(json['equipmentRecordId']),
      );

  final int id;
  final DateTime? date;
  final double odometer;
  final double initialOdometer;
  final String notes;
  final String tags;
  final List<Attachment> files;

  final List<ExtraField> extraFields;

  /// Equipment this reading is attributed to, space-joined as the update
  /// endpoint wants it. No UI — read solely so an edit can send it back; the
  /// server clears the link otherwise.
  final String equipmentRecordId;

  /// Reads the link whether it arrives as a list or as an already-joined string.
  static String _toIdList(Object? v) => switch (v) {
        final String s => s,
        final List<dynamic> l => l.map((e) => e.toString()).join(' '),
        final num n => n.toString(),
        _ => '',
      };

  static int _toInt(Object? v) => switch (v) {
        final num n => n.toInt(),
        final String s => int.tryParse(s) ?? 0,
        _ => 0,
      };

  static double _toDouble(Object? v) => switch (v) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s) ?? 0,
        _ => 0,
      };
}
