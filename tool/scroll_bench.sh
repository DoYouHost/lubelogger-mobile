#!/usr/bin/env bash
# Deterministic scroll benchmark: same gestures, same screen, every run.
#
# Hand-scrolling is not a measurement — two runs differ in length, speed and
# where they stopped, and the numbers then say more about the hand than the code.
# This drives the app through a fixed script and reports only the frames produced
# during the measured phase.
#
# Timings come from a frame probe that deliberately does not live in the app:
# `--emit-probe` writes it, you wire the one call it needs, measure, then drop
# both again. Deleting them is the point — a diagnostic that ships is a
# diagnostic nobody removes.
#
#   tool/scroll_bench.sh --emit-probe        # writes the file, prints the wiring
#   flutter build apk --profile --dart-define=frame_log=true
#   tool/scroll_bench.sh <label> [serial]
#
# PROFILE mode matters: debug drops frames for reasons a release build does not
# have, so debug timings answer a question nobody asked.
#
# Coordinates are calibrated for the 1080x1920 phone this was written against
# (FRD-L09). On another screen, re-derive CARD_TAP and the swipe geometry.
#
# usage: tool/scroll_bench.sh <label> [serial]
set -euo pipefail

PROBE=lib/core/diagnostics/frame_probe.dart

if [ "${1:-}" = "--emit-probe" ]; then
    mkdir -p "$(dirname "$PROBE")"
    cat > "$PROBE" <<'DART'
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// TEMPORARY, emitted by tool/scroll_bench.sh — delete when done measuring.
///
/// Per-second frame timings for the benchmark to parse. `b` is Dart work (build,
/// layout, paint recording), `r` is the GPU replaying it; the two have different
/// causes and different fixes. Every second that produced frames is reported,
/// clean ones included — a line only for the bad seconds leaves the denominator
/// unknown, which is how a longer run reads as a worse one.
class FrameProbe {
  FrameProbe._();

  static const _enabled = bool.fromEnvironment('frame_log');
  static const _budgetMs = int.fromEnvironment(
    'frame_budget_ms',
    defaultValue: 16,
  );

  static final List<double> _build = [];
  static final List<double> _raster = [];
  static DateTime _windowStart = DateTime.now();

  static void startIfEnabled() {
    if (kReleaseMode || !_enabled) return;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    debugPrint('[frames] budget=${_budgetMs}ms');
  }

  static void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _build.add(timing.buildDuration.inMicroseconds / 1000);
      _raster.add(timing.rasterDuration.inMicroseconds / 1000);
    }
    final now = DateTime.now();
    if (now.difference(_windowStart) < const Duration(seconds: 1)) return;
    _windowStart = now;
    if (_build.isEmpty) return;

    var late = 0;
    for (var i = 0; i < _build.length; i++) {
      if (_build[i] > _budgetMs || _raster[i] > _budgetMs) late++;
    }
    debugPrint(
      '[frames] n=${_build.length} late=$late '
      'bsum=${_sum(_build).toStringAsFixed(1)} bmax=${_max(_build).toStringAsFixed(1)} '
      'rsum=${_sum(_raster).toStringAsFixed(1)} rmax=${_max(_raster).toStringAsFixed(1)}',
    );
    _build.clear();
    _raster.clear();
  }

  static double _sum(List<double> v) => v.fold(0, (a, b) => a + b);

  static double _max(List<double> v) => v.reduce((a, b) => a > b ? a : b);
}
DART
    cat >&2 <<TXT
wrote $PROBE

Add to main(), right after WidgetsFlutterBinding.ensureInitialized():
    FrameProbe.startIfEnabled();
and the import:
    import 'core/diagnostics/frame_probe.dart';

When finished:  rm $PROBE  and revert main.dart
TXT
    exit 0
fi

LABEL="${1:?pass a label for the run, or --emit-probe to write the probe}"
SERIAL="${2:-}"
ADB=(adb)
[ -n "$SERIAL" ] && ADB=(adb -s "$SERIAL")

PKG=page.codeberg.doyouhost.lubelogger_mobile

# Garage: centre of the first (only) vehicle card.
CARD_TAP=(540 739)
# Vehicle screen: horizontal swipes over the tab body, one per tab. The fuel tab
# is the 6th of 12, and the screen opens on the 1st.
TAB_SWIPES=5
# Measured phase: flings up and down over the record list, alternating so the
# list keeps moving instead of resting against an end.
#
# Overridable from the environment, because how hard the list is thrown decides
# how many rows have to be built in one frame — a gentle drag and a real flick
# are different tests, and a harness that only does the gentle one will report a
# screen as smooth that stutters in a hand.
FLING_PAIRS="${FLING_PAIRS:-8}"
FLING_MS="${FLING_MS:-200}"
FLING_GAP="${FLING_GAP:-0.35}"
FLING_FROM="${FLING_FROM:-1500}"
FLING_TO="${FLING_TO:-500}"

log() { printf '  %s\n' "$*" >&2; }

log "$LABEL: restarting $PKG"
"${ADB[@]}" shell am force-stop "$PKG"
"${ADB[@]}" logcat -c
"${ADB[@]}" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1

# The probe announces itself once the app is up; without it there is nothing to
# measure, so fail loudly rather than reporting an empty run as a good one.
for _ in $(seq 1 30); do
    if "${ADB[@]}" logcat -d -s flutter:I | grep -q '\[frames\] budget='; then break; fi
    sleep 1
done
if ! "${ADB[@]}" logcat -d -s flutter:I | grep -q '\[frames\] budget='; then
    echo "FrameProbe never reported in; was the app built with --dart-define=frame_log=true?" >&2
    exit 1
fi

sleep 6                                   # let the garage finish loading
log "$LABEL: opening the vehicle"
"${ADB[@]}" shell input tap "${CARD_TAP[0]}" "${CARD_TAP[1]}"
sleep 5
log "$LABEL: swiping to the fuel tab"
for _ in $(seq 1 "$TAB_SWIPES"); do
    "${ADB[@]}" shell input swipe 900 1000 200 1000 250
    sleep 1
done
sleep 4                                   # records loaded and settled

# Everything above is setup, and its frames are not the ones under test.
"${ADB[@]}" logcat -c
log "$LABEL: measuring ($FLING_PAIRS fling pairs)"
for _ in $(seq 1 "$FLING_PAIRS"); do
    "${ADB[@]}" shell input swipe 540 "$FLING_FROM" 540 "$FLING_TO" "$FLING_MS"
    sleep "$FLING_GAP"
    "${ADB[@]}" shell input swipe 540 "$FLING_TO" 540 "$FLING_FROM" "$FLING_MS"
    sleep "$FLING_GAP"
done
sleep 1

"${ADB[@]}" logcat -d -s flutter:I | grep -F '[frames] n=' | awk -v label="$LABEL" '
{
    for (i = 1; i <= NF; i++) {
        split($i, kv, "=")
        v[kv[1]] = kv[2]
    }
    sec++; n += v["n"]; late += v["late"]
    bsum += v["bsum"]; rsum += v["rsum"]
    if (v["bmax"] + 0 > bmax) bmax = v["bmax"] + 0
    if (v["rmax"] + 0 > rmax) rmax = v["rmax"] + 0
}
END {
    if (n == 0) { print label ": no frames captured"; exit 1 }
    printf "%-14s sekund=%d klatek=%d spoznionych=%d (%.1f%%)  build sr=%.1fms max=%.1fms  raster sr=%.1fms max=%.1fms\n",
        label, sec, n, late, 100 * late / n, bsum / n, bmax, rsum / n, rmax
}'
