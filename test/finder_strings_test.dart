import 'package:app_guards/app_guards.dart';
import 'package:flutter_test/flutter_test.dart';

/// A finder that spells out the app's own copy breaks on every wording change,
/// so the tests read it from the localizations: `find.text(en.actionSave)`.
/// What is not copy stays literal — server data, fixture names, and the
/// framework's own strings, the few of which that equal a message are below.
void main() {
  const notAppCopy = <String>{
    'OK', // MaterialLocalizations: the stock date picker's button
  };

  test('no finder in test/ spells out copy that lives in the .arb', () {
    final offenders = finderCopy(
      AppCopy.fromArb('lib/l10n/app_en.arb', prefix: 'en'),
      allowed: notAppCopy,
    );
    expect(
      offenders.join('\n'),
      isEmpty,
      reason:
          'These read their text from a literal. Use en.<key>; if the text is '
          'server data that happens to look like copy, add it to notAppCopy '
          'with its source.',
    );
  });
}
