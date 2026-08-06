import 'package:flutter/widgets.dart';

/// Names a control for the diagnostic log.
///
/// The log records identifiers and **never** accessibility labels: a label is
/// user-facing text — a vehicle name, a plate, a note — and the log can end up
/// in a public, permanent issue. So a control the user can press is worth naming
/// here; without it a tap on it reads as `role=button` and nothing more.
///
/// Ids are dotted and stable: `area.thing`, lowercase, never localized, never
/// containing data (`garage.card`, not `garage.card.VW-Golf`). Repeated rows
/// share one id — which row it was is not what a bug report needs.
///
/// The probe carries an identifier down to the node actually hit, so tagging a
/// card names taps anywhere inside it unless something deeper has its own tag.
Widget logTag(String id, Widget child) =>
    Semantics(identifier: id, child: child);

/// Names a whole area of the app **and** everything inside it: the taps (via
/// [logTag]) and the code (via [LogSurface.of]).
///
/// This is the hierarchical unit — a screen, a tab, a sheet. One wrap names
/// every control underneath that does not name itself, and lets shared widgets
/// like the error and empty views say which screen they are standing on without
/// every call site passing it down by hand.
Widget logSurface(String id, Widget child) =>
    LogSurface(id, child: logTag(id, child));

/// The nearest enclosing [logSurface] name, for code that has a context but no
/// idea where it is being used.
class LogSurface extends InheritedWidget {
  const LogSurface(this.id, {required super.child, super.key});

  final String id;

  /// Read without registering a dependency, so it is usable from `initState` —
  /// which is where a one-shot record belongs, a rebuild being no news.
  static String? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LogSurface>()?.id;

  @override
  bool updateShouldNotify(LogSurface oldWidget) => oldWidget.id != id;
}

extension LogTagged on Widget {
  /// Same as [logTag], written after the widget instead of around it — for
  /// long widget expressions, where wrapping would re-indent the whole tree.
  Widget tagged(String id) => logTag(id, this);

  /// Postfix form of [logSurface].
  Widget surface(String id) => logSurface(id, this);
}
