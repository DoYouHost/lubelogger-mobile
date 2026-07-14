import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/state_views.dart';

/// One icon + value pair in a [RecordCard]'s meta row (design: odometer,
/// distance-since-last, economy, price/volume — JetBrains Mono, tertiary).
class RecordMetaItem {
  const RecordMetaItem(this.icon, this.value);

  final IconData icon;
  final String value;
}

/// One record entry, styled as a card (design handoff: subcard fill + hairline
/// border, 14px radius, 8px stacking gap). Top row is the date (left) and a
/// right-aligned headline value — the cost for money-bearing records, or the
/// primary reading when there's no cost (e.g. an odometer entry); an optional
/// description sits below it; an optional meta row of small icon+value stats
/// (JetBrains Mono, tertiary) sits at the bottom.
class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.date,
    required this.headline,
    this.headlineColor,
    this.description,
    this.meta = const [],
    this.onTap,
  });

  final String date;
  final String headline;
  final Color? headlineColor;
  final String? description;
  final List<RecordMetaItem> meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final radius = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.subCard,
          borderRadius: radius,
          border: Border.all(color: t.subCardBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: DashTokens.fontUi,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      headline,
                      style: TextStyle(
                        fontFamily: DashTokens.fontMono,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: headlineColor ?? t.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: t.textSecondary,
                    ),
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      for (final m in meta)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(m.icon, size: 14, color: t.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              m.value,
                              style: TextStyle(
                                fontFamily: DashTokens.fontMono,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: t.textTertiary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared record-tab body: pull-to-refresh + loading / error / empty / content
/// switching over an [AsyncValue] list. [onRefresh] both invalidates and awaits
/// the provider so the spinner reflects the real reload.
class RecordsTabBody<T> extends StatelessWidget {
  const RecordsTabBody({
    super.key,
    required this.async,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.builder,
  });

  final AsyncValue<List<T>> async;
  final Future<void> Function() onRefresh;
  final IconData emptyIcon;
  final String emptyLabel;
  final Widget Function(List<T> records) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AsyncErrorView(
          message: l10n.dashLoadError,
          onRetry: onRefresh,
          retryLabel: l10n.retry,
        ),
        data: (records) => records.isEmpty
            ? EmptyStateView(message: emptyLabel, icon: emptyIcon)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [builder(records)],
              ),
      ),
    );
  }
}

/// A group of summary pills above a record list (fuel tab). Uses [DashPill].
class SummaryPillRow extends StatelessWidget {
  const SummaryPillRow({super.key, required this.pills});

  final List<Widget> pills;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(spacing: 6, runSpacing: 6, children: pills),
    );
  }
}
