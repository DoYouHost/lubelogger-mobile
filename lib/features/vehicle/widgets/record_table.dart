import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/state_views.dart';

/// One column of a [RecordTable]. [numeric] columns are right-aligned and set in
/// the monospace face (matching the design's JetBrains-Mono data cells); text
/// columns use the UI face and ellipsize.
class RecordColumn {
  const RecordColumn(this.label, {this.flex = 1, this.numeric = false});

  final String label;
  final int flex;
  final bool numeric;
}

/// Zebra-striped record table (design #4): sticky-style header row + hairline
/// dividers. Column widths are proportional ([RecordColumn.flex]); everything
/// fits the screen width — no horizontal scroll — so cells ellipsize when tight.
class RecordTable extends StatelessWidget {
  const RecordTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
  });

  final List<RecordColumn> columns;

  /// One inner list per row, with a cell string per column (same length/order).
  final List<List<String>> rows;

  /// Tap handler keyed by row index (into [rows]), for opening an edit form.
  /// Omit for tables that aren't editable yet.
  final void Function(int index)? onRowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecordRow(columns: columns, cells: [for (final c in columns) c.label],
            header: true),
        for (var i = 0; i < rows.length; i++)
          _RecordRow(
            columns: columns,
            cells: rows[i],
            zebra: i.isEven,
            onTap: onRowTap == null ? null : () => onRowTap!(i),
          ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.columns,
    required this.cells,
    this.header = false,
    this.zebra = false,
    this.onTap,
  });

  final List<RecordColumn> columns;
  final List<String> cells;
  final bool header;
  final bool zebra;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final headerStyle = TextStyle(
      fontFamily: DashTokens.fontUi,
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: t.textTertiary,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: !header && zebra ? t.subCard : null,
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < columns.length; i++)
                Expanded(
                  flex: columns[i].flex,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      cells[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: columns[i].numeric
                          ? TextAlign.right
                          : TextAlign.left,
                      style: header
                          ? headerStyle
                          : TextStyle(
                              fontFamily: columns[i].numeric
                                  ? DashTokens.fontMono
                                  : DashTokens.fontUi,
                              fontSize: columns[i].numeric ? 11 : 12.5,
                              fontWeight: FontWeight.w600,
                              color: t.textSecondary,
                            ),
                    ),
                  ),
                ),
            ],
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

/// A group of summary pills above a table (fuel tab). Uses [DashPill].
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
