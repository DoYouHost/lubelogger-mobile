import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_client.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/credentials_store.dart';
import 'core/models/server_info.dart';
import 'core/models/vehicle_info.dart';
import 'core/settings/server_profile.dart';
import 'core/settings/settings_repository.dart';
import 'core/settings/units_settings.dart';
import 'data/vehicles_repository.dart';

/// Overridden in main() after `SharedPreferences.getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in ProviderScope'),
);

final credentialsStoreProvider =
    Provider<CredentialsStore>((ref) => SecureCredentialsStore());

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

/// Display-unit preferences (currency symbol, distance, fuel economy). Persisted
/// locally; independent of the server's own locale.
final unitsSettingsProvider =
    NotifierProvider<UnitsSettingsNotifier, UnitsSettings>(
  UnitsSettingsNotifier.new,
);

class UnitsSettingsNotifier extends Notifier<UnitsSettings> {
  @override
  UnitsSettings build() => ref.watch(settingsRepositoryProvider).loadUnits();

  Future<void> _save(UnitsSettings units) async {
    await ref.read(settingsRepositoryProvider).saveUnits(units);
    state = units;
  }

  Future<void> setBase(MeasurementSystem base) =>
      _save(state.copyWith(base: base));

  Future<void> setCurrency(CurrencyOption currency) =>
      _save(state.copyWith(currency: currency));

  Future<void> setDistance(DistanceUnit distance) =>
      _save(state.copyWith(distance: distance));

  Future<void> setEconomy(FuelEconomyUnit economy) =>
      _save(state.copyWith(economy: economy));
}

/// The currency symbol to display: the user's forced choice, or the server's
/// symbol when set to [CurrencyOption.auto].
final currencySymbolProvider = Provider<String>((ref) {
  final forced = ref.watch(unitsSettingsProvider).currency.fixedSymbol;
  if (forced != null) return forced;
  return ref.watch(serverInfoProvider).valueOrNull?.currencySymbol ?? r'$';
});

/// Bare Dio (no auth) used for the login probe.
final bareDioProvider = Provider<Dio>((ref) => createBareDio());

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    bareDio: ref.watch(bareDioProvider),
    credentials: ref.watch(credentialsStoreProvider),
  ),
);

/// Active server profile; `null` = unconfigured (router → /setup).
final serverProfileProvider =
    NotifierProvider<ServerProfileNotifier, ServerProfile?>(
  ServerProfileNotifier.new,
);

class ServerProfileNotifier extends Notifier<ServerProfile?> {
  @override
  ServerProfile? build() =>
      ref.watch(settingsRepositoryProvider).loadProfile();

  Future<void> save(ServerProfile profile) async {
    await ref.read(settingsRepositoryProvider).saveProfile(profile);
    state = profile;
  }

  /// "Log out / change server": clear the profile and every stored secret.
  Future<void> clear() async {
    await ref.read(settingsRepositoryProvider).clearProfile();
    await ref.read(credentialsStoreProvider).clearAll();
    state = null;
  }
}

/// Most recently built client. Survives the transient frame between "change
/// server" clearing the profile and the router redirecting to /setup, when
/// repository providers that `watch` this may momentarily rebuild with a null
/// profile. Never used for a real request in that window — its consumers are
/// about to unmount. Safe to cache: [ApiClient] holds no disposable resources.
ApiClient? _lastApiClient;

/// API client for the active profile. Routes without a profile redirect to
/// /setup, so the UI should never read this while the profile is null.
final apiClientProvider = Provider<ApiClient>((ref) {
  final profile = ref.watch(serverProfileProvider);
  if (profile == null) {
    final cached = _lastApiClient;
    if (cached != null) {
      assert(() {
        debugPrint('apiClientProvider: reusing last client (profile is null)');
        return true;
      }());
      return cached;
    }
    throw StateError('apiClientProvider used without a server profile');
  }
  return _lastApiClient = ApiClient(
    profile: profile,
    credentials: ref.watch(credentialsStoreProvider),
  );
});

/// The active API key, for authenticating image requests (`Image.network`
/// headers). Read once per profile.
final apiKeyProvider = FutureProvider<String?>(
  (ref) => ref.watch(credentialsStoreProvider).readApiKey(),
);

final vehiclesRepositoryProvider = Provider<VehiclesRepository>(
  (ref) => VehiclesRepository(ref.watch(apiClientProvider).dio),
);

/// Server metadata (currency, locale, date format). Cached per session; drives
/// number/date formatting across the app.
final serverInfoProvider = FutureProvider<ServerInfo>(
  (ref) => ref.watch(vehiclesRepositoryProvider).serverInfo(),
);

/// Garage contents: every vehicle with its aggregated info. Fetches the vehicle
/// list, then each vehicle's info in parallel (household lists are small, so the
/// N+1 is cheap and keeps the cards fully populated).
final garageProvider = FutureProvider<List<VehicleInfo>>((ref) async {
  final repo = ref.watch(vehiclesRepositoryProvider);
  final vehicles = await repo.list();
  final infos = await Future.wait(vehicles.map((v) => repo.info(v.id)));
  return infos;
});
