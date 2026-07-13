import 'package:dio/dio.dart';

import '../core/api/api_exceptions.dart';
import '../core/api/endpoints.dart';
import '../core/models/server_info.dart';
import '../core/models/vehicle.dart';
import '../core/models/vehicle_info.dart';

/// Reads vehicles and their aggregated info. Shares the authenticated Dio from
/// [ApiClient]; rebuilt on profile change.
class VehiclesRepository {
  VehiclesRepository(this._dio);

  final Dio _dio;

  /// `GET /api/vehicles` → the household's vehicles.
  Future<List<Vehicle>> list() => guard(() async {
        final res = await _dio.get<List<dynamic>>(Endpoints.vehicles);
        return _parseVehicles(res.data);
      });

  /// `GET /api/vehicle/info?vehicleId=` → aggregated info for one vehicle. The
  /// endpoint returns an array; we take the first (and only) element.
  Future<VehicleInfo> info(int vehicleId) => guard(() async {
        final res = await _dio.get<List<dynamic>>(
          Endpoints.vehicleInfo,
          queryParameters: {'vehicleId': vehicleId},
        );
        final list = res.data ?? const [];
        if (list.isEmpty) {
          throw const ApiException(AppErrorCode.malformedResponse);
        }
        return VehicleInfo.fromJson(list.first as Map<String, dynamic>);
      });

  /// `GET /api/info` → server metadata (currency, locale, date format).
  Future<ServerInfo> serverInfo() => guard(() async {
        final res = await _dio.get<Map<String, dynamic>>(Endpoints.info);
        return ServerInfo.fromJson(res.data ?? const {});
      });

  List<Vehicle> _parseVehicles(List<dynamic>? data) => [
        for (final e in data ?? const [])
          if (e is Map<String, dynamic>) Vehicle.fromJson(e),
      ];
}
