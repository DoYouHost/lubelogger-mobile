import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/auth/whoami.dart';
import '../../core/settings/server_profile.dart';
import '../../providers.dart';

/// Validation errors raised by the setup screen itself (distinct from an
/// [AppApiException] from the network layer). Translated in the UI.
enum SetupErrorCode { missingUrl, missingApiKey }

class SetupState {
  const SetupState({this.busy = false, this.error});

  final bool busy;

  /// A [SetupErrorCode] or an [AppApiException]; translated on display.
  final Object? error;

  SetupState copyWith({bool? busy, Object? error}) =>
      SetupState(busy: busy ?? this.busy, error: error);
}

final setupControllerProvider =
    AutoDisposeNotifierProvider<SetupController, SetupState>(
  SetupController.new,
);

/// Drives the login screen: validate input, verify the API key against
/// `GET /api/whoami`, then persist the profile (which flips the router to the
/// app — see `router.dart`).
class SetupController extends AutoDisposeNotifier<SetupState> {
  @override
  SetupState build() => const SetupState();

  Future<void> connect({
    required String rawUrl,
    required String apiKey,
  }) async {
    final url = ServerProfile.normalizeBaseUrl(rawUrl);
    if (url.isEmpty) {
      state = state.copyWith(error: SetupErrorCode.missingUrl);
      return;
    }
    if (apiKey.trim().isEmpty) {
      state = state.copyWith(error: SetupErrorCode.missingApiKey);
      return;
    }
    state = const SetupState(busy: true);
    try {
      final result = await ref.read(authServiceProvider).verifyAndStoreApiKey(
            baseUrl: url,
            apiKey: apiKey.trim(),
          );
      await _saveProfile(result.baseUrl, result.who);
    } on AppApiException catch (e) {
      state = SetupState(error: e);
    }
  }

  /// Saving the profile switches the router to the app shell (see routerProvider).
  Future<void> _saveProfile(String url, WhoAmI who) =>
      ref.read(serverProfileProvider.notifier).save(
            ServerProfile(
              baseUrl: url,
              label: who.displayName.isEmpty ? null : who.displayName,
            ),
          );
}
