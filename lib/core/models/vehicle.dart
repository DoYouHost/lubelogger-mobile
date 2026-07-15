/// A vehicle in the household garage, from `GET /api/vehicles` (also nested as
/// `vehicleData` inside `GET /api/vehicle/info`).
///
/// Only the fields the app currently reads are modelled; the write model
/// (VehicleImportModel) differs and is added when the add/edit form is built.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.year,
    required this.make,
    required this.model,
    required this.licensePlate,
    required this.imageLocation,
    required this.tags,
    required this.isElectric,
    required this.isDiesel,
    required this.useHours,
    required this.odometerOptional,
    this.identifier = 'LicensePlate',
    this.extraFields = const [],
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: (json['id'] as num?)?.toInt() ?? 0,
        year: (json['year'] as num?)?.toInt() ?? 0,
        make: (json['make'] as String?) ?? '',
        model: (json['model'] as String?) ?? '',
        licensePlate: (json['licensePlate'] as String?) ?? '',
        imageLocation: (json['imageLocation'] as String?) ?? '',
        tags: _stringList(json['tags']),
        isElectric: json['isElectric'] == true,
        isDiesel: json['isDiesel'] == true,
        useHours: json['useHours'] == true,
        odometerOptional: json['odometerOptional'] == true,
        identifier: (json['vehicleIdentifier'] as String?) ?? 'LicensePlate',
        extraFields: _extraFields(json['extraFields']),
      );

  final int id;
  final int year;
  final String make;
  final String model;

  /// Registration/identifier plate; also LubeLogger's default vehicle label.
  final String licensePlate;

  /// Server-relative image path (e.g. `/images/<uuid>.jpg`), empty if none.
  final String imageLocation;

  final List<String> tags;

  /// True → distances are tracked in engine hours rather than odometer km/mi.
  final bool useHours;

  final bool isElectric;
  final bool isDiesel;
  final bool odometerOptional;

  /// Which field labels the vehicle server-side (usually `LicensePlate`, or the
  /// name of an [extraFields] entry). Kept so an edit can resend it unchanged —
  /// the update endpoint overwrites it with whatever we send.
  final String identifier;

  /// Custom fields as returned by the server (`{name, value, ...}`), kept as raw
  /// maps purely to round-trip them on edit (the update endpoint replaces the
  /// whole list). The app doesn't otherwise read or display them.
  final List<Map<String, dynamic>> extraFields;

  /// "Make Model" for the card title (year is shown separately).
  String get makeModel => [make, model].where((s) => s.isNotEmpty).join(' ');

  static List<Map<String, dynamic>> _extraFields(Object? raw) {
    if (raw is! List) return const [];
    return [for (final e in raw) if (e is Map<String, dynamic>) e];
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return [for (final e in raw) if (e != null) e.toString()];
  }
}
