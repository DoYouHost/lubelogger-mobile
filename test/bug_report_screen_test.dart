import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lubelogger_mobile/core/diagnostics/diagnostic_recorder.dart';
import 'package:lubelogger_mobile/core/diagnostics/log_event.dart';
import 'package:lubelogger_mobile/core/diagnostics/session_facts.dart';
import 'package:lubelogger_mobile/features/bug_report/bug_report_controller.dart';
import 'package:lubelogger_mobile/features/bug_report/bug_report_screen.dart';
import 'package:lubelogger_mobile/features/bug_report/log_export.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppLocalizations l10n;
  late List<({String fileName, String log})> saved;
  late LogSaveResult saveResult;

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // In-memory recording: no package info, no support directory, no files.
        diagnosticRecorderProvider.overrideWith(
          (ref) => DiagnosticRecorder(
            settings: ref.watch(settingsRepositoryProvider),
            loadFacts: () async => const SessionFacts(app: '0.2.7+207'),
            resolveDirectory: () async => null,
          ),
        ),
        logFileSaverProvider.overrideWithValue(
          ({required String fileName, required String log, String? dialogTitle}) async {
            saved.add((fileName: fileName, log: log));
            return saveResult;
          },
        ),
      ],
    );
    addTearDown(container.dispose);

    // A router of its own rather than the app's: finishing a report navigates
    // away, and the screen reaches for `GoRouter.of(context)` to do it.
    final router = GoRouter(
      initialLocation: '/settings/bug-report',
      routes: [
        GoRoute(
          path: '/setup',
          builder: (_, _) => const Scaffold(body: Text('setup')),
        ),
        GoRoute(
          path: '/settings/bug-report',
          builder: (_, _) => const BugReportScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    saved = [];
    saveResult = LogSaveResult.saved;
  });

  testWidgets('opens on the explanation, with recording not yet running',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text(l10n.bugReportIntroHeader), findsOneWidget);
    expect(find.text(l10n.bugReportPrivacyHeader), findsOneWidget);
    expect(find.text(l10n.bugReportStart), findsOneWidget);
    expect(DiagnosticRecorder.isRecording, isFalse);
  });

  testWidgets('a finished recording is reviewed before anything leaves',
      (tester) async {
    final container = await pumpScreen(tester);
    final controller = container.read(bugReportProvider.notifier);

    await controller.start();
    DiagnosticRecorder.active!.add(
      LogSource.ui,
      'tap',
      fields: {'id': 'garage.card'},
    );
    await controller.stop();
    await tester.pumpAndSettle();

    // The review lists what was recorded, and the file is the default
    // destination — publishing is never the choice made for the user.
    expect(find.text(l10n.bugReportReviewHeader), findsOneWidget);
    expect(find.textContaining('garage.card'), findsOneWidget);
    expect(find.text(l10n.bugReportSaveShort), findsOneWidget);
    expect(find.text(l10n.bugReportDestinationFileBody), findsOneWidget);
    expect(find.text(l10n.bugReportDescriptionLabel), findsNothing);
  });

  testWidgets('choosing the public issue asks for a description and warns',
      (tester) async {
    final container = await pumpScreen(tester);
    final controller = container.read(bugReportProvider.notifier);
    await controller.start();
    await controller.stop();
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.bugReportDestinationIssue));
    await tester.pumpAndSettle();

    expect(find.text(l10n.bugReportDestinationIssueBody), findsOneWidget);
    expect(find.text(l10n.bugReportDescriptionLabel), findsOneWidget);
    expect(find.text(l10n.bugReportSend), findsOneWidget);
  });

  testWidgets('reporting without a description is refused', (tester) async {
    final container = await pumpScreen(tester);
    final controller = container.read(bugReportProvider.notifier);
    await controller.start();
    await controller.stop();
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.bugReportDestinationIssue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.bugReportSend));
    await tester.pumpAndSettle();

    expect(find.text(l10n.bugReportDescriptionRequired), findsOneWidget);
  });

  testWidgets('saving hands the whole session to the picker', (tester) async {
    final container = await pumpScreen(tester);
    final controller = container.read(bugReportProvider.notifier);
    await controller.start();
    DiagnosticRecorder.active!.add(LogSource.ui, 'tap', fields: {'id': 'a.b'});
    await controller.stop();
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.bugReportSaveShort));
    await tester.pumpAndSettle();

    expect(saved.single.fileName, endsWith('.txt'));
    expect(saved.single.log, contains('"evt":"tap"'));
  });

  testWidgets('discarding asks first', (tester) async {
    final container = await pumpScreen(tester);
    final controller = container.read(bugReportProvider.notifier);
    await controller.start();
    await controller.stop();
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.bugReportDiscard).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.bugReportDiscardQuestion), findsOneWidget);

    await tester.tap(find.text(l10n.actionCancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.bugReportReviewHeader), findsOneWidget);

    await tester.tap(find.text(l10n.bugReportDiscard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.bugReportDiscard).last);
    await tester.pumpAndSettle();

    // Back to the start: nothing left to review, nothing left on the phone.
    expect(find.text(l10n.bugReportStart), findsOneWidget);
  });
}
