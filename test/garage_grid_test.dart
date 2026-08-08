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
/// not cost is the layout itself: every vehicle on screen, the add tile still
/// riding along at the end, and the swipe action still opening.
void main() {
  Future<void> pumpGarage(WidgetTester tester, List<VehicleInfo> vehicles) async {
    SharedPreferences.setMockInitialValues({
      'server_profile': jsonEncode({'baseUrl': 'https://lube.invalid'}),
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          garageProvider.overrideWith((ref) async => vehicles),
        ],
        child: const LubeLoggerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

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
    await pumpGarage(tester, [vehicle(1), vehicle(2), vehicle(3)]);

    expect(find.text('Make Model 1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(AddVehicleTile),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(AddVehicleTile), findsOneWidget);
  });

  // The Edit action used to be wrapped in its log tag, which put a widget
  // between the pane's Row and the Expanded that CustomSlidableAction builds:
  // the first swipe threw and left the pane unlaid-out.
  testWidgets('swiping a card open reveals the Edit action', (tester) async {
    await pumpGarage(tester, [vehicle(1)]);

    await tester.drag(find.byType(VehicleCard).first, const Offset(-150, 0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
  });
}
