/// A supply / part-inventory record from `GET /api/vehicle/supplyrecords`.
/// Shares the generic date + cost + description shape (no odometer), plus
/// part-tracking fields. All fields arrive as strings on the wire.
class SupplyRecord {
  const SupplyRecord({
    required this.date,
    required this.description,
    required this.cost,
    required this.partNumber,
    required this.partSupplier,
    required this.partQuantity,
    required this.notes,
  });

  factory SupplyRecord.fromJson(Map<String, dynamic> json) => SupplyRecord(
        date: json['date'] is String
            ? DateTime.tryParse(json['date'] as String)
            : null,
        description: (json['description'] as String?) ?? '',
        cost: _toDouble(json['cost']),
        partNumber: (json['partNumber'] as String?) ?? '',
        partSupplier: (json['partSupplier'] as String?) ?? '',
        partQuantity: (json['partQuantity'] as String?) ?? '',
        notes: (json['notes'] as String?) ?? '',
      );

  final DateTime? date;
  final String description;
  final double cost;
  final String partNumber;
  final String partSupplier;
  final String partQuantity;
  final String notes;

  static double _toDouble(Object? v) => switch (v) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s) ?? 0,
        _ => 0,
      };
}
