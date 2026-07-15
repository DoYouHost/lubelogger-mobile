import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/format/shift_digits_formatter.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/plan_record.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/error_messages.dart';
import '../../../providers.dart';
import 'attachments_field.dart';
import 'form_fields.dart';
import 'record_form_scaffold.dart';

const _costFormat = ShiftDigitsFormatter(decimalDigits: 2, minIntegerDigits: 3);

/// Progress states the API accepts on write — Done is excluded (plans reach
/// Done only via the planner board; the API rejects setting it).
const _writableProgress = [
  PlanProgress.backlog,
  PlanProgress.inProgress,
  PlanProgress.testing,
];

/// Opens the add/edit form for a planner item as a modal bottom sheet. Pass
/// [existing] to edit that item instead (prefilled, with a delete option).
/// Resolves to `true` once an item was added/updated/deleted, or `null` if
/// cancelled.
Future<bool?> showAddPlanForm(
  BuildContext context,
  int vehicleId, {
  PlanRecord? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AddPlanForm(vehicleId: vehicleId, existing: existing),
  );
}

class _AddPlanForm extends ConsumerStatefulWidget {
  const _AddPlanForm({required this.vehicleId, this.existing});

  final int vehicleId;
  final PlanRecord? existing;

  @override
  ConsumerState<_AddPlanForm> createState() => _AddPlanFormState();
}

class _AddPlanFormState extends ConsumerState<_AddPlanForm> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _cost = TextEditingController();
  final _notes = TextEditingController();

  late PlanType _type;
  late PlanPriority _priority;
  late PlanProgress _progress;
  List<Attachment> _files = const [];
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    // Fall back to sensible defaults for add, or when a stored value isn't one
    // the API can write back (unknown enum, or a Done plan being edited).
    _type = (e != null && e.type != PlanType.unknown) ? e.type : PlanType.service;
    _priority = (e != null && e.priority != PlanPriority.unknown)
        ? e.priority
        : PlanPriority.normal;
    _progress = (e != null && _writableProgress.contains(e.progress))
        ? e.progress
        : PlanProgress.backlog;
    if (e != null) {
      _description.text = e.description;
      _cost.text = _costFormat.seed(e.cost);
      _notes.text = e.notes;
      _files = [...e.files];
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);

    return RecordFormScaffold(
      formKey: _formKey,
      title: _isEditing ? l10n.formPlanEditTitle : l10n.formPlanTitle,
      isEditing: _isEditing,
      submitting: _submitting,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      onDelete: _confirmDelete,
      error: _error,
      fields: [
        TextFormField(
          controller: _description,
          enabled: !_submitting,
          decoration: dashFieldDecoration(t, labelText: l10n.colDescription),
          validator: (raw) => (raw == null || raw.trim().isEmpty)
              ? l10n.validationRequired
              : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<PlanType>(
          initialValue: _type,
          decoration: dashFieldDecoration(t, labelText: l10n.formPlanType),
          items: [
            for (final v in PlanType.values)
              if (v != PlanType.unknown)
                DropdownMenuItem(value: v, child: Text(_typeLabel(v, l10n))),
          ],
          onChanged:
              _submitting ? null : (v) => setState(() => _type = v ?? _type),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<PlanPriority>(
          initialValue: _priority,
          decoration: dashFieldDecoration(t, labelText: l10n.formPlanPriority),
          items: [
            for (final v in PlanPriority.values)
              if (v != PlanPriority.unknown)
                DropdownMenuItem(value: v, child: Text(_priorityLabel(v, l10n))),
          ],
          onChanged: _submitting
              ? null
              : (v) => setState(() => _priority = v ?? _priority),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<PlanProgress>(
          initialValue: _progress,
          decoration: dashFieldDecoration(t, labelText: l10n.formPlanProgress),
          items: [
            for (final v in _writableProgress)
              DropdownMenuItem(value: v, child: Text(_progressLabel(v, l10n))),
          ],
          onChanged: _submitting
              ? null
              : (v) => setState(() => _progress = v ?? _progress),
        ),
        const SizedBox(height: 14),
        _CostField(
          controller: _cost,
          enabled: !_submitting,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _notes,
          enabled: !_submitting,
          minLines: 2,
          maxLines: 4,
          decoration: dashFieldDecoration(t, labelText: l10n.formNotesOptional),
        ),
        const SizedBox(height: 14),
        AttachmentsField(
          initial: _files,
          enabled: !_submitting,
          onChanged: (files) => _files = files,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    final repo = ref.read(vehiclesRepositoryProvider);
    final existing = widget.existing;
    try {
      if (existing == null) {
        await repo.addPlanRecord(
          vehicleId: widget.vehicleId,
          description: _description.text.trim(),
          cost: parseFormNumber(_cost.text)!,
          type: _type,
          priority: _priority,
          progress: _progress,
          notes: _notes.text.trim(),
          files: _files,
        );
      } else {
        await repo.updatePlanRecord(
          id: existing.id,
          description: _description.text.trim(),
          cost: parseFormNumber(_cost.text)!,
          type: _type,
          priority: _priority,
          progress: _progress,
          notes: _notes.text.trim(),
          files: _files,
        );
      }
      ref.invalidate(planRecordsProvider(widget.vehicleId));
      ref.invalidate(vehicleInfoProvider(widget.vehicleId));
      if (!mounted) return;
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(
            content:
                Text(existing == null ? l10n.recordAdded : l10n.recordUpdated)),
      );
    } on AppApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.localized(l10n);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error =
            existing == null ? l10n.recordAddError : l10n.recordUpdateError;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.actionDelete, style: TextStyle(color: t.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(vehiclesRepositoryProvider)
          .deletePlanRecord(widget.existing!.id);
      ref.invalidate(planRecordsProvider(widget.vehicleId));
      ref.invalidate(vehicleInfoProvider(widget.vehicleId));
      if (!mounted) return;
      Navigator.pop(context, true);
      messenger.showSnackBar(SnackBar(content: Text(l10n.recordDeleted)));
    } on AppApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.localized(l10n);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.recordDeleteError;
      });
    }
  }
}

String _typeLabel(PlanType v, AppLocalizations l10n) => switch (v) {
      PlanType.service => l10n.catService,
      PlanType.repair => l10n.catRepairs,
      PlanType.upgrade => l10n.catUpgrades,
      PlanType.unknown => l10n.catService,
    };

String _priorityLabel(PlanPriority v, AppLocalizations l10n) => switch (v) {
      PlanPriority.critical => l10n.planPriorityCritical,
      PlanPriority.normal => l10n.planPriorityNormal,
      PlanPriority.low => l10n.planPriorityLow,
      PlanPriority.unknown => l10n.planPriorityNormal,
    };

String _progressLabel(PlanProgress v, AppLocalizations l10n) => switch (v) {
      PlanProgress.backlog => l10n.planProgressBacklog,
      PlanProgress.inProgress => l10n.planProgressInProgress,
      PlanProgress.testing => l10n.planProgressTesting,
      PlanProgress.done => l10n.planProgressDone,
      PlanProgress.unknown => l10n.planProgressBacklog,
    };

/// Required cost field (allows 0) shared shape with the other forms' numeric
/// inputs — monospace, shift-digits entry.
class _CostField extends StatelessWidget {
  const _CostField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: const [_costFormat],
      style: const TextStyle(fontFamily: DashTokens.fontMono),
      decoration: dashFieldDecoration(t, labelText: l10n.colCost),
      validator: (raw) {
        final value = parseFormNumber(raw);
        if (value == null) {
          return (raw == null || raw.trim().isEmpty)
              ? l10n.validationRequired
              : l10n.validationNumber;
        }
        if (value < 0) return l10n.validationNumber;
        return null;
      },
    );
  }
}
