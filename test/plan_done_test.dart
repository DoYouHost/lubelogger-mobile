import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/api/api_exceptions.dart';
import 'package:lubelogger_mobile/core/demo/demo_http_adapter.dart';
import 'package:lubelogger_mobile/core/models/plan_record.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';
import 'package:lubelogger_mobile/features/vehicle/forms/add_plan_form.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/providers.dart';

/// A finished plan is the one record the API will not take back: it answers 400
/// to `Progress: Done`, and every value it does accept moves the plan backwards.
void main() {
  VehiclesRepository repo() {
    final dio = Dio(BaseOptions(baseUrl: 'http://demo'))
      ..httpClientAdapter = DemoHttpClientAdapter(latency: Duration.zero);
    return VehiclesRepository(dio);
  }

  PlanRecord plan(PlanProgress progress) => PlanRecord(
        id: 5,
        dateCreated: DateTime(2026, 1, 2),
        description: 'Fit winter tyres',
        cost: 480,
        type: PlanType.upgrade,
        priority: PlanPriority.normal,
        progress: progress,
        notes: '',
      );

  Future<void> openForm(WidgetTester tester, PlanRecord existing) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehiclesRepositoryProvider.overrideWithValue(repo()),
          extraFieldTemplatesProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showAddPlanForm(context, 2, existing: existing),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  test('Done no longer disguises itself as Testing on the wire', () {
    // The old mapping made a save look successful while demoting the plan.
    expect(PlanProgress.done.wireName, 'Done');
    expect(PlanProgress.done.isWritable, isFalse);
    for (final p in [
      PlanProgress.backlog,
      PlanProgress.inProgress,
      PlanProgress.testing,
    ]) {
      expect(p.isWritable, isTrue);
    }
  });

  // One test, because the demo backend is a per-process singleton and the
  // delete below is what makes the seeded plan disappear.
  test('a finished plan is refused on update but can still be deleted',
      () async {
    final r = repo();
    final done = (await r.planRecords(2)).firstWhere(
      (p) => p.progress == PlanProgress.done,
    );

    await expectLater(
      r.updatePlanRecord(
        id: done.id,
        description: done.description,
        cost: done.cost,
        type: done.type,
        priority: done.priority,
        progress: PlanProgress.done,
        notes: done.notes,
      ),
      throwsA(isA<AppApiException>()),
    );

    await r.deletePlanRecord(done.id);
    expect((await r.planRecords(2)).any((p) => p.id == done.id), isFalse);
  });

  testWidgets('editing a finished plan is blocked, with the reason shown', (
    tester,
  ) async {
    await openForm(tester, plan(PlanProgress.done));

    expect(
      find.textContaining('refuses to store a finished plan'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );
    // Read-only means read-only: not just the progress field.
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .enabled,
      isFalse,
    );
  });

  testWidgets('an unfinished plan is untouched by any of it', (tester) async {
    await openForm(tester, plan(PlanProgress.inProgress));

    expect(
      find.textContaining('refuses to store a finished plan'),
      findsNothing,
    );
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .enabled,
      isTrue,
    );
  });
}
