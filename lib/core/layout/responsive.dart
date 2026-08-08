import 'package:flutter/widgets.dart';

/// Layout helpers for adapting the (single-column, portrait-first) design to
/// wider viewports — phone landscape and tablets — so horizontal space is used
/// instead of stretching one column edge-to-edge.

/// Max width for modal bottom sheets. When the screen is wider the sheet is
/// centered at this width rather than spanning the full landscape width, which
/// would leave forms with uncomfortably long fields.
const double kBottomSheetMaxWidth = 640;

/// Max width for a centered full-screen content column (e.g. Settings), so its
/// rows stay readable in landscape instead of running the whole width.
const double kContentMaxWidth = 760;

/// First width at which a second column of cards fits.
const double _wideBreakpoint = 600;

/// Width at which a third column fits (large tablets / desktop).
const double _extraWideBreakpoint = 1100;

/// Column count for a card grid at [width].
int responsiveColumns(double width) => width >= _extraWideBreakpoint
    ? 3
    : width >= _wideBreakpoint
    ? 2
    : 1;

extension ResponsiveContext on BuildContext {
  /// True once there's room for a multi-column layout (phone landscape and up).
  bool get isWideLayout => MediaQuery.sizeOf(this).width >= _wideBreakpoint;
}

/// Lays cards out in a responsive number of equal-width columns based on the
/// available width: one column when narrow (portrait phones), two or three side
/// by side when there's room. Cells hug their content height, so cards of
/// differing heights sit top-aligned within a row.
///
/// A sliver rather than a box, because the cells are built on demand: the whole
/// grid used to be one box inside the scroll view, which the viewport can
/// neither skip nor cull, so a few hundred records were laid out and painted on
/// every frame they scrolled past.
class SliverResponsiveCards extends StatelessWidget {
  const SliverResponsiveCards({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 12,
    this.runSpacing = 0,
    this.maxColumns,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Horizontal gap between columns.
  final double spacing;

  /// Vertical gap between rows. Leave at 0 for children that already carry
  /// their own bottom margin (e.g. record cards).
  final double runSpacing;

  /// Caps the computed column count.
  final int? maxColumns;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        var columns = responsiveColumns(constraints.crossAxisExtent);
        final cap = maxColumns;
        if (cap != null && columns > cap) columns = cap;
        final rows = (itemCount + columns - 1) ~/ columns;
        return SliverList.builder(
          itemCount: rows,
          itemBuilder: (context, row) => Padding(
            // Like the wrap's runSpacing: between rows only, never trailing.
            padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : runSpacing),
            child: columns == 1
                ? itemBuilder(context, row)
                : _row(context, row, columns),
          ),
        );
      },
    );
  }

  /// One row of [columns] equal-width cells, top-aligned so cards of differing
  /// heights sit flush at the top. The tail of the last row is filled with empty
  /// cells so the ones before it keep their width.
  Widget _row(BuildContext context, int row, int columns) {
    final first = row * columns;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var column = 0; column < columns; column++) ...[
          if (column > 0) SizedBox(width: spacing),
          Expanded(
            child: first + column < itemCount
                ? itemBuilder(context, first + column)
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

/// Centers [child] and caps its width at [maxWidth], for full-screen scrollable
/// content that would otherwise stretch across a landscape/tablet width.
class ContentConstraint extends StatelessWidget {
  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
