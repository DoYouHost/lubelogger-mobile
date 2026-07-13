import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_client.dart';
import 'core/api/endpoints.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/credentials_store.dart';
import 'core/format/gas_stats.dart';
import 'core/format/monthly_breakdown.dart';
import 'core/models/dated_cost.dart';
import 'core/models/gas_record.dart';
import 'core/models/odometer_record.dart';
import 'core/models/server_info.dart';
import 'core/models/vehicle_info.dart';
import 'core/models/vehicle_record.dart';
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

  Future<void> setDateOrder(DateOrder dateOrder) =>
      _save(state.copyWith(dateOrder: dateOrder));

  Future<void> setDateSeparator(DateSeparator dateSeparator) =>
      _save(state.copyWith(dateSeparator: dateSeparator));
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

/// App name/version/build number, for the Settings "About" section.
final packageInfoProvider =
    FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

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

/// Aggregated info for one vehicle (odometer, costs, reminders) — powers the
/// dashboard header, stat block, and both expense/reminder charts.
final vehicleInfoProvider = FutureProvider.family<VehicleInfo, int>(
  (ref, vehicleId) => ref.watch(vehiclesRepositoryProvider).info(vehicleId),
);

/// Locally-computed fuel statistics for one vehicle (lifetime average, distance
/// span, per-month economy). Kept in raw stored units; unit conversion happens
/// at display time, so this doesn't depend on the units settings.
final gasStatsProvider = FutureProvider.family<GasStats, int>(
  (ref, vehicleId) async {
    final records =
        await ref.watch(vehiclesRepositoryProvider).gasRecords(vehicleId);
    return GasStats.from(records);
  },
);

/// Raw refuel log for one vehicle, powering the Fuel tab's per-record table
/// (economy is computed by [fuelRows]). Distinct from [gasStatsProvider], which
/// aggregates the same records into lifetime/monthly stats.
final gasRecordsProvider = FutureProvider.family<List<GasRecord>, int>(
  (ref, vehicleId) =>
      ref.watch(vehiclesRepositoryProvider).gasRecords(vehicleId),
);

/// Odometer readings for one vehicle, powering the Odometer tab's table.
final odometerRecordsProvider =
    FutureProvider.family<List<OdometerRecord>, int>(
  (ref, vehicleId) =>
      ref.watch(vehiclesRepositoryProvider).odometerRecords(vehicleId),
);

/// Full records for one vehicle's generic (date + cost) record tab, keyed by
/// vehicle + [RecordKind] (service / repair / upgrade / tax).
final vehicleRecordsProvider = FutureProvider.family<List<VehicleRecord>,
    ({int vehicleId, RecordKind kind})>(
  (ref, key) => ref
      .watch(vehiclesRepositoryProvider)
      .records(key.kind, key.vehicleId),
);

/// Monthly expense (by category) + distance breakdown for one vehicle. Fetches
/// every cost-bearing record type plus odometer readings in parallel, then
/// aggregates them per calendar month for the combo chart.
final monthlyBreakdownProvider = FutureProvider.family<MonthlyBreakdown, int>(
  (ref, vehicleId) async {
    final repo = ref.watch(vehiclesRepositoryProvider);
    final (service, repair, upgrade, tax, gas, odometers) = await (
      repo.datedCosts(Endpoints.serviceRecords, vehicleId),
      repo.datedCosts(Endpoints.repairRecords, vehicleId),
      repo.datedCosts(Endpoints.upgradeRecords, vehicleId),
      repo.datedCosts(Endpoints.taxRecords, vehicleId),
      repo.gasRecords(vehicleId),
      repo.odometerRecords(vehicleId),
    ).wait;

    // Distance timeline: every odometer reading from fuel-ups and dedicated
    // odometer records, so a fuel-only vehicle still charts distance.
    final readings = <OdometerReading>[
      for (final g in gas) (date: g.date, odometer: g.odometer),
      for (final o in odometers) (date: o.date, odometer: o.odometer),
    ];

    return MonthlyBreakdown.from(
      costsByCategory: {
        ExpenseCategory.service: service,
        ExpenseCategory.repair: repair,
        ExpenseCategory.upgrade: upgrade,
        ExpenseCategory.tax: tax,
        ExpenseCategory.fuel: [
          for (final r in gas) DatedCost(date: r.date, cost: r.cost),
        ],
      },
      odometerReadings: readings,
    );
  },
);
