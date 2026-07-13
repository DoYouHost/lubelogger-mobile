/// One odometer reading from `GET /api/vehicle/odometerrecords`. Only the fields
/// needed for the monthly distance line are modelled: the date and the distance
/// the record spans (`odometer - initialOdometer`, matching the server's
/// `DistanceTraveled`). Values are in the server's raw stored distance unit.
class OdometerRecord {
  const OdometerRecord({required this.date, required this.distanceTraveled});

  factory OdometerRecord.fromJson(Map<String, dynamic> json) {
    final initial = _toDouble(json['initialOdometer']);
    final current = _toDouble(json['odometer']);
    final span = current - initial;
    return OdometerRecord(
      date: json['date'] is String
          ? DateTime.tryParse(json['date'] as String)
          : null,
      distanceTraveled: span > 0 ? span : 0,
    );
  }

  final DateTime? date;
  final double distanceTraveled;

  static double _toDouble(Object? v) => switch (v) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s) ?? 0,
        _ => 0,
      };
}
