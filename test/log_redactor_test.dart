import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/diagnostics/report_config.dart';

void main() {
  group('lubeloggerRedactor fields', () {
    test('a secret-named field is redacted whatever it holds', () {
      final redactor = lubeloggerRedactor();
      final scrubbed = redactor.scrubFields({
        'x-api-key': 'plain-looking',
        'username': 'anna',
        'emailAddress': 'not an address yet',
        'status': 200,
      });
      expect(scrubbed['x-api-key'], '[REDACTED]');
      expect(scrubbed['username'], '[REDACTED]');
      expect(scrubbed['emailAddress'], '[REDACTED]');
      expect(scrubbed['status'], 200);
    });

    test("the app's own vocabulary survives a server named after it", () {
      // The demo host is `demo`; a control id must not become `[HOST].start`.
      final redactor = lubeloggerRedactor()..remember('demo', '[HOST]');
      final scrubbed = redactor.scrubFields({
        'id': 'setup.demo',
        'to': '/vehicle/12',
        'method': 'POST',
      });
      expect(scrubbed['id'], 'setup.demo');
      expect(scrubbed['to'], '/vehicle/12');
      expect(scrubbed['method'], 'POST');
    });

    test('a request path is not mangled by a server named after a route', () {
      // A host of `vehicle` would otherwise rewrite every LubeLogger endpoint.
      final redactor = lubeloggerRedactor()..remember('vehicle', '[HOST]');
      final scrubbed = redactor.scrubFields({
        'path': '/api/vehicle/gasrecords',
        'surface': 'vehicle.fuel',
      });
      expect(scrubbed['path'], '/api/vehicle/gasrecords');
      expect(scrubbed['surface'], 'vehicle.fuel');
    });

    test('a value of the wrong shape in an app field is still scrubbed', () {
      final redactor = lubeloggerRedactor()..remember('WX12345', '[PLATE]');
      // Not a dotted identifier, so it does not count as ours.
      expect(
        redactor.scrubFields({'id': 'garage.card WX12345'})['id'],
        'garage.card [PLATE]',
      );
    });
  });

  group('lubeloggerRedactor samples', () {
    final redactor = lubeloggerRedactor();

    test('keeps field names, numbers, booleans and dates', () {
      final sample =
          redactor.scrubSample({
                'id': 12,
                'date': '2026-08-06',
                'odometer': '148230',
                'cost': '54.90',
                'isFillToFull': 'True',
                'fuelType': 'Gasoline',
              })
              as Map<String, Object?>;

      expect(sample, {
        'id': 12,
        'date': '2026-08-06',
        'odometer': '148230',
        'cost': '54.90',
        'isFillToFull': 'True',
        'fuelType': 'Gasoline',
      });
    });

    test('replaces what the user wrote with its length', () {
      final sample =
          redactor.scrubSample({
                'licensePlate': 'WX 1234A',
                'notes': 'Oil change before the trip to Anna',
                'make': 'Volkswagen',
              })
              as Map<String, Object?>;

      expect(sample['licensePlate'], '<str:8>');
      expect(sample['notes'], '<str:34>');
      expect(sample['make'], '<str:10>');
    });

    test('a one-word note is the user, not an enum', () {
      // The shape rule cannot tell `Warsztat` from `Gasoline`, so on the fields
      // the user writes into it does not get to try.
      final sample =
          redactor.scrubSample({'notes': 'Warsztat', 'fuelType': 'Gasoline'})
              as Map<String, Object?>;

      expect(sample['notes'], '<str:8>');
      expect(sample['fuelType'], 'Gasoline');
    });

    test('every entry of a free-text list is measured, not just the field', () {
      final sample =
          redactor.scrubSample({
                'tags': ['winter', 'Anna'],
              })
              as Map<String, Object?>;
      expect(sample['tags'], ['<str:6>', '<str:4>']);
    });

    test('user-invented extra fields are masked at depth', () {
      final sample =
          redactor.scrubSample({
                'extraFields': [
                  {'name': 'Insurance policy', 'value': 'PL-88-2210-7781'},
                ],
              })
              as Map<String, Object?>;

      final extra = (sample['extraFields'] as List).first as Map;
      expect(extra['name'], '<str:16>');
      expect(extra['value'], '<str:15>');
    });

    test('a one-word extra field is masked on both halves', () {
      // The user invents the key here as well as the content, so neither half
      // can be argued to be the schema's.
      final sample =
          redactor.scrubSample({
                'extraFields': [
                  {'name': 'Insurer', 'value': 'Warta'},
                ],
              })
              as Map<String, Object?>;

      final extra = (sample['extraFields'] as List).first as Map;
      expect(extra['name'], '<str:7>');
      expect(extra['value'], '<str:5>');
    });

    test("the server's own format settings are kept verbatim", () {
      // `/api/info` is the answer to every "my dates/amounts look wrong", and
      // none of these three survives the shape rule on its own.
      final sample =
          redactor.scrubSample({
                'dateFormat': 'MM/dd/yyyy',
                'decimalSeparator': ',',
                'currencySymbol': 'zł',
              })
              as Map<String, Object?>;

      expect(sample, {
        'dateFormat': 'MM/dd/yyyy',
        'decimalSeparator': ',',
        'currencySymbol': 'zł',
      });
    });
  });
}
