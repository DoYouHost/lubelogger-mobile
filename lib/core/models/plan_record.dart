/// A planner item from `GET /api/vehicle/planrecords`. Unlike cost records it
/// has no service date/odometer — it tracks a creation date, a [type], a
/// priority and a progress state, plus an estimated cost. Enums arrive as their
/// .NET names (e.g. "Critical", "InProgress"); we match them case-insensitively.
class PlanRecord {
  const PlanRecord({
    required this.id,
    required this.dateCreated,
    required this.description,
    required this.cost,
    required this.type,
    required this.priority,
    required this.progress,
    required this.notes,
  });

  factory PlanRecord.fromJson(Map<String, dynamic> json) => PlanRecord(
        id: _toInt(json['id']),
        dateCreated: json['dateCreated'] is String
            ? DateTime.tryParse(json['dateCreated'] as String)
            : null,
        description: (json['description'] as String?) ?? '',
        cost: _toDouble(json['cost']),
        type: PlanType.parse(json['type']),
        priority: PlanPriority.parse(json['priority']),
        progress: PlanProgress.parse(json['progress']),
        notes: (json['notes'] as String?) ?? '',
      );

  final int id;
  final DateTime? dateCreated;
  final String description;
  final double cost;
  final PlanType type;
  final PlanPriority priority;
  final PlanProgress progress;
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

/// What a planned item becomes once done — the API's `ImportMode` (a planner
/// item may only be a ServiceRecord, RepairRecord or UpgradeRecord). [unknown]
/// covers any other value the server might report.
enum PlanType {
  service('ServiceRecord'),
  repair('RepairRecord'),
  upgrade('UpgradeRecord'),
  unknown('ServiceRecord');

  const PlanType(this.wireName);

  /// The .NET `ImportMode` name the API expects on write.
  final String wireName;

  static PlanType parse(Object? raw) => switch (raw?.toString().toLowerCase()) {
        'servicerecord' => PlanType.service,
        'repairrecord' => PlanType.repair,
        'upgraderecord' => PlanType.upgrade,
        _ => PlanType.unknown,
      };
}

/// Planner priority (`PlanPriority`: Critical=0, Normal=1, Low=2). [unknown]
/// covers values the server may add later.
enum PlanPriority {
  critical('Critical'),
  normal('Normal'),
  low('Low'),
  unknown('Normal');

  const PlanPriority(this.wireName);

  /// The .NET enum name the API expects on write.
  final String wireName;

  static PlanPriority parse(Object? raw) =>
      switch (raw?.toString().toLowerCase()) {
        'critical' || '0' => PlanPriority.critical,
        'normal' || '1' => PlanPriority.normal,
        'low' || '2' => PlanPriority.low,
        _ => PlanPriority.unknown,
      };
}

/// Planner progress (`PlanProgress`: Backlog=0, InProgress=1, Testing=2,
/// Done=3). [unknown] covers values the server may add later. Note: the API
/// rejects writing [done] (plans reach Done only via the planner board), so the
/// edit form doesn't offer it.
enum PlanProgress {
  backlog('Backlog'),
  inProgress('InProgress'),
  testing('Testing'),
  done('Testing'),
  unknown('Backlog');

  const PlanProgress(this.wireName);

  /// The .NET enum name the API expects on write. [done] maps to `Testing`
  /// because the API forbids setting Done — a Done plan re-saved via the app
  /// falls back to the closest writable state.
  final String wireName;

  static PlanProgress parse(Object? raw) =>
      switch (raw?.toString().toLowerCase()) {
        'backlog' || '0' => PlanProgress.backlog,
        'inprogress' || '1' => PlanProgress.inProgress,
        'testing' || '2' => PlanProgress.testing,
        'done' || '3' => PlanProgress.done,
        _ => PlanProgress.unknown,
      };
}
