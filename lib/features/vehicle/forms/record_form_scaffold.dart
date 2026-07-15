import 'package:flutter/material.dart';

import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Shared chrome for a record add/edit bottom sheet: a title row (with a delete
/// action when editing and a close button), the caller's [fields] inside a
/// [Form], an optional error line, and the cancel / add-or-save buttons. The
/// owning widget keeps the form key, controllers and submit/delete logic; this
/// only lays out the common shell so every record form looks identical.
class RecordFormScaffold extends StatelessWidget {
  const RecordFormScaffold({
    super.key,
    required this.formKey,
    required this.title,
    required this.isEditing,
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
    required this.onDelete,
    required this.error,
    required this.fields,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final bool isEditing;
  final bool submitting;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  /// Invoked by the delete icon; only shown when [isEditing].
  final VoidCallback? onDelete;
  final String? error;
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: DashTokens.fontUi,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  if (isEditing && onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: t.danger),
                      onPressed: submitting ? null : onDelete,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: submitting ? null : onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...fields,
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style:
                      TextStyle(color: t.danger, fontFamily: DashTokens.fontUi),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: submitting ? null : onCancel,
                      child: Text(l10n.actionCancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: submitting ? null : onSubmit,
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? l10n.actionSave : l10n.actionAdd),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
