import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/units_settings.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';

/// Basic settings: display units (currency / distance / fuel economy) and the
/// server connection (with log out).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(unitsSettingsProvider);
    final unitsCtl = ref.read(unitsSettingsProvider.notifier);
    final serverSymbol =
        ref.watch(serverInfoProvider).valueOrNull?.currencySymbol ?? r'$';
    final profile = ref.watch(serverProfileProvider);
    final packageInfo = ref.watch(packageInfoProvider).valueOrNull;

    return DashBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: dashAppBar(context, title: l10n.settingsTitle),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Section(
              title: l10n.settingsUnits,
              footnote: l10n.settingsUnitsMetricNote,
              children: [
                _SettingRow(
                  label: l10n.settingsStorageBase,
                  control: SegmentedButton<MeasurementSystem>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: MeasurementSystem.metric,
                        label: Text(l10n.baseMetric),
                      ),
                      ButtonSegment(
                        value: MeasurementSystem.imperial,
                        label: Text(l10n.baseImperial),
                      ),
                    ],
                    selected: {units.base},
                    onSelectionChanged: (s) => unitsCtl.setBase(s.first),
                  ),
                ),
                _divider(t),
                _SettingRow(
                  label: l10n.settingsCurrency,
                  control: _Dropdown<CurrencyOption>(
                    value: units.currency,
                    items: CurrencyOption.values,
                    labelOf: (c) => c.fixedSymbol == null
                        ? l10n.currencyAuto(serverSymbol)
                        : '${c.fixedSymbol} (${c.name.toUpperCase()})',
                    onChanged: unitsCtl.setCurrency,
                  ),
                ),
                _divider(t),
                _SettingRow(
                  label: l10n.settingsDistance,
                  control: SegmentedButton<DistanceUnit>(
                    showSelectedIcon: false,
                    segments: [
                      for (final u in DistanceUnit.values)
                        ButtonSegment(value: u, label: Text(u.label)),
                    ],
                    selected: {units.distance},
                    onSelectionChanged: (s) => unitsCtl.setDistance(s.first),
                  ),
                ),
                _divider(t),
                _SettingRow(
                  label: l10n.settingsFuelEconomy,
                  control: _Dropdown<FuelEconomyUnit>(
                    value: units.economy,
                    items: FuelEconomyUnit.values,
                    labelOf: (e) => e.label,
                    onChanged: unitsCtl.setEconomy,
                  ),
                ),
                _divider(t),
                _SettingRow(
                  label: l10n.settingsDateFormat,
                  control: _Dropdown<DateOrder>(
                    value: units.dateOrder,
                    items: DateOrder.values,
                    labelOf: (o) => o.labelWith(units.dateSeparator),
                    onChanged: unitsCtl.setDateOrder,
                  ),
                ),
                _divider(t),
                _SettingRow(
                  label: l10n.settingsDateSeparator,
                  control: _Dropdown<DateSeparator>(
                    value: units.dateSeparator,
                    items: DateSeparator.values,
                    labelOf: (s) => units.dateOrder.labelWith(s),
                    onChanged: unitsCtl.setDateSeparator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Section(
              title: l10n.settingsServer,
              children: [
                if (profile?.label != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      l10n.signedInAs(profile!.label!),
                      style: TextStyle(
                        fontFamily: DashTokens.fontUi,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                Text(
                  profile?.baseUrl ?? '',
                  style: TextStyle(
                    fontFamily: DashTokens.fontMono,
                    fontSize: 12,
                    color: t.textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.danger,
                    side: BorderSide(color: t.danger.withValues(alpha: 0.5)),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(l10n.logout),
                  onPressed: () =>
                      ref.read(serverProfileProvider.notifier).clear(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Section(
              title: l10n.settingsAbout,
              children: [
                Text(
                  packageInfo?.appName ?? l10n.appTitle,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                if (packageInfo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l10n.appVersion(
                          packageInfo.version, packageInfo.buildNumber),
                      style: TextStyle(
                        fontFamily: DashTokens.fontMono,
                        fontSize: 12,
                        color: t.textTertiary,
                      ),
                    ),
                  ),
                _divider(t),
                _LinkRow(
                  label: l10n.openSourceLicenses,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: packageInfo?.appName ?? l10n.appTitle,
                    applicationVersion: packageInfo?.version,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(DashTokens t) =>
      Divider(height: 20, thickness: 1, color: t.hairline);
}

/// A titled card grouping related settings, with an optional footnote caption.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    this.footnote,
    required this.children,
  });

  final String title;
  final List<Widget> children;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: t.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: DashTokens.fontUi,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: t.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
          if (footnote != null) ...[
            const SizedBox(height: 12),
            Text(
              footnote!,
              style: TextStyle(
                fontFamily: DashTokens.fontUi,
                fontSize: 11.5,
                color: t.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A tappable row that navigates elsewhere (e.g. the licenses page): label on
/// the left, chevron on the right.
class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: DashTokens.fontUi,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: t.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// A label on the left with its control right-aligned.
class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.control});

  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: DashTokens.fontUi,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        control,
      ],
    );
  }
}

/// Themed dropdown for an enum-backed setting.
class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        borderRadius: BorderRadius.circular(14),
        dropdownColor: t.overlaySurface,
        style: TextStyle(
          fontFamily: DashTokens.fontUi,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: t.textPrimary,
        ),
        icon: Icon(Icons.arrow_drop_down, color: t.textSecondary),
        items: [
          for (final item in items)
            DropdownMenuItem(value: item, child: Text(labelOf(item))),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
