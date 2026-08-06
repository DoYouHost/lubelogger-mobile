import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'diagnostic_recorder.dart';
import 'log_event.dart';

/// Records which screen the user is on, as `route` lines with `from` and `to`.
///
/// A tap records an identifier and a role and nothing else (labels are not
/// logged at all), so without the screen the log is only half-readable: the same
/// `record.add` identifier shows up on every vehicle tab.
///
/// Reads the router's own configuration rather than watching [Route] objects: a
/// route carries its *pattern* at best. What the location cannot see — dialogs,
/// sheets and menus, which leave it untouched — is [ModalObserver]'s job.
///
/// Installed for the app's lifetime and writing through
/// `DiagnosticRecorder.active`, which is null unless a recording runs.
class NavigationProbe {
  /// The screen the app is showing, kept current whether or not a recording is
  /// running: a session started on a vehicle page has to say so in its first
  /// records, and the probe only ever reports the *next* change.
  ///
  /// Static so the recorder can reach it without depending on the router, which
  /// is rebuilt whenever the server profile changes.
  static String? get screen => _screen;
  static String? _screen;

  GoRouterDelegate? _delegate;

  /// Starts following [router]. Call once, right after the router is built.
  void watch(GoRouter router) {
    _delegate = router.routerDelegate;
    // Keep the screen the user is looking at when the new router has not
    // resolved one yet. Saving a server profile rebuilds the router, and
    // clearing here would drop the `from` of the very transition that says the
    // setup finally worked.
    _screen = _locationOf(router.routerDelegate) ?? _screen;
    router.routerDelegate.addListener(_onRouterChanged);
  }

  void unwatch() {
    _delegate?.removeListener(_onRouterChanged);
    _delegate = null;
  }

  void _onRouterChanged() {
    final delegate = _delegate;
    if (delegate == null) return;
    final to = _locationOf(delegate);
    // Redirects and imperative pushes can settle on the location already
    // showing; one record per actual change.
    if (to == null || to == _screen) return;
    final from = _screen;
    _screen = to;
    DiagnosticRecorder.active?.add(
      LogSource.ui,
      'route',
      fields: {'from': from, 'to': to},
    );
  }

  /// The topmost screen's path. `matchedLocation` carries no query string, and
  /// its path parameter (`/vehicle/:id`) is resolved to the id the user is
  /// actually looking at — an internal row id, which names nobody.
  static String? _locationOf(GoRouterDelegate delegate) {
    // Empty until the first frame, and `state` throws on an empty configuration.
    if (delegate.currentConfiguration.isEmpty) return null;
    final path = delegate.state.matchedLocation;
    return path.isEmpty ? null : path;
  }
}

/// Records what gets pushed on top of a screen by hand — dialogs, bottom sheets,
/// popup menus — as `open` and `close` lines with a `kind`.
///
/// This app pushes a lot of them: every add/edit form is a bottom sheet, and
/// every delete goes through a dialog, none of which touches the location.
///
/// **One instance per [Navigator].** Flutter asserts that an observer belongs to
/// a single navigator, so a shared instance would crash on the second one.
class ModalObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log('open', route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log('close', route);

  // didReplace and didRemove are deliberately left alone: go_router's own
  // screens are [NavigationProbe]'s job, and nothing in the app replaces or
  // silently removes a dialog.

  void _log(String evt, Route<dynamic> route) {
    // go_router builds every screen as a `Page`, and those are reported by the
    // location instead. What is left is what was pushed by hand.
    if (route.settings is Page) return;
    DiagnosticRecorder.active?.add(
      LogSource.ui,
      evt,
      fields: {'kind': kindOf(route), 'name': route.settings.name},
    );
  }

  /// What kind of thing was pushed. Tested against the public route classes
  /// rather than type names, which a release build may obfuscate.
  static String kindOf(Route<dynamic> route) {
    if (route is ModalBottomSheetRoute) return 'sheet';
    if (route is RawDialogRoute) return 'dialog'; // DialogRoute extends it
    if (route is PopupRoute) return 'popup'; // popup menus, dropdowns
    if (route is PageRoute) return 'page';
    return 'route';
  }
}
