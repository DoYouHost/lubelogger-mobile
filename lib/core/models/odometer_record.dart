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
      );

  final int id;
  final DateTime? date;
  final double odometer;
  final double initialOdometer;
  final String notes;
  final String tags;

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
