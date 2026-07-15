import 'package:quick_actions/quick_actions.dart';

/// Launcher long-press shortcuts (Android App Shortcuts / iOS Quick Actions).
///
/// Two record-adding shortcuts — [addFuel] and [addOdometer] — are published
/// while the user is signed in and cleared on logout. Tapping one fires the
/// handler registered in [init]; the actual "resolve a vehicle, open the form"
/// flow lives in `QuickActionHandler` (it needs the widget tree).
class QuickActionsService {
  final QuickActions _quickActions = const QuickActions();

  /// Shortcut [ShortcutItem.type] values, echoed back to the [init] handler.
  static const String addFuel = 'add_fuel';
  static const String addOdometer = 'add_odometer';

  /// Registers the tap handler. On a cold launch the handler is invoked once
  /// with the launching shortcut's type shortly after this call.
  Future<void> init(void Function(String type) onAction) =>
      _quickActions.initialize(onAction);

  /// Publishes the add-record shortcuts. Labels are passed in so they follow
  /// the app locale (shortcuts live outside the widget tree).
  Future<void> setRecordShortcuts({
    required String fuelLabel,
    required String odometerLabel,
  }) =>
      _quickActions.setShortcutItems([
        ShortcutItem(
          type: addFuel,
          localizedTitle: fuelLabel,
          icon: 'ic_shortcut_fuel',
        ),
        ShortcutItem(
          type: addOdometer,
          localizedTitle: odometerLabel,
          icon: 'ic_shortcut_odometer',
        ),
      ]);

  /// Removes every shortcut (on logout, when there's no vehicle to target).
  Future<void> clear() => _quickActions.clearShortcutItems();
}

/// App-wide singleton, shared by `main` (init + publish at launch) and the
/// server-profile notifier (publish on login / clear on logout).
final quickActionsService = QuickActionsService();
