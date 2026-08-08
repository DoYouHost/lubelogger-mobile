/// Custom ("extra") fields — LubeLogger's per-record-type user-defined fields.
///
/// The wire format differs between the two places they come from: a record's own
/// `extraFields` send `fieldType` as the .NET enum's **integer**, while the
/// template from `GET /api/extrafields` sends its **name** (a different export
/// model stringifies it). Reads accept both; writes always emit the integer,
/// the only form the write path parses.
///
/// Writes also break this app's rule that every field goes out as a string:
/// `isRequired`/`fieldType` must be a real JSON bool and number, because
/// server-side `ExtraField` is a typed class rather than one of the stringly
/// export models, and ASP.NET's JSON defaults parse neither from a string.
library;

/// `Enum/ExtraFieldType.cs`. A kind this app doesn't know is edited as plain
/// text — matching the web UI's own `default:` branch — and written back
/// unchanged (see [ExtraField.wireFieldType]).
enum ExtraFieldType {
  text(0),
  number(1),
  decimal(2),
  date(3),
  time(4),
  location(5);

  const ExtraFieldType(this.wireValue);

  final int wireValue;

  /// Accepts the integer, that integer as a string, or the .NET enum name.
  /// Null for anything else, leaving the caller to preserve it.
  static ExtraFieldType? parse(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return _byWire(raw.toInt());
    final s = raw.toString().trim();
    final asInt = int.tryParse(s);
    if (asInt != null) return _byWire(asInt);
    final name = s.toLowerCase();
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static ExtraFieldType? _byWire(int wire) {
    for (final v in values) {
      if (v.wireValue == wire) return v;
    }
    return null;
  }
}

/// One custom field: its definition plus the value a record holds for it.
/// Template entries are the same class with an empty [value].
class ExtraField {
  const ExtraField({
    required this.name,
    this.value = '',
    this.isRequired = false,
    this.fieldType = ExtraFieldType.text,
    this.wireFieldType,
  });

  factory ExtraField.fromJson(Map<String, dynamic> json) {
    final rawType = json['fieldType'];
    final parsed = ExtraFieldType.parse(rawType);
    return ExtraField(
      name: (json['name'] as String?) ?? '',
      value: (json['value'] as String?) ?? '',
      isRequired: _toBool(json['isRequired']),
      fieldType: parsed ?? ExtraFieldType.text,
      wireFieldType: parsed == null ? _toIntOrNull(rawType) : null,
    );
  }

  final String name;
  final String value;
  final bool isRequired;
  final ExtraFieldType fieldType;

  /// Set only for a `fieldType` this app doesn't know, so [toJson] can echo the
  /// server's own integer back instead of retyping the field to Text.
  final int? wireFieldType;

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'isRequired': isRequired,
        'fieldType': wireFieldType ?? fieldType.wireValue,
      };

  ExtraField copyWith({String? value}) => ExtraField(
        name: name,
        value: value ?? this.value,
        isRequired: isRequired,
        fieldType: fieldType,
        wireFieldType: wireFieldType,
      );

  /// This field's value carried onto [definition]'s name, kind and
  /// required-ness — the per-field half of [mergeExtraFields].
  ExtraField withDefinition(ExtraField definition) => ExtraField(
        name: definition.name,
        value: value,
        isRequired: definition.isRequired,
        fieldType: definition.fieldType,
        wireFieldType: definition.wireFieldType,
      );

  static List<ExtraField> listFrom(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map<String, dynamic>) ExtraField.fromJson(e),
    ];
  }

  static List<Map<String, dynamic>> jsonList(List<ExtraField> fields) =>
      [for (final f in fields) f.toJson()];

  static bool _toBool(Object? raw) => switch (raw) {
        final bool b => b,
        final String s => s.toLowerCase() == 'true',
        final num n => n != 0,
        _ => false,
      };

  static int? _toIntOrNull(Object? raw) => switch (raw) {
        final num n => n.toInt(),
        final String s => int.tryParse(s.trim()),
        _ => null,
      };
}

/// Reconciles a record's stored fields with the household's current [template],
/// mirroring the server's `StaticHelper.AddExtraFields` so the app offers
/// exactly the fields the web UI's edit modal would.
///
/// A null [template] means it isn't known — an older server without
/// `/api/extrafields`, or a failed fetch — and passes the record's fields
/// through untouched, so a write still round-trips them. An *empty* template is
/// different: it means no fields are configured, and clears them like the web
/// UI does.
List<ExtraField> mergeExtraFields(
  List<ExtraField> record,
  List<ExtraField>? template,
) {
  if (template == null) return List.of(record);
  if (template.isEmpty) return const [];
  if (record.isEmpty) return List.of(template);
  final byName = {for (final f in record) f.name: f};
  return [
    for (final definition in template)
      byName[definition.name]?.withDefinition(definition) ?? definition,
  ];
}

/// Record types that can carry custom fields, keyed by the server's `ImportMode`
/// name as `/api/extrafields` reports them.
///
/// Reminders are absent on purpose: `ReminderExportModel` has no extra fields,
/// so the API cannot store any.
enum ExtraFieldRecordType {
  service('ServiceRecord'),
  repair('RepairRecord'),
  upgrade('UpgradeRecord'),
  tax('TaxRecord'),
  gas('GasRecord'),
  odometer('OdometerRecord'),
  supply('SupplyRecord'),
  plan('PlanRecord'),
  note('NoteRecord'),
  equipment('EquipmentRecord'),
  vehicle('VehicleRecord');

  const ExtraFieldRecordType(this.wireName);

  final String wireName;

  static ExtraFieldRecordType? parse(Object? raw) {
    final name = raw?.toString().toLowerCase();
    for (final v in values) {
      if (v.wireName.toLowerCase() == name) return v;
    }
    return null;
  }
}
