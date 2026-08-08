import 'attachment.dart';
import 'extra_field.dart';

/// One refuel from `GET /api/vehicle/gasrecords?vehicleId=`. Fuel economy is
/// computed locally (see `GasStats`), not read from the server's `fuelEconomy`
/// field — that field is always emitted in the API's default metric mode and
/// ignores our chosen measurement base.
class GasRecord {
  /// The server's own defaults for a new record (`Models/GasRecord/GasRecord.cs`),
  /// which is also where the web's slider starts.
  static const defaultStartingSoc = 20;
  static const defaultEndingSoc = 80;

  const GasRecord({
    required this.id,
    required this.date,
    required this.odometer,
    required this.fuelConsumed,
    required this.cost,
    required this.isFillToFull,
    required this.missedFuelUp,
    this.startingSoc = defaultStartingSoc,
    this.endingSoc = defaultEndingSoc,
    this.notes = '',
    this.tags = '',
    this.files = const [],
    this.extraFields = const [],
  });

  factory GasRecord.fromJson(Map<String, dynamic> json) => GasRecord(
        id: _toInt(json['id']),
        date: _toDate(json['date']),
        odometer: _toDouble(json['odometer']),
        fuelConsumed: _toDouble(json['fuelConsumed']),
        cost: _toDouble(json['cost']),
        isFillToFull: _toBool(json['isFillToFull']),
        missedFuelUp: _toBool(json['missedFuelUp']),
        startingSoc: _toInt(json['startingSoc']),
        endingSoc: _toInt(json['endingSoc']),
        notes: (json['notes'] as String?) ?? '',
        tags: (json['tags'] as String?) ?? '',
        files: Attachment.listFrom(json['files']),
        extraFields: ExtraField.listFrom(json['extraFields']),
      );

  final int id;
  final DateTime? date;
  final double odometer;
  final double fuelConsumed;
  final double cost;
  final bool isFillToFull;
  final bool missedFuelUp;
  final List<Attachment> files;

  /// Battery charge either side of the session, as a percentage. Only shown for
  /// electric vehicles, but round-tripped for every record: the server derives
  /// an EV's battery capacity from `fuelConsumed / (endingSoc - startingSoc)`,
  /// so writing the two equal makes it divide by zero and report no consumption.
  final int startingSoc;
  final int endingSoc;

  /// Not shown in the fuel table, but read so editing a record can prefill
  /// (and round-trip) its notes/tags instead of the update silently clearing
  /// them.
  final String notes;
  final String tags;

  final List<ExtraField> extraFields;

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

  static bool _toBool(Object? v) => switch (v) {
        final bool b => b,
        final String s => s.toLowerCase() == 'true',
        _ => false,
      };

  static DateTime? _toDate(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
}
