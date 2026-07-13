import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers.dart';

/// Bundled fonts (Manrope, JetBrains Mono) aren't pub packages, so their OFL
/// licenses aren't picked up by Flutter's automatic per-package license
/// collection — register them manually so they show up on the licenses page.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    const licenses = {
      'Manrope': 'assets/licenses/OFL-Manrope.txt',
      'JetBrains Mono': 'assets/licenses/OFL-JetBrainsMono.txt',
    };
    for (final entry in licenses.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const LubeLoggerApp(),
    ),
  );
}
