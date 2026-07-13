import 'vehicle.dart';

/// Aggregated per-vehicle data from `GET /api/vehicle/info?vehicleId=` — the
/// vehicle plus its odometer, record counts/costs, and reminder counts. The
/// endpoint returns an array (one element per requested vehicle).
class VehicleInfo {
  const VehicleInfo({
    required this.vehicle,
    required this.lastReportedOdometer,
    required this.serviceRecordCost,
    required this.repairRecordCost,
    required this.upgradeRecordCost,
    required this.taxRecordCost,
    required this.gasRecordCost,
    required this.veryUrgentReminderCount,
    required this.urgentReminderCount,
    required this.notUrgentReminderCount,
    required this.pastDueReminderCount,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) => VehicleInfo(
        vehicle:
            Vehicle.fromJson(json['vehicleData'] as Map<String, dynamic>),
        lastReportedOdometer: _toDouble(json['lastReportedOdometer']),
        serviceRecordCost: _toDouble(json['serviceRecordCost']),
        repairRecordCost: _toDouble(json['repairRecordCost']),
        upgradeRecordCost: _toDouble(json['upgradeRecordCost']),
        taxRecordCost: _toDouble(json['taxRecordCost']),
        gasRecordCost: _toDouble(json['gasRecordCost']),
        veryUrgentReminderCount: _toInt(json['veryUrgentReminderCount']),
        urgentReminderCount: _toInt(json['urgentReminderCount']),
        notUrgentReminderCount: _toInt(json['notUrgentReminderCount']),
        pastDueReminderCount: _toInt(json['pastDueReminderCount']),
      );

  final Vehicle vehicle;
  final double lastReportedOdometer;

  final double serviceRecordCost;
  final double repairRecordCost;
  final double upgradeRecordCost;
  final double taxRecordCost;
  final double gasRecordCost;

  final int veryUrgentReminderCount;
  final int urgentReminderCount;
  final int notUrgentReminderCount;
  final int pastDueReminderCount;

  /// Lifetime spend across every record type.
  double get totalCost =>
      serviceRecordCost +
      repairRecordCost +
      upgradeRecordCost +
      taxRecordCost +
      gasRecordCost;

  /// Reminders needing attention now (past due or very urgent).
  int get alertReminderCount => pastDueReminderCount + veryUrgentReminderCount;

  static double _toDouble(Object? v) => switch (v) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s) ?? 0,
        _ => 0,
      };

  static int _toInt(Object? v) => switch (v) {
        final num n => n.toInt(),
        final String s => int.tryParse(s) ?? 0,
        _ => 0,
      };
}
