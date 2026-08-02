import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/customer.dart';
import '../../state/customers_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/ids.dart';
import '../../widgets/measurement_sections.dart';
import '../../widgets/photo_gallery_field.dart';
import '../../widgets/section_header.dart';

/// Add or edit a customer. Pass an existing [customer] to edit it;
/// leave it null to create a new one.
class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customer});

  final Customer? customer;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _notesCtrl;
  late final Map<String, TextEditingController> _measurementCtrls;
  late List<String> _photoPaths;
  bool _saving = false;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _photoPaths = List.of(c?.photoPaths ?? const []);
    _measurementCtrls = {
      for (final f in measurementFields)
        f.key: TextEditingController(text: c?.measurement(f.key)?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    for (final ctrl in _measurementCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  double? _parseMeasurement(String key) {
    final text = _measurementCtrls[key]!.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final controller = context.read<CustomersController>();
    final now = DateTime.now();
    final customer = Customer(
      id: widget.customer?.id ?? generateId(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      photoPaths: _photoPaths,
      measurements: {
        for (final f in measurementFields) f.key: _parseMeasurement(f.key),
      },
      createdAt: widget.customer?.createdAt ?? now,
    );

    if (_isEditing) {
      await controller.edit(customer);
    } else {
      await controller.add(customer);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit customer' : 'New customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PhotoGalleryField(
              photoPaths: _photoPaths,
              onChanged: (paths) => setState(() => _photoPaths = paths),
              storageSubfolder: 'customer_photos',
              label: 'Reference photos (optional)',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Preferences, style notes…',
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            const SectionHeader('MEASUREMENTS (INCHES)'),
            const SizedBox(height: 8),
            MeasurementSections(
              fieldBuilder: (field) => TextFormField(
                controller: _measurementCtrls[field.key],
                decoration: InputDecoration(labelText: field.label),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return double.tryParse(v.trim()) == null ? 'Invalid' : null;
                },
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(_isEditing ? 'Save changes' : 'Save customer'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.thread,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
