import 'package:dio/dio.dart';

import '../core/api/api_exceptions.dart';
import '../core/api/endpoints.dart';
import '../core/diagnostics/diagnostic_recorder.dart';
import '../core/diagnostics/log_event.dart';
import '../core/auth/whoami.dart';
import '../core/models/attachment.dart';
import '../core/models/dated_cost.dart';
import '../core/models/equipment_record.dart';
import '../core/models/gas_record.dart';
import '../core/models/note_record.dart';
import '../core/models/odometer_record.dart';
import '../core/models/plan_record.dart';
import '../core/models/reminder_record.dart';
import '../core/models/server_info.dart';
import '../core/models/server_version.dart';
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

  /// `POST /api/vehicles/add` → create a vehicle, returning its new id (or null
  /// if the server omitted it). The app always uses the `LicensePlate`
  /// identifier, so [licensePlate] is required; [fuelType] must be one of
  /// `Gasoline`, `Diesel`, `Electric`. Values go out as strings, matching the
  /// server's string-parsed import model.
  Future<int?> addVehicle({
    required int year,
    required String make,
    required String model,
    required String licensePlate,
    required String fuelType,
    bool useHours = false,
    bool odometerOptional = false,
    String tags = '',
  }) =>
      guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          Endpoints.vehiclesAdd,
          options: Options(contentType: Headers.jsonContentType),
          data: _vehicleBody(
            year: year,
            make: make,
            model: model,
            licensePlate: licensePlate,
            fuelType: fuelType,
            useHours: useHours,
            odometerOptional: odometerOptional,
            tags: tags,
            identifier: 'LicensePlate',
            extraFields: const [],
          ),
        );
        _ensureSuccess(res.data);
        final extra = res.data?['additionalData'];
        if (extra is Map) return (extra['vehicleId'] as num?)?.toInt();
        return null;
      });

  /// `PUT /api/vehicles/update` → update an existing vehicle by [id]. The server
  /// replaces the identifier and extra fields with what's sent, so pass the
  /// vehicle's existing [identifier]/[extraFields] to preserve them. [fuelType]
  /// must be one of `Gasoline`, `Diesel`, `Electric`.
  ///
  /// Server caveat: it only *sets* the diesel/electric flag and never clears it,
  /// so switching a vehicle back to Gasoline (or Diesel↔Electric) won't take
  /// effect server-side — nothing the client can do about it.
  Future<void> updateVehicle({
    required int id,
    required int year,
    required String make,
    required String model,
    required String licensePlate,
    required String fuelType,
    required String identifier,
    required List<Map<String, dynamic>> extraFields,
    bool useHours = false,
    bool odometerOptional = false,
    String tags = '',
  }) =>
      _update(Endpoints.vehiclesUpdate, {
        'id': id.toString(),
        ..._vehicleBody(
          year: year,
          make: make,
          model: model,
          licensePlate: licensePlate,
          fuelType: fuelType,
          useHours: useHours,
          odometerOptional: odometerOptional,
          tags: tags,
          identifier: identifier,
          extraFields: extraFields,
        ),
      });

  /// `DELETE /api/vehicles/delete?id=` → delete a vehicle (LubeLogger 1.7.0+).
  /// The server cascades, wiping all of the vehicle's records first, so this is
  /// irreversible. Surfaces [AppErrorCode.unauthorized] when the key's household
  /// lacks the `Delete` permission (the server answers 401, not a logout signal).
  Future<void> deleteVehicle(int id) => _delete(Endpoints.vehiclesDelete, id);

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
        return _parseAll(res.data, GasRecord.fromJson, Endpoints.gasRecords);
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
    List<Attachment> files = const [],
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
            files: files,
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
    List<Attachment> files = const [],
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
              files: files,
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
        return _parseAll(res.data, DatedCost.fromJson, endpoint);
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
        return _parseAll(res.data, VehicleRecord.fromJson, kind.endpoint);
      });

  /// `POST {kind}/add?vehicleId=` → add a generic (service / repair / upgrade /
  /// tax) record. The server requires date, description and cost — plus
  /// odometer for the odometer-bearing kinds; pass [odometer] as null for tax so
  /// it's omitted. Values go out as strings (odometer as a whole number for the
  /// server's `int.Parse`, cost as a plain `.`-decimal).
  Future<void> addRecord({
    required RecordKind kind,
    required int vehicleId,
    required DateTime date,
    required String description,
    required num cost,
    num? odometer,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
  }) =>
      guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          kind.addEndpoint,
          queryParameters: {'vehicleId': vehicleId},
          options: Options(contentType: Headers.jsonContentType),
          data: _recordBody(
            date: date,
            description: description,
            cost: cost,
            odometer: odometer,
            notes: notes,
            tags: tags,
            files: files,
          ),
        );
        _ensureSuccess(res.data);
      });

  /// `PUT {kind}/update` → update a generic record by [id]. No query params; the
  /// server resolves the record's vehicle from [id], so `vehicleId` isn't sent.
  Future<void> updateRecord({
    required RecordKind kind,
    required int id,
    required DateTime date,
    required String description,
    required num cost,
    num? odometer,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
  }) =>
      guard(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          kind.updateEndpoint,
          options: Options(contentType: Headers.jsonContentType),
          data: {
            'id': id.toString(),
            ..._recordBody(
              date: date,
              description: description,
              cost: cost,
              odometer: odometer,
              notes: notes,
              tags: tags,
              files: files,
            ),
          },
        );
        _ensureSuccess(res.data);
      });

  /// `DELETE {kind}/delete?id=` → delete a generic record.
  Future<void> deleteRecord(RecordKind kind, int id) => guard(() async {
        final res = await _dio.delete<Map<String, dynamic>>(
          kind.deleteEndpoint,
          queryParameters: {'id': id},
        );
        _ensureSuccess(res.data);
      });

  // ── Supply records ──────────────────────────────────────────────────────
  // Server requires date, description, quantity and cost; part number/supplier
  // are optional. Quantity and cost are decimals.
  Future<void> addSupplyRecord({
    required int vehicleId,
    required DateTime date,
    required String description,
    required num partQuantity,
    required num cost,
    String partNumber = '',
    String partSupplier = '',
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
  }) =>
      _add(Endpoints.supplyRecordsAdd, vehicleId,
          _supplyBody(date, description, partQuantity, cost, partNumber,
              partSupplier, notes, tags, files));

  Future<void> updateSupplyRecord({
    required int id,
    required DateTime date,
    required String description,
    required num partQuantity,
    required num cost,
    String partNumber = '',
    String partSupplier = '',
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
  }) =>
      _update(Endpoints.supplyRecordsUpdate, {
        'id': id.toString(),
        ..._supplyBody(date, description, partQuantity, cost, partNumber,
            partSupplier, notes, tags, files),
      });

  Future<void> deleteSupplyRecord(int id) =>
      _delete(Endpoints.supplyRecordsDelete, id);

  // ── Plan (planner) records ──────────────────────────────────────────────
  // Server requires description, cost, type, priority and progress; there is no
  // date/odometer/tags. The API refuses to set Progress.done (see PlanProgress).
  Future<void> addPlanRecord({
    required int vehicleId,
    required String description,
    required num cost,
    required PlanType type,
    required PlanPriority priority,
    required PlanProgress progress,
    String notes = '',
    List<Attachment> files = const [],
  }) =>
      _add(Endpoints.planRecordsAdd, vehicleId,
          _planBody(description, cost, type, priority, progress, notes, files));

  Future<void> updatePlanRecord({
    required int id,
    required String description,
    required num cost,
    required PlanType type,
    required PlanPriority priority,
    required PlanProgress progress,
    String notes = '',
    List<Attachment> files = const [],
  }) =>
      _update(Endpoints.planRecordsUpdate, {
        'id': id.toString(),
        ..._planBody(description, cost, type, priority, progress, notes, files),
      });

  Future<void> deletePlanRecord(int id) =>
      _delete(Endpoints.planRecordsDelete, id);

  // ── Reminders ───────────────────────────────────────────────────────────
  // Server requires description and metric; the due date and/or odometer are
  // required per the metric (date → dueDate, odometer → dueOdometer, both →
  // both). Urgency is computed server-side, never sent.
  Future<void> addReminder({
    required int vehicleId,
    required String description,
    required ReminderMetric metric,
    DateTime? dueDate,
    num? dueOdometer,
    String notes = '',
    String tags = '',
  }) =>
      _add(Endpoints.remindersAdd, vehicleId,
          _reminderBody(description, metric, dueDate, dueOdometer, notes, tags));

  Future<void> updateReminder({
    required int id,
    required String description,
    required ReminderMetric metric,
    DateTime? dueDate,
    num? dueOdometer,
    String notes = '',
    String tags = '',
  }) =>
      _update(Endpoints.remindersUpdate, {
        'id': id.toString(),
        ..._reminderBody(description, metric, dueDate, dueOdometer, notes, tags),
      });

  Future<void> deleteReminder(int id) =>
      _delete(Endpoints.remindersDelete, id);

  // ── Notes ───────────────────────────────────────────────────────────────
  // Server requires description (title) and noteText (body).
  Future<void> addNote({
    required int vehicleId,
    required String description,
    required String noteText,
    bool pinned = false,
    String tags = '',
    List<Attachment> files = const [],
  }) =>
      _add(Endpoints.notesAdd, vehicleId,
          _noteBody(description, noteText, pinned, tags, files));

  Future<void> updateNote({
    required int id,
    required String description,
    required String noteText,
    bool pinned = false,
    String tags = '',
    List<Attachment> files = const [],
  }) =>
      _update(Endpoints.notesUpdate, {
        'id': id.toString(),
        ..._noteBody(description, noteText, pinned, tags, files),
      });

  Future<void> deleteNote(int id) => _delete(Endpoints.notesDelete, id);

  // ── Equipment ───────────────────────────────────────────────────────────
  // Server requires description and isEquipped.
  Future<void> addEquipmentRecord({
    required int vehicleId,
    required String description,
    required bool isEquipped,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
  }) =>
      _add(Endpoints.equipmentRecordsAdd, vehicleId,
          _equipmentBody(description, isEquipped, notes, tags, files));

  Future<void> updateEquipmentRecord({
    required int id,
    required String description,
    required bool isEquipped,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
  }) =>
      _update(Endpoints.equipmentRecordsUpdate, {
        'id': id.toString(),
        ..._equipmentBody(description, isEquipped, notes, tags, files),
      });

  Future<void> deleteEquipmentRecord(int id) =>
      _delete(Endpoints.equipmentRecordsDelete, id);

  /// `GET /api/vehicle/odometerrecords?vehicleId=` → odometer readings, source
  /// of the monthly distance line.
  Future<List<OdometerRecord>> odometerRecords(int vehicleId) =>
      guard(() async {
        final res = await _dio.get<List<dynamic>>(
          Endpoints.odometerRecords,
          queryParameters: {'vehicleId': vehicleId},
        );
        return _parseAll(
          res.data,
          OdometerRecord.fromJson,
          Endpoints.odometerRecords,
        );
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
    List<Attachment> files = const [],
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
            'files': _filesJson(files),
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
    List<Attachment> files = const [],
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
            'files': _filesJson(files),
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
        return _parseAll(res.data, fromJson, endpoint);
      });

  /// `POST {endpoint}?vehicleId=` with a JSON [body] → add a record. Shared by
  /// the per-type add methods (all uniform-CRUD endpoints, see §6).
  Future<void> _add(String endpoint, int vehicleId, Map<String, dynamic> body) =>
      guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          endpoint,
          queryParameters: {'vehicleId': vehicleId},
          options: Options(contentType: Headers.jsonContentType),
          data: body,
        );
        _ensureSuccess(res.data);
      });

  /// `PUT {endpoint}` with a JSON [body] (including `id`) → update a record. The
  /// server resolves the record's vehicle from its id, so no query params.
  Future<void> _update(String endpoint, Map<String, dynamic> body) =>
      guard(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          endpoint,
          options: Options(contentType: Headers.jsonContentType),
          data: body,
        );
        _ensureSuccess(res.data);
      });

  /// `DELETE {endpoint}?id=` → delete a record by [id].
  Future<void> _delete(String endpoint, int id) => guard(() async {
        final res = await _dio.delete<Map<String, dynamic>>(
          endpoint,
          queryParameters: {'id': id},
        );
        _ensureSuccess(res.data);
      });

  /// `POST /api/documents/upload` (multipart, field `documents`) → upload one or
  /// more files and return the resulting [Attachment]s, which the caller stores
  /// in a record's `files` list on add/update.
  Future<List<Attachment>> uploadDocuments(
    List<({String path, String name})> files,
  ) =>
      guard(() async {
        final form = FormData();
        for (final f in files) {
          form.files.add(MapEntry(
            'documents',
            await MultipartFile.fromFile(f.path, filename: f.name),
          ));
        }
        final res = await _dio.post<List<dynamic>>(
          Endpoints.documentsUpload,
          data: form,
        );
        return [
          for (final e in res.data ?? const [])
            if (e is Map<String, dynamic>) Attachment.fromJson(e),
        ];
      });

  /// Download an attachment to [savePath]. [location] is a record's
  /// `files[].location` (e.g. `/documents/<guid>.pdf`), resolved against the
  /// server base URL; the authenticated client's `x-api-key` is accepted for
  /// `/documents` paths (see the server's static-file auth).
  Future<void> downloadDocument(String location, String savePath) =>
      guard(() async {
        await _dio.download(location, savePath);
      });

  /// `GET /api/info` → server metadata (currency, locale, date format).
  Future<ServerInfo> serverInfo() => guard(() async {
        final res = await _dio.get<Map<String, dynamic>>(Endpoints.info);
        return ServerInfo.fromJson(res.data ?? const {});
      });

  /// `GET /api/whoami` → the authenticated account (username, email, roles).
  Future<WhoAmI> whoAmI() => guard(() async {
        final res = await _dio.get<Map<String, dynamic>>(Endpoints.whoami);
        return WhoAmI.fromJson(res.data ?? const {});
      });

  /// `GET /api/version?checkForUpdate=1` → running vs. latest release version.
  Future<ServerVersion> serverVersion() => guard(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          Endpoints.version,
          queryParameters: {'checkForUpdate': true},
        );
        return ServerVersion.fromJson(res.data ?? const {});
      });

  /// `GET /api/makebackup` → trigger a server-side backup (root only), returning
  /// the created file's path. Throws (403) for non-root callers.
  Future<String> makeBackup() => guard(() async {
        final res = await _dio.get<String>(Endpoints.makeBackup);
        return res.data ?? '';
      });

  List<Vehicle> _parseVehicles(List<dynamic>? data) =>
      _parseAll(data, Vehicle.fromJson, Endpoints.vehicles);

  /// Turns a list endpoint's body into typed records, skipping any element that
  /// is not a JSON object — and saying so in the diagnostic log when it does.
  ///
  /// A dropped element is the quietest failure the app has: the screen renders
  /// the records that did parse, so "three of my fuel-ups are missing" arrives
  /// as a screenshot of a working list. The HTTP probe reports how many the
  /// server sent; only this knows how many survived.
  List<T> _parseAll<T>(
    List<dynamic>? data,
    T Function(Map<String, dynamic>) fromJson,
    String endpoint,
  ) {
    final received = data ?? const [];
    final parsed = [
      for (final e in received)
        if (e is Map<String, dynamic>) fromJson(e),
    ];
    if (parsed.length != received.length) {
      DiagnosticRecorder.active?.add(
        LogSource.http,
        'records_dropped',
        lvl: LogLevel.warn,
        fields: {
          'path': endpoint,
          'n': received.length,
          'kept': parsed.length,
        },
      );
    }
    return parsed;
  }

  /// Shared field set for a gas record write (add or update); all values go out
  /// as strings, per the server's string-parsed export model.
  ///
  /// `startingSoc`/`endingSoc` (EV state-of-charge, unused by this app) were
  /// unconditionally `int.Parse`d server-side with no null/empty guard before
  /// LubeLogger 1.7.0 — an absent field threw a 500 ("input string '' was not in
  /// a correct format"). 1.7.0 defaults empty to 20/80, but we still send `"0"`
  /// so a non-EV write never trips the bug on older servers.
  static Map<String, dynamic> _gasRecordBody({
    required DateTime date,
    required num odometer,
    required num fuelConsumed,
    required num cost,
    required bool isFillToFull,
    required bool missedFuelUp,
    required String notes,
    required String tags,
    required List<Attachment> files,
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
        'files': _filesJson(files),
      };

  /// Shared field set for a generic record write (add or update). Odometer is
  /// omitted when null (tax records have none); it goes out as a whole-number
  /// string for the server's `int.Parse`, cost as a plain `.`-decimal.
  static Map<String, dynamic> _recordBody({
    required DateTime date,
    required String description,
    required num cost,
    required num? odometer,
    required String notes,
    required String tags,
    required List<Attachment> files,
  }) =>
      {
        'date': _isoDate(date),
        if (odometer != null) 'odometer': _intString(odometer),
        'description': description,
        'cost': cost.toString(),
        'notes': notes,
        'tags': tags,
        'files': _filesJson(files),
      };

  /// Supply write fields. Quantity and cost are decimals; part number/supplier
  /// are free-form and may be empty.
  static Map<String, dynamic> _supplyBody(
    DateTime date,
    String description,
    num partQuantity,
    num cost,
    String partNumber,
    String partSupplier,
    String notes,
    String tags,
    List<Attachment> files,
  ) =>
      {
        'date': _isoDate(date),
        'description': description,
        'partNumber': partNumber,
        'partSupplier': partSupplier,
        'partQuantity': partQuantity.toString(),
        'cost': cost.toString(),
        'notes': notes,
        'tags': tags,
        'files': _filesJson(files),
      };

  /// Plan write fields. Enums go out as their .NET names; there is no
  /// date/odometer/tags. The server sets DateCreated/DateModified itself.
  static Map<String, dynamic> _planBody(
    String description,
    num cost,
    PlanType type,
    PlanPriority priority,
    PlanProgress progress,
    String notes,
    List<Attachment> files,
  ) =>
      {
        'description': description,
        'cost': cost.toString(),
        'type': type.wireName,
        'priority': priority.wireName,
        'progress': progress.wireName,
        'notes': notes,
        'files': _filesJson(files),
      };

  /// Reminder write fields. Metric goes out as its .NET name; the due date and
  /// odometer are sent only when set (the caller supplies whichever the metric
  /// requires). Urgency is computed server-side and never sent.
  static Map<String, String> _reminderBody(
    String description,
    ReminderMetric metric,
    DateTime? dueDate,
    num? dueOdometer,
    String notes,
    String tags,
  ) =>
      {
        'description': description,
        'metric': metric.wireName,
        if (dueDate != null) 'dueDate': _isoDate(dueDate),
        if (dueOdometer != null) 'dueOdometer': _intString(dueOdometer),
        'notes': notes,
        'tags': tags,
      };

  /// Note write fields: a title ([description]) + body ([noteText]) + pin flag.
  static Map<String, dynamic> _noteBody(
    String description,
    String noteText,
    bool pinned,
    String tags,
    List<Attachment> files,
  ) =>
      {
        'description': description,
        'noteText': noteText,
        'pinned': pinned.toString(),
        'tags': tags,
        'files': _filesJson(files),
      };

  /// Equipment write fields: a name ([description]) + equipped flag.
  static Map<String, dynamic> _equipmentBody(
    String description,
    bool isEquipped,
    String notes,
    String tags,
    List<Attachment> files,
  ) =>
      {
        'description': description,
        'isEquipped': isEquipped.toString(),
        'notes': notes,
        'tags': tags,
        'files': _filesJson(files),
      };

  /// Shared field set for a vehicle write (add or update). All values go out as
  /// strings (bools as "true"/"false", which the server's `bool.Parse` accepts),
  /// matching the string-parsed `VehicleImportModel`.
  static Map<String, dynamic> _vehicleBody({
    required int year,
    required String make,
    required String model,
    required String licensePlate,
    required String fuelType,
    required bool useHours,
    required bool odometerOptional,
    required String tags,
    required String identifier,
    required List<Map<String, dynamic>> extraFields,
  }) =>
      {
        'year': year.toString(),
        'make': make,
        'model': model,
        'licensePlate': licensePlate,
        'identifier': identifier,
        'fuelType': fuelType,
        'useEngineHours': useHours.toString(),
        'odometerOptional': odometerOptional.toString(),
        'tags': tags,
        'extraFields': extraFields,
      };

  /// Serialize a record's attachments for a write body's `files` field.
  static List<Map<String, dynamic>> _filesJson(List<Attachment> files) =>
      [for (final f in files) f.toJson()];

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
