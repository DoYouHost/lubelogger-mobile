import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/models/vehicle.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/error_messages.dart';
import '../../providers.dart';
import '../vehicle/forms/record_form_scaffold.dart';

/// Opens the vehicle add/edit form as a modal bottom sheet. Pass [existing] to
/// edit that vehicle (prefilled). Resolves to the vehicle's id on success (the
/// new id when adding, the same id when editing) or `null` if cancelled. The
/// form invalidates [garageProvider] itself; edits also refresh the vehicle's
/// own info provider. (The API has no vehicle-delete, so there's no delete.)
Future<int?> showVehicleForm(BuildContext context, {Vehicle? existing}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _VehicleForm(existing: existing),
  );
}

/// The three fuel types the server accepts on write, with their wire names.
enum _FuelType {
  gasoline('Gasoline'),
  diesel('Diesel'),
  electric('Electric');

  const _FuelType(this.wireName);

  final String wireName;

  static _FuelType of(Vehicle v) => v.isElectric
      ? _FuelType.electric
      : v.isDiesel
          ? _FuelType.diesel
          : _FuelType.gasoline;

  String label(AppLocalizations l10n) => switch (this) {
        _FuelType.gasoline => l10n.fuelTypeGasoline,
        _FuelType.diesel => l10n.fuelTypeDiesel,
        _FuelType.electric => l10n.fuelTypeElectric,
      };
}

class _VehicleForm extends ConsumerStatefulWidget {
  const _VehicleForm({this.existing});

  final Vehicle? existing;

  @override
  ConsumerState<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends ConsumerState<_VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _year = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _licensePlate = TextEditingController();
  final _tags = TextEditingController();

  late _FuelType _fuelType;
  late bool _useHours;
  late bool _odometerOptional;
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _fuelType = e == null ? _FuelType.gasoline : _FuelType.of(e);
    _useHours = e?.useHours ?? false;
    _odometerOptional = e?.odometerOptional ?? false;
    if (e != null) {
      if (e.year > 0) _year.text = '${e.year}';
      _make.text = e.make;
      _model.text = e.model;
      _licensePlate.text = e.licensePlate;
      _tags.text = e.tags.join(' ');
    }
  }

  @override
  void dispose() {
    _year.dispose();
    _make.dispose();
    _model.dispose();
    _licensePlate.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);

    return RecordFormScaffold(
      formKey: _formKey,
      title: _isEditing ? l10n.formVehicleEditTitle : l10n.formVehicleTitle,
      isEditing: _isEditing,
      submitting: _submitting,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      onDelete: null, // no vehicle-delete endpoint in the API
      error: _error,
      fields: [
        TextFormField(
          controller: _year,
          enabled: !_submitting,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          style: const TextStyle(fontFamily: DashTokens.fontMono),
          decoration: dashFieldDecoration(t, labelText: l10n.formVehicleYear),
          validator: (raw) {
            final value = int.tryParse(raw?.trim() ?? '');
            if (value == null) {
              return (raw == null || raw.trim().isEmpty)
                  ? l10n.validationRequired
                  : l10n.validationNumber;
            }
            if (value < 1) return l10n.validationNumber;
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _make,
          enabled: !_submitting,
          textCapitalization: TextCapitalization.words,
          decoration: dashFieldDecoration(t, labelText: l10n.formVehicleMake),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _model,
          enabled: !_submitting,
          textCapitalization: TextCapitalization.words,
          decoration: dashFieldDecoration(t, labelText: l10n.formVehicleModel),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _licensePlate,
          enabled: !_submitting,
          textCapitalization: TextCapitalization.characters,
          decoration: dashFieldDecoration(
              t, labelText: l10n.formVehicleLicensePlate),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<_FuelType>(
          initialValue: _fuelType,
          decoration:
              dashFieldDecoration(t, labelText: l10n.formVehicleFuelType),
          items: [
            for (final v in _FuelType.values)
              DropdownMenuItem(value: v, child: Text(v.label(l10n))),
          ],
          onChanged: _submitting
              ? null
              : (v) => setState(() => _fuelType = v ?? _fuelType),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.formVehicleUseHours),
          value: _useHours,
          onChanged: _submitting ? null : (v) => setState(() => _useHours = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.formVehicleOdometerOptional),
          value: _odometerOptional,
          onChanged: _submitting
              ? null
              : (v) => setState(() => _odometerOptional = v),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tags,
          enabled: !_submitting,
          decoration: dashFieldDecoration(t, labelText: l10n.formTagsOptional),
        ),
      ],
    );
  }

  String? _requiredValidator(String? raw) {
    final l10n = AppLocalizations.of(context);
    return (raw == null || raw.trim().isEmpty) ? l10n.validationRequired : null;
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
      final int? resultId;
      if (existing == null) {
        resultId = await repo.addVehicle(
          year: int.parse(_year.text.trim()),
          make: _make.text.trim(),
          model: _model.text.trim(),
          licensePlate: _licensePlate.text.trim(),
          fuelType: _fuelType.wireName,
          useHours: _useHours,
          odometerOptional: _odometerOptional,
          tags: _tags.text.trim(),
        );
      } else {
        await repo.updateVehicle(
          id: existing.id,
          year: int.parse(_year.text.trim()),
          make: _make.text.trim(),
          model: _model.text.trim(),
          licensePlate: _licensePlate.text.trim(),
          fuelType: _fuelType.wireName,
          useHours: _useHours,
          odometerOptional: _odometerOptional,
          tags: _tags.text.trim(),
          // Resend the existing identifier/extra fields — the update endpoint
          // overwrites them with whatever we send.
          identifier: existing.identifier,
          extraFields: existing.extraFields,
        );
        resultId = existing.id;
        ref.invalidate(vehicleInfoProvider(existing.id));
      }
      ref.invalidate(garageProvider);
      if (!mounted) return;
      Navigator.pop(context, resultId);
      messenger.showSnackBar(SnackBar(
          content: Text(existing == null ? l10n.vehicleAdded : l10n.vehicleUpdated)));
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
        _error = existing == null ? l10n.vehicleAddError : l10n.vehicleUpdateError;
      });
    }
  }
}
