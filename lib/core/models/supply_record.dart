/// A supply / part-inventory record from `GET /api/vehicle/supplyrecords`.
/// Shares the generic date + cost + description shape (no odometer), plus
/// part-tracking fields. Numeric fields arrive as numbers under the
/// culture-invariant header; [id] and [partQuantity] parse tolerantly.
class SupplyRecord {
  const SupplyRecord({
    required this.id,
    required this.date,
    required this.description,
    required this.cost,
    required this.partNumber,
    required this.partSupplier,
    required this.partQuantity,
    required this.notes,
    required this.tags,
  });

  factory SupplyRecord.fromJson(Map<String, dynamic> json) => SupplyRecord(
        id: _toInt(json['id']),
        date: json['date'] is String
            ? DateTime.tryParse(json['date'] as String)
            : null,
        description: (json['description'] as String?) ?? '',
        cost: _toDouble(json['cost']),
        partNumber: (json['partNumber'] as String?) ?? '',
        partSupplier: (json['partSupplier'] as String?) ?? '',
        // Sent as a number under culture-invariant; keep a trimmed string for
        // display and re-parse it for the edit form.
        partQuantity: _toNumString(json['partQuantity']),
        notes: (json['notes'] as String?) ?? '',
        tags: (json['tags'] as String?) ?? '',
      );

  final int id;
  final DateTime? date;
  final String description;
  final double cost;
  final String partNumber;
  final String partSupplier;
  final String partQuantity;
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

  /// A numeric wire value as a display string, dropping a trailing `.0`
  /// (`2.0` → "2", `1.5` → "1.5"); already-string values pass through.
  static String _toNumString(Object? v) => switch (v) {
        final String s => s,
        final num n =>
          n == n.roundToDouble() ? n.toInt().toString() : n.toString(),
        _ => '',
      };
}
