/// The record tabs a vehicle can show, in display order. The Dashboard is not
/// listed here — it is always shown first and is not user-toggleable. Each
/// value's [name] is its stable persistence id for the visible-tabs setting.
enum VehicleTab {
  odometer,
  service,
  repair,
  upgrade,
  fuel,
  tax,
  supply,
  plan,
  reminder,
  note,
  equipment;

  /// The enum value for a persisted [name], or null if it's unknown (e.g. a tab
  /// removed in a later app version).
  static VehicleTab? byName(String name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }
}
