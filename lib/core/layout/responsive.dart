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

/// Lays [children] out in a responsive number of equal-width columns based on
/// the available width: one column when narrow (portrait phones), two or three
/// side by side when there's room. Cells hug their content height, so cards of
/// differing heights sit top-aligned within a row.
class ResponsiveCardWrap extends StatelessWidget {
  const ResponsiveCardWrap({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 0,
    this.maxColumns,
  });

  final List<Widget> children;

  /// Horizontal gap between columns.
  final double spacing;

  /// Vertical gap between rows. Leave at 0 for children that already carry
  /// their own bottom margin (e.g. record cards).
  final double runSpacing;

  /// Caps the computed column count (e.g. charts never go past two-up).
  final int? maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = responsiveColumns(constraints.maxWidth);
        final cap = maxColumns;
        if (cap != null && columns > cap) columns = cap;
        // Single column: full-width cells stacked by the Wrap's runSpacing.
        final cellWidth = columns <= 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: cellWidth, child: child),
          ],
        );
      },
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
