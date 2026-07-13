import '../api/endpoints.dart';

/// A service / repair / upgrade / tax record from `GET /api/vehicle/X`. These
/// four share the `GenericRecordExportModel` shape (date, odometer, description,
/// cost, notes, tags); tax records carry no odometer, so [odometer] is null for
/// them. All fields arrive as strings on the wire (see the API contract).
class VehicleRecord {
  const VehicleRecord({
    required this.id,
    required this.date,
    required this.odometer,
    required this.description,
    required this.cost,
    required this.notes,
  });

  factory VehicleRecord.fromJson(Map<String, dynamic> json) => VehicleRecord(
        id: _toInt(json['id']),
        date: json['date'] is String
            ? DateTime.tryParse(json['date'] as String)
            : null,
        // Tax records omit odometer; a "0" reading is treated as absent too.
        odometer: () {
          final o = _toDouble(json['odometer']);
          return o > 0 ? o : null;
        }(),
        description: (json['description'] as String?) ?? '',
        cost: _toDouble(json['cost']),
        notes: (json['notes'] as String?) ?? '',
      );

  final int id;
  final DateTime? date;
  final double? odometer;
  final String description;
  final double cost;
  final String notes;

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

/// The four generic (date + cost) record types, each mapping to its list
/// endpoint. Fuel and odometer have their own richer models/endpoints.
enum RecordKind {
  service(Endpoints.serviceRecords, hasOdometer: true),
  repair(Endpoints.repairRecords, hasOdometer: true),
  upgrade(Endpoints.upgradeRecords, hasOdometer: true),
  tax(Endpoints.taxRecords, hasOdometer: false);

  const RecordKind(this.endpoint, {required this.hasOdometer});

  final String endpoint;

  /// Tax records have no odometer column; the others do.
  final bool hasOdometer;
}
