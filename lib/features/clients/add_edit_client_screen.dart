import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/gs_button.dart';
import '../../providers/data_hub.dart';
import '../../models/client.dart';

/// Form for adding or editing a client / lead.
class AddEditClientScreen extends StatefulWidget {
  final ClientModel? client; // null = add mode

  const AddEditClientScreen({super.key, this.client});

  @override
  State<AddEditClientScreen> createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _villageController = TextEditingController();
  final _billController = TextEditingController();
  final _notesController = TextEditingController();

  String _area = GSArea.talaja;
  String _propertyType = GSPropertyType.residential;
  String _preferredPackage = '3.08';
  String _source = GSSource.website;

  bool get isEdit => widget.client != null;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final c = widget.client!;
      _nameController.text = c.name;
      _phoneController.text = c.phone;
      _altPhoneController.text = c.altPhone ?? '';
      _area = c.area;
      _villageController.text = c.village ?? '';
      _propertyType = c.propertyType;
      _billController.text = c.monthlyBill.toInt().toString();
      _preferredPackage = c.preferredPackage == 'not-sure' ? '3.08' : c.preferredPackage;
      _source = c.source;
      _notesController.text = c.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _villageController.dispose();
    _billController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final hub = context.read<DataHub>();
    final now = DateTime.now();

    final client = ClientModel(
      id: isEdit ? widget.client!.id : hub.generateId(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      altPhone: _altPhoneController.text.trim().isNotEmpty
          ? _altPhoneController.text.trim()
          : null,
      area: _area,
      village: _area == GSArea.village
          ? _villageController.text.trim()
          : null,
      propertyType: _propertyType,
      monthlyBill: double.tryParse(_billController.text) ?? 0,
      preferredPackage: _preferredPackage,
      source: _source,
      status: isEdit ? widget.client!.status : GSClientStatus.newLead,
      ownerUid: isEdit ? widget.client!.ownerUid : GSUsers.founderUid,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: isEdit ? widget.client!.createdAt : now,
      updatedAt: now,
    );

    if (isEdit) {
      await hub.updateClient(client);
    } else {
      await hub.addClient(client);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEdit ? 'Client updated' : 'Client added')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      appBar: AppBar(title: Text(isEdit ? 'Edit Client' : 'Add Client')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: 'Phone Number', prefixText: '+91 '),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().length < 10 ? 'Valid phone required' : null,
              ),
              const SizedBox(height: 16),

              // Alt phone
              TextFormField(
                controller: _altPhoneController,
                decoration: const InputDecoration(
                    labelText: 'Alternate Phone', prefixText: '+91 '),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Area selector
              DropdownButtonFormField<String>(
                initialValue: _area,
                decoration: const InputDecoration(labelText: 'Area'),
                items: GSArea.all
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setState(() => _area = v ?? GSArea.talaja),
              ),
              const SizedBox(height: 16),

              // Village (conditional)
              if (_area == GSArea.village)
                TextFormField(
                  controller: _villageController,
                  decoration: const InputDecoration(labelText: 'Village Name'),
                  textInputAction: TextInputAction.next,
                ),
              if (_area == GSArea.village) const SizedBox(height: 16),

              // Property type
              DropdownButtonFormField<String>(
                initialValue: _propertyType,
                decoration: const InputDecoration(labelText: 'Property Type'),
                items: GSPropertyType.all
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _propertyType = v ?? GSPropertyType.residential),
              ),
              const SizedBox(height: 16),

              // Monthly bill
              TextFormField(
                controller: _billController,
                decoration: const InputDecoration(
                    labelText: 'Monthly Electricity Bill (₹)',
                    prefixIcon: Icon(Icons.payments, size: 20)),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Preferred package
              DropdownButtonFormField<String>(
                initialValue: _preferredPackage,
                decoration: InputDecoration(
                    labelText: 'Preferred Package',
                    hintText: 'kW rating',
                    hintStyle: GSTextStyles.bodySmall
                        .copyWith(color: GSColors.ink.withValues(alpha: 0.5))),
                items: [
                  const DropdownMenuItem(
                      value: 'not-sure', child: Text('Not sure yet')),
                  ...gsPackages.map((p) => DropdownMenuItem(
                      value: p.kw.toString(),
                      child: Text('${p.kw} kW (${p.panels} panels)'))),
                ],
                onChanged: (v) =>
                    setState(() => _preferredPackage = v ?? '3.08'),
              ),
              const SizedBox(height: 16),

              // Lead source
              DropdownButtonFormField<String>(
                initialValue: _source,
                decoration: const InputDecoration(labelText: 'How did they find you?'),
                items: GSSource.all
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _source = v ?? GSSource.website),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    alignLabelWithHint: true),
                maxLines: 4,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              // Save button
              GsButton(
                text: isEdit ? 'Update Client' : 'Save Client',
                onPressed: _loading ? null : _save,
                isLoading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
