import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/diagnostics/log_tag.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/state_views.dart';

/// One icon + value pair in a [RecordCard]'s meta row (design: odometer,
/// distance-since-last, economy, price/volume — JetBrains Mono, tertiary).
class RecordMetaItem {
  const RecordMetaItem(this.icon, this.value, {this.tooltip});

  /// An item that is only its icon — a flag ("this record has a note"), where
  /// the icon is the whole message and a value beside it would just repeat it.
  /// [tooltip] is what says so out loud, for a long press and for a screen
  /// reader.
  const RecordMetaItem.flag(this.icon, {required String this.tooltip})
      : value = '';

  final IconData icon;
  final String value;

  /// Long-press text, and the item's semantics label.
  final String? tooltip;
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
        // Named here rather than by each tab: a row is a row in every tab, and
        // the enclosing tab surface already says which list it belongs to.
        child: logTag(
          'record.card',
          InkWell(
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
                      children: [for (final m in meta) _MetaItem(item: m)],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One entry of a card's meta row. A [RecordMetaItem.flag] renders as the bare
/// icon; anything else keeps its mono value beside it.
class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.item});

  final RecordMetaItem item;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 14, color: t.textTertiary),
        if (item.value.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            item.value,
            style: TextStyle(
              fontFamily: DashTokens.fontMono,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: t.textTertiary,
            ),
          ),
        ],
      ],
    );
    final tooltip = item.tooltip;
    return tooltip == null ? row : Tooltip(message: tooltip, child: row);
  }
}

/// What a record tab shows once its records have loaded: the cards, built one at
/// a time by index, plus an optional header above them (the fuel tab's summary
/// pills).
///
/// Cards are handed over as a builder rather than a list so the tab body can
/// keep them lazy — see [SliverResponsiveCards].
class RecordsContent {
  const RecordsContent({
    required this.count,
    required this.card,
    this.header,
  });

  final int count;
  final IndexedWidgetBuilder card;
  final Widget? header;
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
  final RecordsContent Function(List<T> records) builder;

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
            : _content(builder(records)),
      ),
    );
  }

  Widget _content(RecordsContent content) {
    final header = content.header;
    return CustomScrollView(
      slivers: [
        if (header != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(child: header),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, header == null ? 8 : 0, 16, 32),
          sliver: SliverResponsiveCards(
            itemCount: content.count,
            itemBuilder: content.card,
          ),
        ),
      ],
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
