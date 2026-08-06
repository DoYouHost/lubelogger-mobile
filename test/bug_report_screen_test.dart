import 'dart:typed_data';

import 'package:dio/dio.dart';
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

/// Answers the relay's challenge without a socket. Choosing a request kind
/// fetches a ticket straight away, and a test must not depend on DNS for that.
class _OfflineRelay implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final now = DateTime.now();
    return ResponseBody.fromString(
      '{"ticket":"signed","nbf":${now.millisecondsSinceEpoch},'
      '"exp":${now.add(const Duration(minutes: 10)).millisecondsSinceEpoch},'
      '"seed":"seed","bits":0}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

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
        bareDioProvider.overrideWithValue(
          Dio()..httpClientAdapter = _OfflineRelay(),
        ),
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

  testWidgets('a feature request skips recording entirely', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.bugReportKindFeature));
    await tester.pumpAndSettle();

    // Nothing to reproduce, so nothing to record: the whole recording step is
    // gone and the form is the report.
    expect(find.text(l10n.bugReportStart), findsNothing);
    expect(find.text(l10n.bugReportFeatureHeader), findsOneWidget);
    expect(find.text(l10n.bugReportFeatureLabel), findsOneWidget);
    expect(find.text(l10n.bugReportSend), findsOneWidget);
    // And the promise made is the one a request can keep.
    expect(find.text(l10n.bugReportRequestPrivacyHeader), findsOneWidget);
    expect(DiagnosticRecorder.isRecording, isFalse);
  });

  testWidgets('a change request asks its own question', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.bugReportKindChange));
    await tester.pumpAndSettle();

    expect(find.text(l10n.bugReportChangeLabel), findsOneWidget);
    // "What went wrong" is the wrong question for something that works.
    expect(find.text(l10n.bugReportDescriptionLabel), findsNothing);
  });

  testWidgets('an empty request is refused', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.bugReportKindFeature));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.bugReportSend));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.bugReportSend));
    await tester.pumpAndSettle();

    expect(find.text(l10n.bugReportRequestRequired), findsOneWidget);
  });

  testWidgets('going back to a bug brings the recording step back',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.bugReportKindFeature));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.bugReportKindBug));
    await tester.pumpAndSettle();

    expect(find.text(l10n.bugReportStart), findsOneWidget);
    expect(find.text(l10n.bugReportFeatureLabel), findsNothing);
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
    expect(find.text(l10n.bugReportSaveShort), findsOneWidget);
    expect(find.text(l10n.bugReportDestinationFileBody), findsOneWidget);
    expect(find.text(l10n.bugReportDescriptionLabel), findsNothing);
    // What describes the whole session is shown above the records, so the phone
    // and the time zone the header carries are reviewed like everything else.
    expect(find.textContaining('app 0.2.7+207'), findsOneWidget);

    // The records themselves are below the fold on a small screen.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.textContaining('garage.card'), findsOneWidget);
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
