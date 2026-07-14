/// A planner item from `GET /api/vehicle/planrecords`. Unlike cost records it
/// has no service date/odometer — it tracks a creation date, a priority and a
/// progress state, plus an estimated cost. Enums arrive as their .NET names
/// (e.g. "Critical", "InProgress"); we match them case-insensitively.
class PlanRecord {
  const PlanRecord({
    required this.dateCreated,
    required this.description,
    required this.cost,
    required this.priority,
    required this.progress,
    required this.notes,
  });

  factory PlanRecord.fromJson(Map<String, dynamic> json) => PlanRecord(
        dateCreated: json['dateCreated'] is String
            ? DateTime.tryParse(json['dateCreated'] as String)
            : null,
        description: (json['description'] as String?) ?? '',
        cost: _toDouble(json['cost']),
        priority: PlanPriority.parse(json['priority']),
        progress: PlanProgress.parse(json['progress']),
        notes: (json['notes'] as String?) ?? '',
      );

  final DateTime? dateCreated;
  final String description;
  final double cost;
  final PlanPriority priority;
  final PlanProgress progress;
  final String notes;

  static double _toDouble(Object? v) => switch (v) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s) ?? 0,
        _ => 0,
      };
}

/// Planner priority (`PlanPriority`: Critical=0, Normal=1, Low=2). [unknown]
/// covers values the server may add later.
enum PlanPriority {
  critical,
  normal,
  low,
  unknown;

  static PlanPriority parse(Object? raw) => switch (raw?.toString().toLowerCase()) {
        'critical' || '0' => PlanPriority.critical,
        'normal' || '1' => PlanPriority.normal,
        'low' || '2' => PlanPriority.low,
        _ => PlanPriority.unknown,
      };
}

/// Planner progress (`PlanProgress`: Backlog=0, InProgress=1, Testing=2,
/// Done=3). [unknown] covers values the server may add later.
enum PlanProgress {
  backlog,
  inProgress,
  testing,
  done,
  unknown;

  static PlanProgress parse(Object? raw) => switch (raw?.toString().toLowerCase()) {
        'backlog' || '0' => PlanProgress.backlog,
        'inprogress' || '1' => PlanProgress.inProgress,
        'testing' || '2' => PlanProgress.testing,
        'done' || '3' => PlanProgress.done,
        _ => PlanProgress.unknown,
      };
}
