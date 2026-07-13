import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../common/state_views.dart';
import 'widgets/vehicle_card.dart';

/// The garage: the household's vehicles as photo cards, with an add-vehicle tile
/// at the end (design screen #2).
class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final garage = ref.watch(garageProvider);
    final baseUrl = ref.watch(serverProfileProvider)?.baseUrl ?? '';
    final apiKey = ref.watch(apiKeyProvider).valueOrNull;
    final currency = ref.watch(currencySymbolProvider);
    final units = ref.watch(unitsSettingsProvider);

    Future<void> refresh() async {
      ref.invalidate(garageProvider);
      ref.invalidate(serverInfoProvider);
      await ref.read(garageProvider.future);
    }

    return DashBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: dashAppBar(
          context,
          titleWidget: const LubeLoggerWordmark(),
          actions: [
            IconButton(
              tooltip: l10n.settingsTitle,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: refresh,
          child: garage.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => AsyncErrorView(
              message: l10n.garageLoadError,
              onRetry: refresh,
              retryLabel: l10n.retry,
            ),
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return _EmptyGarage(l10n: l10n, onAdd: () => _comingSoon(context, l10n));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: vehicles.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (context, i) {
                  if (i == vehicles.length) {
                    return AddVehicleTile(onTap: () => _comingSoon(context, l10n));
                  }
                  return VehicleCard(
                    info: vehicles[i],
                    baseUrl: baseUrl,
                    apiKey: apiKey,
                    currencySymbol: currency,
                    measurementBase: units.base,
                    distanceUnit: units.distance,
                    onTap: () => context.push('/vehicle/${vehicles[i].vehicle.id}'),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }
}

/// Empty state that still offers the add-vehicle tile.
class _EmptyGarage extends StatelessWidget {
  const _EmptyGarage({required this.l10n, required this.onAdd});

  final AppLocalizations l10n;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      children: [
        Icon(Icons.garage_outlined, size: 56, color: t.textTertiary),
        const SizedBox(height: 12),
        Text(
          l10n.garageEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: DashTokens.fontUi,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: t.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        AddVehicleTile(onTap: onAdd),
      ],
    );
  }
}
