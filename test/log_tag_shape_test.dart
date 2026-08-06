import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/diagnostics/log_redactor.dart';

/// Every `logTag` / `logSurface` identifier in the app, with the file it is in.
///
/// Read off the source rather than off a registry: a tag is a string literal at
/// a call site, and a registry would be a second place to forget. Comments are
/// stripped first — the redactor's own doc comment quotes a bad tag as an
/// example of one.
List<(String file, String id)> _declaredTags() {
  final call = RegExp(
    r"""(?:logTag|logSurface)\(\s*'([^']*)'|\.(?:tagged|surface)\(\s*'([^']*)'""",
  );
  final comment = RegExp(r'^\s*//.*$', multiLine: true);
  final found = <(String, String)>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = entity.readAsStringSync().replaceAll(comment, '');
    for (final match in call.allMatches(source)) {
      found.add((entity.path, match.group(1) ?? match.group(2)!));
    }
  }
  found.sort((a, b) => '${a.$1}${a.$2}'.compareTo('${b.$1}${b.$2}'));
  return found;
}

/// What the tag is at run time, as far as its *shape* goes: an interpolation
/// stands in for one word, because every one of them is an enum's `name`.
String _asWritten(String literal) => literal
    .replaceAll(RegExp(r'\$\{[^}]*\}'), 'x')
    .replaceAll(RegExp(r'\$\w+'), 'x');

void main() {
  // Ids are compared against the shape the redactor trusts. Both halves matter:
  // an id that does not match is scrubbed like any other string — so a server
  // called `garage` would turn `garage.card` into `[HOST].card` — and an id that
  // does match is written to a public issue verbatim, so it had better be a name
  // this app chose rather than something read off the screen.
  final shape = LogRedactor.ourKeys['id']!;

  test('every control identifier is a dotted, unlocalized name', () {
    final tags = _declaredTags();
    // A guard that finds nothing is a guard that is not running.
    expect(tags.length, greaterThan(30));

    final offenders = [
      for (final (file, id) in tags)
        if (!shape.hasMatch(_asWritten(id))) '$file: "$id"',
    ];
    expect(offenders, isEmpty);
  });

  test('an identifier carries a name, never a value', () {
    // Interpolation is how data gets into one by accident. Every one of these
    // interpolates an enum's own `name` or a literal name passed in beside it —
    // a compile-time set of unlocalized words. Anything new in this list has to
    // justify itself here first.
    final interpolated = [
      for (final (file, id) in _declaredTags())
        if (id.contains(r'$')) '$file: "$id"',
    ];
    expect(interpolated, [
      'lib/features/common/confirm_dialog.dart: "confirm.\$what"',
      'lib/features/settings/settings_screen.dart: "settings.\$id"',
      'lib/features/vehicle/add_record_sheet.dart: "add_sheet.\${tab.name}"',
      'lib/features/vehicle/forms/add_generic_record_form.dart: '
          '"form.\${kind.name}"',
      'lib/features/vehicle/vehicle_screen.dart: "vehicle.\${t.id}"',
      'lib/features/vehicle/vehicle_screen.dart: "vehicle.tabbar.\${tab.id}"',
    ]);
  });

  test("the recorder's own controls are named so the probe can skip them", () {
    // `InteractionProbe.ownUiPrefix` — the recorder must not record the user
    // operating the recorder.
    final own = [
      for (final (file, id) in _declaredTags())
        if (file.contains('features/bug_report/')) id,
    ];
    expect(own, isNotEmpty);
    expect(own.every((id) => id.startsWith('bug_report.')), isTrue);
  });
}
