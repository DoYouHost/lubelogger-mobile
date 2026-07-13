/// LubeLogger REST API endpoints in one place.
///
/// Contract: LubeLogger (CarCareTracker) `x-api-key` API, verified against a
/// live v1.6.9 instance + the server source (`reference/lubelog`). All paths
/// are under `/api` on the server root (no version prefix). See
/// `reference/LUBELOGGER-API.md` for the full contract, including the
/// `culture-invariant` header requirement and the overloaded-401 behaviour.
abstract final class Endpoints {
  static const apiPrefix = '/api';

  /// Identity of the authenticated caller: `{username, emailAddress, isAdmin,
  /// isRoot}`. Cheapest authenticated read — used to validate credentials on
  /// the login screen.
  static const whoami = '$apiPrefix/whoami';

  /// Server info: `{currentVersion, locale, currencySymbol, decimalSeparator,
  /// dateFormat}`. No auth-sensitive data; useful for a version/locale banner.
  static const info = '$apiPrefix/info';

  /// Household vehicles (array of [Vehicle]).
  static const vehicles = '$apiPrefix/vehicles';

  /// Aggregated info for one vehicle: `?vehicleId=`. Returns an ARRAY of
  /// VehicleInfo (odometer, record counts/costs, reminder counts) — one element
  /// even for a single vehicle.
  static const vehicleInfo = '$apiPrefix/vehicle/info';

  /// Refuel log for one vehicle: `?vehicleId=`. Returns an array of gas records.
  /// The server's per-record `fuelEconomy` is ignored (see [GasRecord]); the
  /// app recomputes economy locally from odometer + fuel.
  static const gasRecords = '$apiPrefix/vehicle/gasrecords';

  // Record types with a date + cost, aggregated into the monthly expense chart.
  static const serviceRecords = '$apiPrefix/vehicle/servicerecords';
  static const repairRecords = '$apiPrefix/vehicle/repairrecords';
  static const upgradeRecords = '$apiPrefix/vehicle/upgraderecords';
  static const taxRecords = '$apiPrefix/vehicle/taxrecords';

  /// Odometer readings: `?vehicleId=`. Source of the monthly distance line.
  static const odometerRecords = '$apiPrefix/vehicle/odometerrecords';
}
