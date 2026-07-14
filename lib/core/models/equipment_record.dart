/// An equipment item from `GET /api/vehicle/equipmentrecords` (read model
/// `EquipmentRecordAPIExportModel`). Has no date or cost — a description, an
/// [isEquipped] flag, and the [distanceTraveled] accrued while equipped (in the
/// server's raw stored distance unit). The bool arrives as "True"/"False".
class EquipmentRecord {
  const EquipmentRecord({
    required this.description,
    required this.isEquipped,
    required this.distanceTraveled,
    required this.notes,
  });

  factory EquipmentRecord.fromJson(Map<String, dynamic> json) => EquipmentRecord(
        description: (json['description'] as String?) ?? '',
        isEquipped: _toBool(json['isEquipped']),
        distanceTraveled: () {
          final d = _toDouble(json['distanceTraveled']);
          return d > 0 ? d : null;
        }(),
        notes: (json['notes'] as String?) ?? '',
      );

  final String description;
  final bool isEquipped;
  final double? distanceTraveled;
  final String notes;

  static bool _toBool(Object? v) => switch (v) {
        final bool b => b,
        final String s => s.toLowerCase() == 'true',
        _ => false,
      };

  static double _toDouble(Object? v) => switch (v) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s) ?? 0,
        _ => 0,
      };
}
