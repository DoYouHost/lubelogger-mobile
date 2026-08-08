import '../../core/cache/write_queue.dart';
import '../../core/models/vehicle_tab.dart';
import '../../l10n/app_localizations.dart';
import '../common/vehicle_tab_ui.dart';

/// A queued request as a line its author can recognise: what it does, and to
/// what. The queue stores raw HTTP, so the path is all there is to read it off.
String describePendingWrite(PendingWrite write, AppLocalizations l10n) {
  final segments = write.path.split('/').where((s) => s.isNotEmpty).toList();
  final action = segments.isEmpty ? '' : segments.last;
  final type = _typeLabel(segments, l10n);
  return switch (action) {
    'add' => l10n.syncOpAdd(type),
    'update' => l10n.syncOpUpdate(type),
    'delete' => l10n.syncOpDelete(type),
    _ => type,
  };
}

/// Record types already have names on the tab bar; a queued write names the
/// same things and has no business inventing a second set.
String _typeLabel(List<String> segments, AppLocalizations l10n) {
  final collection = segments.length >= 2 ? segments[segments.length - 2] : '';
  if (collection == 'vehicles' || segments.contains('vehicles')) {
    return l10n.syncTypeVehicle;
  }
  final tab = switch (collection) {
    'gasrecords' => VehicleTab.fuel,
    'odometerrecords' => VehicleTab.odometer,
    'servicerecords' => VehicleTab.service,
    'repairrecords' => VehicleTab.repair,
    'upgraderecords' => VehicleTab.upgrade,
    'taxrecords' => VehicleTab.tax,
    'supplyrecords' => VehicleTab.supply,
    'planrecords' => VehicleTab.plan,
    'reminders' => VehicleTab.reminder,
    'notes' => VehicleTab.note,
    'equipmentrecords' => VehicleTab.equipment,
    _ => null,
  };
  return tab?.label(l10n) ?? collection;
}
