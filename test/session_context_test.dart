import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/diagnostics/diagnostic_recorder.dart';
import 'package:lubelogger_mobile/core/diagnostics/log_event.dart';
import 'package:lubelogger_mobile/core/diagnostics/session_facts.dart';
import 'package:lubelogger_mobile/core/models/vehicle_tab.dart';
import 'package:lubelogger_mobile/core/settings/settings_repository.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What a report can answer about the session without asking the person who
/// filed it: which phone, which time zone, and how the app was set up to display
/// the numbers in the records below.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsRepository settings;
  late DiagnosticRecorder recorder;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsRepository(await SharedPreferences.getInstance());
    recorder = DiagnosticRecorder(
      settings: settings,
      loadFacts: () async => SessionFacts(
        app: '0.2.7+207',
        environment: const {'tz': '+02:00', 'device': 'Xiaomi 2201123G'},
        settings: settings.diagnosticsSnapshot(),
      ),
      resolveDirectory: () async => null,
    );
  });

  tearDown(() async {
    if (DiagnosticRecorder.isRecording) await recorder.stop();
  });

  Future<List<Map<String, Object?>>> stopAndRead() async {
    final jsonl = await recorder.stop();
    return [
      for (final line in const LineSplitter().convert(jsonl))
        jsonDecode(line) as Map<String, Object?>,
    ];
  }

  group('session header', () {
    test('the device facts sit beside the app version', () async {
      await recorder.start();
      final header = (await stopAndRead()).first;
      expect(header['app'], '0.2.7+207');
      expect(header['tz'], '+02:00');
      expect(header['device'], 'Xiaomi 2201123G');
    });

    test('a fact survives the round trip the worker puts it through', () {
      // The background isolate does not build a header — it reads the UI's off
      // disk and writes it back tagged as its own stream. A fact this class does
      // not know by name would be dropped there, and only in the file that the
      // report is actually assembled from.
      final original = LogHeader(
        ts: DateTime.utc(2026, 8, 7),
        session: 'abc',
        app: '0.2.7+207',
        extra: const {'tz': '+02:00', 'sdk': 34},
      );

      final reread = LogHeader.tryParse(
        original.toJsonLine(),
        session: 'abc',
      )!.copyWith(stream: LogStream.worker);

      expect(reread.extra['tz'], '+02:00');
      expect(reread.extra['sdk'], 34);
      expect(reread.toJson()['stream'], 'worker');
    });

    test('an unknown fact cannot overwrite a field the header owns', () {
      final header = LogHeader(
        ts: DateTime.utc(2026, 8, 7),
        session: 'abc',
        app: '0.2.7+207',
        extra: const {'session': 'forged', 'tz': '+02:00'},
      );
      expect(header.toJson()['session'], 'abc');
      expect(header.toJson()['tz'], '+02:00');
    });
  });

  group('settings snapshot', () {
    test('the units a report has to be read in are on the second line',
        () async {
      await settings.saveUnits(
        const UnitsSettings(
          base: MeasurementSystem.imperial,
          currency: CurrencyOption.pln,
          distance: DistanceUnit.mi,
          dateOrder: DateOrder.mdy,
          dateSeparator: DateSeparator.dash,
        ),
      );

      await recorder.start();
      final record = (await stopAndRead()).firstWhere(
        (r) => r['evt'] == 'settings',
      );
      final units = record['units']! as Map<String, Object?>;

      expect(units['base'], 'imperial');
      expect(units['currency'], 'pln');
      expect(units['distance'], 'mi');
      // The pattern the app prints dates with, next to whatever the server sent.
      expect(units['date_fmt'], 'MM-dd-yyyy');
    });

    test('an untouched setup says so by staying quiet', () async {
      await recorder.start();
      final record = (await stopAndRead()).firstWhere(
        (r) => r['evt'] == 'settings',
      );
      // Nothing hidden and nothing reordered is the default, and printing twelve
      // tab names to say so would push the session out of view.
      expect(record.containsKey('tabs_hidden'), isFalse);
      expect(record.containsKey('tab_order'), isFalse);
      expect(record['reminders'], false);
    });

    test('a hidden tab is named, and the visible ones are not', () async {
      await settings.saveVisibleTabs(
        VehicleTab.values.toSet()..remove(VehicleTab.fuel),
      );

      await recorder.start();
      final record = (await stopAndRead()).firstWhere(
        (r) => r['evt'] == 'settings',
      );
      expect(record['tabs_hidden'], ['fuel']);
    });
  });

  group('settings changed mid-session', () {
    test('a preference change is recorded where it is persisted', () async {
      await recorder.start();
      await settings.saveRemindersEnabled(true);
      await settings.saveUnits(
        const UnitsSettings(distance: DistanceUnit.mi),
      );

      final changes = [
        for (final r in await stopAndRead())
          if (r['evt'] == 'setting') r,
      ];

      expect(changes.map((r) => r['name']), ['reminders', 'units']);
      expect(changes.first['value'], true);
      expect(
        (changes.last['value']! as Map<String, Object?>)['distance'],
        'mi',
      );
    });

    test('changing server says that it changed, not what to', () async {
      await recorder.start();
      await settings.clearProfile();

      final record = (await stopAndRead()).firstWhere(
        (r) => r['evt'] == 'setting',
      );
      expect(record['name'], 'profile');
      expect(record['value'], 'cleared');
    });
  });
}
