import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/background/background_worker.dart';
import '../../providers.dart';

/// Keeps the offline layer moving without anything on screen having to ask.
///
/// Two triggers, because a queued write has two ways of becoming deliverable:
/// the user comes back to the app (drain it here and now), or the network
/// returns while the app is away (ask the system for a pass, which is what its
/// connectivity constraint is for).
///
/// Mounted for the whole app, above the router.
class SyncHost extends ConsumerStatefulWidget {
  const SyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncHost> createState() => _SyncHostState();
}

class _SyncHostState extends ConsumerState<SyncHost> {
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _sync);
    // A launch is a resume the listener doesn't report, and it is the one the
    // background isolate is most likely to have left work behind for.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    if (!mounted || ref.read(serverProfileProvider) == null) return;
    await ref.read(syncStateProvider.notifier).syncNow();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(syncStateProvider, (previous, next) {
      if (next.pending.isEmpty) return;
      // Idempotent by policy, so every queued write may ask.
      requestWriteRetry().ignore();
    });
    return widget.child;
  }
}
