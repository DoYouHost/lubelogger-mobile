import 'package:dio/dio.dart';

import '../core/api/api_exceptions.dart';
import '../core/api/endpoints.dart';
import '../core/models/dated_cost.dart';
import '../core/models/equipment_record.dart';
import '../core/models/gas_record.dart';
import '../core/models/note_record.dart';
import '../core/models/odometer_record.dart';
import '../core/models/plan_record.dart';
import '../core/models/reminder_record.dart';
import '../core/models/server_info.dart';
import '../core/models/supply_record.dart';
import '../core/models/vehicle.dart';
import '../core/models/vehicle_info.dart';
import '../core/models/vehicle_record.dart';

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

  /// `POST /api/vehicle/gasrecords/add?vehicleId=` → add a refuel. All fields go
  /// out as strings (the server string-parses them; our `culture-invariant`
  /// header makes that parse locale-independent, so `.` decimals and ISO dates
  /// are safe). Throws [ApiException] when the server reports `success: false`.
  Future<void> addGasRecord({
    required int vehicleId,
    required DateTime date,
    required num odometer,
    required num fuelConsumed,
    required num cost,
    required bool isFillToFull,
    required bool missedFuelUp,
    String notes = '',
    String tags = '',
  }) =>
      guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          Endpoints.gasRecordsAdd,
          queryParameters: {'vehicleId': vehicleId},
          options: Options(contentType: Headers.jsonContentType),
          data: _gasRecordBody(
            date: date,
            odometer: odometer,
            fuelConsumed: fuelConsumed,
            cost: cost,
            isFillToFull: isFillToFull,
            missedFuelUp: missedFuelUp,
            notes: notes,
            tags: tags,
          ),
        );
        _ensureSuccess(res.data);
      });

  /// `PUT /api/vehicle/gasrecords/update` → update an existing refuel by [id].
  /// No query params; `id` and `vehicleId` travel in the body (the server looks
  /// up the record's own vehicle, but the export model still expects the
  /// field).
  Future<void> updateGasRecord({
    required int vehicleId,
    required int id,
    required DateTime date,
    required num odometer,
    required num fuelConsumed,
    required num cost,
    required bool isFillToFull,
    required bool missedFuelUp,
    String notes = '',
    String tags = '',
  }) =>
      guard(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          Endpoints.gasRecordsUpdate,
          options: Options(contentType: Headers.jsonContentType),
          data: {
            'id': id.toString(),
            'vehicleId': vehicleId.toString(),
            ..._gasRecordBody(
              date: date,
              odometer: odometer,
              fuelConsumed: fuelConsumed,
              cost: cost,
              isFillToFull: isFillToFull,
              missedFuelUp: missedFuelUp,
              notes: notes,
              tags: tags,
            ),
          },
        );
        _ensureSuccess(res.data);
      });

  /// `DELETE /api/vehicle/gasrecords/delete?id=` → delete a refuel.
  Future<void> deleteGasRecord(int id) => guard(() async {
        final res = await _dio.delete<Map<String, dynamic>>(
          Endpoints.gasRecordsDelete,
          queryParameters: {'id': id},
        );
        _ensureSuccess(res.data);
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

  /// Full records for one vehicle from a generic (date + cost) record [kind]
  /// (service / repair / upgrade / tax) — the source for the per-type record
  /// tables. See [datedCosts] for the trimmed shape used by the expense chart.
  Future<List<VehicleRecord>> records(RecordKind kind, int vehicleId) =>
      guard(() async {
        final res = await _dio.get<List<dynamic>>(
          kind.endpoint,
          queryParameters: {'vehicleId': vehicleId},
        );
        return [
          for (final e in res.data ?? const [])
            if (e is Map<String, dynamic>) VehicleRecord.fromJson(e),
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

  /// `POST /api/vehicle/odometerrecords/add?vehicleId=` → add an odometer
  /// reading. `initialOdometer` is omitted so the server defaults it to the
  /// previous reading. Values go out as integer strings (the server
  /// `int.Parse`s them).
  Future<void> addOdometerRecord({
    required int vehicleId,
    required DateTime date,
    required num odometer,
    String notes = '',
    String tags = '',
  }) =>
      guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          Endpoints.odometerRecordsAdd,
          queryParameters: {'vehicleId': vehicleId},
          options: Options(contentType: Headers.jsonContentType),
          data: {
            'date': _isoDate(date),
            'odometer': _intString(odometer),
            'notes': notes,
            'tags': tags,
          },
        );
        _ensureSuccess(res.data);
      });

  /// `PUT /api/vehicle/odometerrecords/update` → update a reading by [id]. The
  /// endpoint requires [initialOdometer], so callers pass the value read back
  /// from the record to preserve it.
  Future<void> updateOdometerRecord({
    required int id,
    required DateTime date,
    required num odometer,
    required num initialOdometer,
    String notes = '',
    String tags = '',
  }) =>
      guard(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          Endpoints.odometerRecordsUpdate,
          options: Options(contentType: Headers.jsonContentType),
          data: {
            'id': id.toString(),
            'date': _isoDate(date),
            'odometer': _intString(odometer),
            'initialOdometer': _intString(initialOdometer),
            'notes': notes,
            'tags': tags,
          },
        );
        _ensureSuccess(res.data);
      });

  /// `DELETE /api/vehicle/odometerrecords/delete?id=` → delete a reading.
  Future<void> deleteOdometerRecord(int id) => guard(() async {
        final res = await _dio.delete<Map<String, dynamic>>(
          Endpoints.odometerRecordsDelete,
          queryParameters: {'id': id},
        );
        _ensureSuccess(res.data);
      });

  /// `GET /api/vehicle/supplyrecords?vehicleId=` → supply / part records.
  Future<List<SupplyRecord>> supplyRecords(int vehicleId) =>
      _list(Endpoints.supplyRecords, vehicleId, SupplyRecord.fromJson);

  /// `GET /api/vehicle/planrecords?vehicleId=` → planner items.
  Future<List<PlanRecord>> planRecords(int vehicleId) =>
      _list(Endpoints.planRecords, vehicleId, PlanRecord.fromJson);

  /// `GET /api/vehicle/reminders?vehicleId=` → reminders (with computed urgency).
  Future<List<ReminderRecord>> reminders(int vehicleId) =>
      _list(Endpoints.reminders, vehicleId, ReminderRecord.fromJson);

  /// `GET /api/vehicle/notes?vehicleId=` → free-text notes.
  Future<List<NoteRecord>> notes(int vehicleId) =>
      _list(Endpoints.notes, vehicleId, NoteRecord.fromJson);

  /// `GET /api/vehicle/equipmentrecords?vehicleId=` → equipment items.
  Future<List<EquipmentRecord>> equipmentRecords(int vehicleId) =>
      _list(Endpoints.equipmentRecords, vehicleId, EquipmentRecord.fromJson);

  /// Fetch and parse a `?vehicleId=` list endpoint into typed records, skipping
  /// any element that isn't a JSON object.
  Future<List<T>> _list<T>(
    String endpoint,
    int vehicleId,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      guard(() async {
        final res = await _dio.get<List<dynamic>>(
          endpoint,
          queryParameters: {'vehicleId': vehicleId},
        );
        return [
          for (final e in res.data ?? const [])
            if (e is Map<String, dynamic>) fromJson(e),
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

  /// Shared field set for a gas record write (add or update); all values go out
  /// as strings, per the server's string-parsed export model.
  ///
  /// `startingSoc`/`endingSoc` (EV state-of-charge, unused by this app) are
  /// unconditionally `int.Parse`d server-side with no null/empty guard — an
  /// absent field throws a 500 ("input string '' was not in a correct
  /// format"). Send `"0"` so a non-EV write never trips that.
  static Map<String, String> _gasRecordBody({
    required DateTime date,
    required num odometer,
    required num fuelConsumed,
    required num cost,
    required bool isFillToFull,
    required bool missedFuelUp,
    required String notes,
    required String tags,
  }) =>
      {
        'date': _isoDate(date),
        'odometer': odometer.toString(),
        'fuelConsumed': fuelConsumed.toString(),
        'cost': cost.toString(),
        'isFillToFull': isFillToFull.toString(),
        'missedFuelUp': missedFuelUp.toString(),
        'startingSoc': '0',
        'endingSoc': '0',
        'notes': notes,
        'tags': tags,
      };

  /// Odometer values are stored as integers server-side (`int.Parse`); emit a
  /// whole-number string so a `317240.0`-style double never reaches the parser.
  static String _intString(num value) => value.round().toString();

  /// `yyyy-MM-dd` — unambiguous for the server's invariant `DateTime.Parse`.
  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// A write's `OperationResponse` reports failure in-band with HTTP 200
  /// (`{success:false, message}`); surface it as an [ApiException].
  static void _ensureSuccess(Map<String, dynamic>? body) {
    if (body != null && body['success'] == false) {
      throw ApiException(
        AppErrorCode.badResponse,
        detail: body['message'] as String?,
      );
    }
  }
}
