import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/models/attachment.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';

const _imageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'heic',
  'heif',
};

String _extension(String name) {
  final dot = name.lastIndexOf('.');
  return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
}

bool _isImage(String name) => _imageExtensions.contains(_extension(name));

/// Replace path separators so a file name can't escape the cache directory.
String _safeName(String name) => name.replaceAll(RegExp(r'[/\\]'), '_');

/// Open an attachment. Images open in an in-app zoomable viewer, authenticated
/// with the `x-api-key` header so the key never lands in a URL. Other types are
/// downloaded with the authenticated client and handed to the OS's default app
/// (the server accepts the key for `/documents`). Failures surface as a snackbar.
Future<void> openAttachment(
  BuildContext context,
  WidgetRef ref,
  Attachment file,
) async {
  if (_isImage(file.name)) {
    await _openImage(context, ref, file);
  } else {
    await _downloadAndOpen(context, ref, file);
  }
}

Future<void> _openImage(
  BuildContext context,
  WidgetRef ref,
  Attachment file,
) async {
  final profile = ref.read(serverProfileProvider);
  if (profile == null) return;
  final apiKey = await ref.read(apiKeyProvider.future);
  if (!context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => _ImageViewerPage(
        url: '${profile.baseUrl}${file.location}',
        apiKey: apiKey,
        title: file.name,
      ),
    ),
  );
}

Future<void> _downloadAndOpen(
  BuildContext context,
  WidgetRef ref,
  Attachment file,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final nav = Navigator.of(context, rootNavigator: true);

  // Blocking spinner while the file downloads.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  String? savePath;
  try {
    final dir = await getTemporaryDirectory();
    savePath = '${dir.path}/${_safeName(file.name)}';
    await ref.read(vehiclesRepositoryProvider).downloadDocument(
          file.location,
          savePath,
        );
  } on Object {
    savePath = null;
  }

  nav.pop(); // dismiss the spinner

  if (savePath == null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.attachmentOpenError)));
    return;
  }
  final result = await OpenFilex.open(savePath);
  if (result.type != ResultType.done) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.attachmentOpenError)));
  }
}

/// Full-screen, pinch-to-zoom image viewer. Loads the image with the auth
/// header so the API key stays out of the URL.
class _ImageViewerPage extends StatelessWidget {
  const _ImageViewerPage({
    required this.url,
    required this.apiKey,
    required this.title,
  });

  final String url;
  final String? apiKey;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.network(
            url,
            headers: apiKey == null ? null : {'x-api-key': apiKey!},
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const CircularProgressIndicator(),
            errorBuilder: (context, error, stack) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.attachmentOpenError,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
