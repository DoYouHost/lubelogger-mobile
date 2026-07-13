import 'package:dio/dio.dart';

import '../core/api/api_exceptions.dart';
import '../core/api/endpoints.dart';
import '../core/models/dated_cost.dart';
import '../core/models/gas_record.dart';
import '../core/models/odometer_record.dart';
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

  /// `GET /api/vehicle/gasrecords?vehicleId=` → the vehicle's refuel log.
  Future<List<GasRecord>> gasRecords(int vehicleId) => guard(() async {
        final res = await _dio.get<List<dynamic>>(
          Endpoints.gasRecords,
          queryParameters: {'vehicleId': vehicleId},
        );
        return [
          for (final e in res.data ?? const [])
            if (e is Map<String, dynamic>) GasRecord.fromJson(e),
        ];
      });

  /// Date + cost records for one vehicle from any generic-record [endpoint]
  /// (service / repair / upgrade / tax). Used for the monthly expense chart.
  Future<List<DatedCost>> datedCosts(String endpoint, int vehicleId) =>
      guard(() async {
        final res = await _dio.get<List<dynamic>>(
          endpoint,
          queryParameters: {'vehicleId': vehicleId},
        );
        return [
          for (final e in res.data ?? const [])
            if (e is Map<String, dynamic>) DatedCost.fromJson(e),
        ];
      });

  /// `GET /api/vehicle/odometerrecords?vehicleId=` → odometer readings, source
  /// of the monthly distance line.
  Future<List<OdometerRecord>> odometerRecords(int vehicleId) =>
      guard(() async {
        final res = await _dio.get<List<dynamic>>(
          Endpoints.odometerRecords,
          queryParameters: {'vehicleId': vehicleId},
        );
        return [
          for (final e in res.data ?? const [])
            if (e is Map<String, dynamic>) OdometerRecord.fromJson(e),
        ];
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
