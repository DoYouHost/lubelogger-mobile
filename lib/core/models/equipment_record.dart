import 'attachment.dart';
import 'extra_field.dart';

/// An equipment item from `GET /api/vehicle/equipmentrecords` (read model
/// `EquipmentRecordAPIExportModel`). Has no date or cost — a description, an
/// [isEquipped] flag, and the [distanceTraveled] accrued while equipped (in the
/// server's raw stored distance unit). The bool arrives as "True"/"False".
class EquipmentRecord {
  const EquipmentRecord({
    required this.id,
    required this.description,
    required this.isEquipped,
    required this.distanceTraveled,
    required this.notes,
    required this.tags,
    this.files = const [],
    this.extraFields = const [],
  });

  factory EquipmentRecord.fromJson(Map<String, dynamic> json) => EquipmentRecord(
        id: _toInt(json['id']),
        description: (json['description'] as String?) ?? '',
        isEquipped: _toBool(json['isEquipped']),
        distanceTraveled: () {
          final d = _toDouble(json['distanceTraveled']);
          return d > 0 ? d : null;
        }(),
        notes: (json['notes'] as String?) ?? '',
        tags: (json['tags'] as String?) ?? '',
        files: Attachment.listFrom(json['files']),
        extraFields: ExtraField.listFrom(json['extraFields']),
      );

  final int id;
  final String description;
  final bool isEquipped;
  final double? distanceTraveled;
  final String notes;
  final String tags;
  final List<Attachment> files;

  final List<ExtraField> extraFields;

  static int _toInt(Object? v) => switch (v) {
        final num n => n.toInt(),
        final String s => int.tryParse(s) ?? 0,
        _ => 0,
      };

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
