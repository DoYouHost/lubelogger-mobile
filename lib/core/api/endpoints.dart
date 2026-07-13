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

  /// Household vehicles (array of vehicle info).
  static const vehicles = '$apiPrefix/vehicles';
}
