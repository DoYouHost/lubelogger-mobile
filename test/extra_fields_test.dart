import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/models/extra_field.dart';
import 'package:lubelogger_mobile/core/models/plan_record.dart';
import 'package:lubelogger_mobile/core/models/vehicle_record.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';

/// Captures the request a repository call makes, so the assertions are about
/// what actually goes on the wire — the layer where omitting a field silently
/// erases server-side data.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.response);

  final Object? response;
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({VehiclesRepository repo, _CapturingAdapter adapter}) _repo([
  Object? response,
]) {
  final adapter = _CapturingAdapter(
    response ?? {'success': true, 'message': ''},
  );
  final dio = Dio(BaseOptions(baseUrl: 'http://server'))
    ..httpClientAdapter = adapter;
  return (repo: VehiclesRepository(dio), adapter: adapter);
}

Map<String, dynamic> _body(_CapturingAdapter adapter) =>
    adapter.captured!.data as Map<String, dynamic>;

List<dynamic> _sentExtraFields(_CapturingAdapter adapter) =>
    _body(adapter)['extraFields'] as List<dynamic>;

void main() {
  group('wire format', () {
    test('reads a record\'s integer fieldType and a template\'s name', () {
      final fromRecord = ExtraField.fromJson({
        'name': 'Workshop',
        'value': 'Demo Motors',
        'isRequired': true,
        'fieldType': 2,
      });
      final fromTemplate = ExtraField.fromJson({
        'name': 'Workshop',
        'isRequired': true,
        'fieldType': 'Decimal',
      });

      expect(fromRecord.fieldType, ExtraFieldType.decimal);
      expect(fromRecord.value, 'Demo Motors');
      expect(fromTemplate.fieldType, ExtraFieldType.decimal);
      expect(fromTemplate.value, isEmpty);
      expect(fromTemplate.isRequired, isTrue);
    });

    test('reads isRequired whether it arrives as a bool or a string', () {
      expect(
        ExtraField.fromJson({'name': 'a', 'isRequired': 'True'}).isRequired,
        isTrue,
      );
      expect(
        ExtraField.fromJson({'name': 'a', 'isRequired': false}).isRequired,
        isFalse,
      );
    });

    test('writes fieldType as an integer and isRequired as a real bool', () {
      final json = const ExtraField(
        name: 'Warranty until',
        value: '2027-01-01',
        isRequired: true,
        fieldType: ExtraFieldType.date,
      ).toJson();

      expect(json['fieldType'], 3);
      expect(json['isRequired'], isA<bool>());
      expect(json['value'], '2027-01-01');
    });

    test('echoes back a fieldType this app does not model', () {
      final field = ExtraField.fromJson({'name': 'a', 'fieldType': 99});

      expect(field.fieldType, ExtraFieldType.text);
      expect(field.toJson()['fieldType'], 99);
    });
  });

  group('mergeExtraFields', () {
    const stored = [
      ExtraField(name: 'Workshop', value: 'Demo Motors'),
      ExtraField(name: 'Removed field', value: 'stale'),
    ];

    test('passes the record through when the template is unknown', () {
      expect(mergeExtraFields(stored, null), stored);
    });

    test('clears the record when the template is empty', () {
      expect(mergeExtraFields(stored, const []), isEmpty);
    });

    test('offers the whole template for a record with no fields', () {
      const template = [ExtraField(name: 'Workshop', isRequired: true)];

      expect(mergeExtraFields(const [], template), template);
    });

    test('keeps values, drops stale fields, and follows template order', () {
      const template = [
        ExtraField(name: 'Warranty until', fieldType: ExtraFieldType.date),
        ExtraField(name: 'Workshop', isRequired: true),
      ];

      final merged = mergeExtraFields(stored, template);

      expect(merged.map((f) => f.name), ['Warranty until', 'Workshop']);
      expect(merged.last.value, 'Demo Motors');
      expect(merged.first.value, isEmpty);
    });

    test('takes required-ness and kind from the template, not the record', () {
      // Records saved by the web UI carry no fieldType at all, so it lands as
      // Text there — the template is the only trustworthy source.
      const stored = [
        ExtraField(name: 'Mileage check', value: '12', isRequired: true),
      ];
      const template = [
        ExtraField(name: 'Mileage check', fieldType: ExtraFieldType.number),
      ];

      final merged = mergeExtraFields(stored, template);

      expect(merged.single.fieldType, ExtraFieldType.number);
      expect(merged.single.isRequired, isFalse);
      expect(merged.single.value, '12');
    });
  });

  group('write bodies carry extra fields', () {
    const fields = [
      ExtraField(name: 'Workshop', value: 'Demo Motors', isRequired: true),
    ];

    test('a generic record update sends them', () async {
      final (:repo, :adapter) = _repo();

      await repo.updateRecord(
        kind: RecordKind.service,
        id: 7,
        date: DateTime(2026, 4, 5),
        description: 'Oil change',
        cost: 58,
        odometer: 66800,
        extraFields: fields,
      );

      expect(_sentExtraFields(adapter), [
        {
          'name': 'Workshop',
          'value': 'Demo Motors',
          'isRequired': true,
          'fieldType': 0,
        },
      ]);
    });

    test('every editable record type sends the key, never omits it', () async {
      // Omission is what erased them: the server replaces the stored list with
      // whatever arrives, and an absent key deserializes to an empty list.
      final calls = <String, Future<void> Function(VehiclesRepository)>{
        'gas': (r) => r.updateGasRecord(
              vehicleId: 1,
              id: 1,
              date: DateTime(2026, 4, 5),
              odometer: 1,
              fuelConsumed: 1,
              cost: 1,
              isFillToFull: true,
              missedFuelUp: false,
              extraFields: fields,
            ),
        'odometer': (r) => r.updateOdometerRecord(
              id: 1,
              date: DateTime(2026, 4, 5),
              odometer: 2,
              initialOdometer: 1,
              extraFields: fields,
            ),
        'supply': (r) => r.updateSupplyRecord(
              id: 1,
              date: DateTime(2026, 4, 5),
              description: 'Filter',
              partQuantity: 1,
              cost: 1,
              extraFields: fields,
            ),
        'plan': (r) => r.updatePlanRecord(
              id: 1,
              description: 'Brakes',
              cost: 1,
              type: PlanType.service,
              priority: PlanPriority.normal,
              progress: PlanProgress.backlog,
              extraFields: fields,
            ),
        'note': (r) => r.updateNote(
              id: 1,
              description: 'Title',
              noteText: 'Body',
              extraFields: fields,
            ),
        'equipment': (r) => r.updateEquipmentRecord(
              id: 1,
              description: 'Roof rack',
              isEquipped: true,
              extraFields: fields,
            ),
        'vehicle': (r) => r.updateVehicle(
              id: 1,
              year: 2019,
              make: 'Toyota',
              model: 'Corolla',
              licensePlate: 'DEMO-101',
              fuelType: 'Gasoline',
              identifier: 'LicensePlate',
              extraFields: fields,
            ),
      };

      for (final entry in calls.entries) {
        final (:repo, :adapter) = _repo();
        await entry.value(repo);
        expect(
          _sentExtraFields(adapter),
          hasLength(1),
          reason: '${entry.key} dropped its extra fields',
        );
      }
    });

    test('an odometer update resends the equipment link', () async {
      final (:repo, :adapter) = _repo();

      await repo.updateOdometerRecord(
        id: 1,
        date: DateTime(2026, 4, 5),
        odometer: 2,
        initialOdometer: 1,
        equipmentRecordId: '3 4',
      );

      expect(_body(adapter)['equipmentRecordId'], '3 4');
    });
  });

  group('extraFieldTemplates', () {
    test('keys templates by record type and skips unknown ones', () async {
      final (:repo, :adapter) = _repo([
        {
          'recordType': 'ServiceRecord',
          'extraFields': [
            {'name': 'Workshop', 'isRequired': true, 'fieldType': 'Text'},
          ],
        },
        {'recordType': 'InspectionRecord', 'extraFields': <Object>[]},
      ]);

      final templates = await repo.extraFieldTemplates();

      expect(templates.keys, [ExtraFieldRecordType.service]);
      expect(templates[ExtraFieldRecordType.service]!.single.isRequired, isTrue);
    });
  });
}
