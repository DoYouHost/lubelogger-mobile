import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/diagnostics/log_redactor.dart';

void main() {
  group('LogRedactor secrets', () {
    test('a registered value is cut wherever it appears', () {
      final redactor = LogRedactor()..remember('abc123secret', '[APIKEY]');
      expect(
        redactor.scrubString('server said: key abc123secret is invalid'),
        'server said: key [APIKEY] is invalid',
      );
    });

    test('a value shorter than four characters is ignored', () {
      final redactor = LogRedactor()..remember('key', '[APIKEY]');
      expect(redactor.scrubString('monkey'), 'monkey');
    });

    test('the host goes, the scheme and port stay', () {
      final redactor = LogRedactor();
      expect(
        redactor.scrubString('GET https://lube.example.com:8080/api/vehicles'),
        'GET https://[HOST]:8080/api/vehicles',
      );
    });

    test('a bare host is cut once registered', () {
      final redactor = LogRedactor()..rememberServerUrl('https://lube.lan');
      expect(
        redactor.scrubString("Failed host lookup: 'lube.lan'"),
        "Failed host lookup: '[HOST]'",
      );
    });

    test('e-mails, JWTs, query tokens and IPs are cut by shape', () {
      final redactor = LogRedactor();
      expect(redactor.scrubString('me@example.com'), '[EMAIL]');
      expect(
        redactor.scrubString('Bearer eyJhbGciOiJIUzI1NiJ9.body.sig'),
        'Bearer [JWT]',
      );
      expect(
        redactor.scrubString('/api/x?api_key=abcdef&page=2'),
        '/api/x?api_key=[REDACTED]&page=2',
      );
      expect(redactor.scrubString('connect to 192.168.1.44'),
          'connect to [IP]');
    });

    test('a secret-named field is redacted whatever it holds', () {
      final redactor = LogRedactor();
      final scrubbed = redactor.scrubFields({
        'x-api-key': 'plain-looking',
        'username': 'anna',
        'status': 200,
      });
      expect(scrubbed['x-api-key'], '[REDACTED]');
      expect(scrubbed['username'], '[REDACTED]');
      expect(scrubbed['status'], 200);
    });

    test('an absent secret stays absent instead of reading as configured', () {
      expect(LogRedactor().scrubFields({'token': null})['token'], isNull);
    });

    test("the app's own vocabulary survives a server named after it", () {
      // The demo host is `demo`; a control id must not become `[HOST].start`.
      final redactor = LogRedactor()..remember('demo', '[HOST]');
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
      final redactor = LogRedactor()..remember('vehicle', '[HOST]');
      final scrubbed = redactor.scrubFields({
        'path': '/api/vehicle/gasrecords',
        'surface': 'vehicle.fuel',
      });
      expect(scrubbed['path'], '/api/vehicle/gasrecords');
      expect(scrubbed['surface'], 'vehicle.fuel');
    });

    test('a value of the wrong shape in an app field is still scrubbed', () {
      final redactor = LogRedactor()..remember('WX12345', '[PLATE]');
      // Not a dotted identifier, so it does not count as ours.
      expect(
        redactor.scrubFields({'id': 'garage.card WX12345'})['id'],
        'garage.card [PLATE]',
      );
    });

    test('a long string is clipped', () {
      final redactor = LogRedactor(maxStringLength: 10);
      expect(redactor.scrubString('a' * 40), '${'a' * 10}…[clipped]');
    });
  });

  group('LogRedactor.scrubSample', () {
    final redactor = LogRedactor();

    test('keeps field names, numbers, booleans and dates', () {
      final sample = redactor.scrubSample({
        'id': 12,
        'date': '2026-08-06',
        'odometer': '148230',
        'cost': '54.90',
        'isFillToFull': 'True',
        'fuelType': 'Gasoline',
      }) as Map<String, Object?>;

      expect(sample, {
        'id': 12,
        'date': '2026-08-06',
        'odometer': '148230',
        'cost': '54.90',
        'isFillToFull': 'True',
        'fuelType': 'Gasoline',
      });
    });

    test('keeps a date the server formatted wrongly, which is the bug', () {
      final sample = redactor.scrubSample({'date': '01/15/2024 00:00:00'})
          as Map<String, Object?>;
      expect(sample['date'], '01/15/2024 00:00:00');
    });

    test('replaces what the user wrote with its length', () {
      final sample = redactor.scrubSample({
        'licensePlate': 'WX 1234A',
        'notes': 'Oil change before the trip to Anna',
        'make': 'Volkswagen',
      }) as Map<String, Object?>;

      expect(sample['licensePlate'], '<str:8>');
      expect(sample['notes'], '<str:34>');
      // A single word of letters passes as an enum-ish token; that is the
      // deliberate edge of the rule and it costs a make, not a sentence.
      expect(sample['make'], 'Volkswagen');
    });

    test('an empty string stays empty — that the field is set is a signal', () {
      final sample =
          redactor.scrubSample({'notes': ''}) as Map<String, Object?>;
      expect(sample['notes'], '');
    });

    test('user-invented extra fields are masked at depth', () {
      final sample = redactor.scrubSample({
        'extraFields': [
          {'name': 'Insurance policy', 'value': 'PL-88-2210-7781'},
        ],
      }) as Map<String, Object?>;

      final extra = (sample['extraFields'] as List).first as Map;
      expect(extra['name'], '<str:16>');
      expect(extra['value'], '<str:15>');
    });

    test('only the head of a nested list is kept', () {
      final sample = redactor.scrubSample({
        'files': [
          {'name': 'a', 'location': '1'},
          {'name': 'b', 'location': '2'},
          {'name': 'c', 'location': '3'},
          {'name': 'd', 'location': '4'},
        ],
      }) as Map<String, Object?>;
      expect((sample['files'] as List).length, 3);
    });

    test('a secret-named field is redacted, not measured', () {
      final sample = redactor.scrubSample({'apiKey': 'zzzzzzzzzzzz'})
          as Map<String, Object?>;
      expect(sample['apiKey'], '[REDACTED]');
    });
  });
}
