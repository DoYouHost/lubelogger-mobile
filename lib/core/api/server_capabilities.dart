import '../util/version.dart';

/// What the connected LubeLogger server can do.
///
/// The app supports LubeLogger **1.6.9 and 1.7.0**. Diffing the server source
/// between the two tags leaves exactly two differences a client can feel:
///
/// - `DELETE /api/vehicles/delete` first appears in 1.7.0. On 1.6.9 nothing
///   matches the route, so the request comes back 404 — this is the one
///   capability worth asking about before offering the action.
/// - Gas writes: up to 1.6.9 the controller `int.Parse`s `startingSoc` /
///   `endingSoc` with no empty guard, so an omitted field is a 500; 1.7.0 falls
///   back to 20/80. No flag for it — the app always sends both values, which is
///   what both versions accept (see `VehiclesRepository._gasRecordBody`).
///
/// Everything else the app calls — every record CRUD route, uploads, whoami,
/// info, version, extrafields, makebackup — is byte-identical across the two.
class ServerCapabilities {
  const ServerCapabilities({
    required this.version,
    required this.vehicleDelete,
  });

  /// Reads the capability set from `/api/info`'s `currentVersion`. An empty or
  /// unparseable version (info not read yet) enables everything: the check
  /// exists to explain a feature the server lacks, not to withhold one it has,
  /// and an attempt on an older server still lands on the same explanation via
  /// the 404 that `AppErrorCode.unsupportedByServer` carries.
  factory ServerCapabilities.forVersion(String version) => ServerCapabilities(
        version: version,
        vehicleDelete: versionAtLeast(version, vehicleDeleteSince) ?? true,
      );

  /// First version exposing `DELETE /api/vehicles/delete`.
  static const vehicleDeleteSince = '1.7.0';

  /// The server's reported version; empty until `/api/info` answers.
  final String version;

  /// Whether the vehicle-delete endpoint exists (1.7.0+).
  final bool vehicleDelete;
}
