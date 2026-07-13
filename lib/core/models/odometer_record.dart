/// One odometer reading from `GET /api/vehicle/odometerrecords`. Only the date
/// and the reading itself are modelled; monthly distance is derived from a
/// combined timeline of readings (gas + odometer), not per-record spans.
/// Values are in the server's raw stored distance unit.
class OdometerRecord {
  const OdometerRecord({required this.date, required this.odometer});

  factory OdometerRecord.fromJson(Map<String, dynamic> json) => OdometerRecord(
        date: json['date'] is String
            ? DateTime.tryParse(json['date'] as String)
            : null,
        odometer: _toDouble(json['odometer']),
      );

  final DateTime? date;
  final double odometer;

  static double _toDouble(Object? v) => switch (v) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s) ?? 0,
        _ => 0,
      };
}
