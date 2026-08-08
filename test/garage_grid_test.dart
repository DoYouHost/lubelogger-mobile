import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/app.dart';
import 'package:lubelogger_mobile/core/models/vehicle_info.dart';
import 'package:lubelogger_mobile/features/garage/widgets/vehicle_card.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The garage builds its cards lazily, one grid row at a time. What that must
/// not cost is the layout itself: every vehicle on screen, and the add tile
/// still riding along at the end.
void main() {
  VehicleInfo vehicle(int id) => VehicleInfo.fromJson({
    'vehicleData': {
      'id': id,
      'year': 2020,
      'make': 'Make',
      'model': 'Model $id',
      'licensePlate': 'PLATE$id',
      'imageLocation': '',
    },
    'lastReportedOdometer': 1000 * id,
    'serviceRecordCost': 10,
    'repairRecordCost': 20,
    'upgradeRecordCost': 30,
    'taxRecordCost': 40,
    'gasRecordCost': 50,
    'veryUrgentReminderCount': 0,
    'urgentReminderCount': 0,
    'notUrgentReminderCount': 0,
    'pastDueReminderCount': 0,
  });

  testWidgets('every vehicle gets a card, with the add tile last', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'server_profile': jsonEncode({'baseUrl': 'https://lube.invalid'}),
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          garageProvider.overrideWith(
            (ref) async => [vehicle(1), vehicle(2), vehicle(3)],
          ),
        ],
        child: const LubeLoggerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Make Model 1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(AddVehicleTile),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(AddVehicleTile), findsOneWidget);
  });
}
