import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/auth/credentials_store.dart';
import 'package:lubelogger_mobile/core/cache/http_cache.dart';
import 'package:lubelogger_mobile/core/settings/server_profile.dart';
import 'package:lubelogger_mobile/core/settings/settings_repository.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class _MemoryCredentials implements CredentialsStore {
  String? key = 'secret';

  @override
  Future<String?> readApiKey() async => key;

  @override
  Future<void> writeApiKey(String key) async => this.key = key;

  @override
  Future<void> clearAll() async => key = null;
}

class _FakeWorkmanager extends WorkmanagerPlatform {
  final cancelled = <String>[];

  @override
  Future<void> cancelByUniqueName(String uniqueName) async =>
      cancelled.add(uniqueName);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const profile = ServerProfile(baseUrl: 'https://one.example');

  late Directory support;
  late _MemoryCredentials credentials;
  late _FakeWorkmanager workmanager;
  late List<String> quickActionCalls;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('lubelogger_logout_test');
    credentials = _MemoryCredentials();
    workmanager = _FakeWorkmanager();
    WorkmanagerPlatform.instance = workmanager;
    quickActionCalls = [];

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => support.path,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/quick_actions'),
      (call) async => quickActionCalls.add(call.method),
    );
    addTearDown(() async {
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/quick_actions'),
        null,
      );
      if (support.existsSync()) await support.delete(recursive: true);
    });
  });

  Future<ProviderContainer> signedIn() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SettingsRepository(prefs).saveProfile(profile);
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        credentialsStoreProvider.overrideWithValue(credentials),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('logout signs out and wipes the session', () async {
    final c = await signedIn();
    // The client is alive, as it is on any screen that offers logout.
    c.read(apiClientProvider);
    final cacheDir = await serverCacheDirectory(
      profile.baseUrl,
      () async => support,
    );
    await cacheDir.create(recursive: true);

    await c.read(serverProfileProvider.notifier).clear();

    expect(c.read(serverProfileProvider), isNull);
    expect(c.read(settingsRepositoryProvider).loadProfile(), isNull);
    expect(credentials.key, isNull);
    expect(cacheDir.existsSync(), isFalse);
    expect(workmanager.cancelled, isNotEmpty);
    expect(quickActionCalls, contains('clearShortcutItems'));
  });
}
