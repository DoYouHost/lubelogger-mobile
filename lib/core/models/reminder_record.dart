/// A reminder from `GET /api/vehicle/reminders` (read model
/// `ReminderAPIExportModel`). Reminders have no cost; they fall due on a date,
/// an odometer target, or both, and carry a computed [urgency]. Enums arrive as
/// their .NET names (e.g. "PastDue", "Odometer"), matched case-insensitively.
class ReminderRecord {
  const ReminderRecord({
    required this.id,
    required this.description,
    required this.urgency,
    required this.metric,
    required this.dueDate,
    required this.dueOdometer,
    required this.notes,
    required this.tags,
  });

  factory ReminderRecord.fromJson(Map<String, dynamic> json) => ReminderRecord(
        id: _toInt(json['id']),
        description: (json['description'] as String?) ?? '',
        urgency: ReminderUrgency.parse(json['urgency']),
        metric: ReminderMetric.parse(json['metric']),
        dueDate: json['dueDate'] is String
            ? DateTime.tryParse(json['dueDate'] as String)
            : null,
        dueOdometer: () {
          final o = _toDouble(json['dueOdometer']);
          return o > 0 ? o : null;
        }(),
        notes: (json['notes'] as String?) ?? '',
        tags: (json['tags'] as String?) ?? '',
      );

  final int id;
  final String description;
  final ReminderUrgency urgency;
  final ReminderMetric metric;
  final DateTime? dueDate;
  final double? dueOdometer;
  final String notes;
  final String tags;

  /// Whether the due date is relevant for this reminder's [metric].
  bool get showsDate => metric != ReminderMetric.odometer && dueDate != null;

  /// Whether the due odometer is relevant for this reminder's [metric].
  bool get showsOdometer => metric != ReminderMetric.date && dueOdometer != null;

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

/// Reminder urgency (`ReminderUrgency`: NotUrgent=0, Urgent=1, VeryUrgent=2,
/// PastDue=3).
enum ReminderUrgency {
  notUrgent,
  urgent,
  veryUrgent,
  pastDue,
  unknown;

  static ReminderUrgency parse(Object? raw) =>
      switch (raw?.toString().toLowerCase()) {
        'noturgent' || '0' => ReminderUrgency.notUrgent,
        'urgent' || '1' => ReminderUrgency.urgent,
        'veryurgent' || '2' => ReminderUrgency.veryUrgent,
        'pastdue' || '3' => ReminderUrgency.pastDue,
        _ => ReminderUrgency.unknown,
      };
}

/// What a reminder is measured against (`ReminderMetric`: Date=0, Odometer=1,
/// Both=2).
enum ReminderMetric {
  date('Date'),
  odometer('Odometer'),
  both('Both'),
  unknown('Date');

  const ReminderMetric(this.wireName);

  /// The .NET enum name the API expects on write.
  final String wireName;

  static ReminderMetric parse(Object? raw) =>
      switch (raw?.toString().toLowerCase()) {
        'date' || '0' => ReminderMetric.date,
        'odometer' || '1' => ReminderMetric.odometer,
        'both' || '2' => ReminderMetric.both,
        _ => ReminderMetric.unknown,
      };
}
