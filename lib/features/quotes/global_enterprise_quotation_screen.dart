import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/gs_button.dart';
import '../../core/widgets/solar_grid_divider.dart';
import '../../models/quotation_model.dart';
import 'global_enterprise_quotation.dart';

/// Screen that previews and lets the user edit the Global Enterprise
/// quotation before generating or sharing it.
class GlobalEnterpriseQuotationScreen extends StatefulWidget {
  final QuotationData? initialData;

  const GlobalEnterpriseQuotationScreen({super.key, this.initialData});

  @override
  State<GlobalEnterpriseQuotationScreen> createState() =>
      _GlobalEnterpriseQuotationScreenState();
}

class _GlobalEnterpriseQuotationScreenState
    extends State<GlobalEnterpriseQuotationScreen> {
  late QuotationData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ??
        QuotationData(
          date: DateTime.now(),
          consumerName: 'RAJDEPSINH',
          contactNumber: '9824963973',
          address: 'KATHAVA',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      appBar: AppBar(
        title: const Text('Quotation Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefaults,
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Editable fields (only customer info is editable here) ──
            _buildEditor(),
            const SolarGridDivider(height: 1, margin: EdgeInsets.symmetric(vertical: 16)),
            // ── Quotation preview ──
            GlobalEnterpriseQuotation(data: _data),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GsButton(
            text: 'Save & Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quotation saved')),
              );
            },
            fullWidth: true,
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Card(
      color: GSColors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Details',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: GSColors.navy900, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Consumer Name',
              _data.consumerName,
              (v) => _update((d) => d.copyWith(consumerName: v)),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Contact Number',
              _data.contactNumber,
              (v) => _update((d) => d.copyWith(contactNumber: v)),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Address',
              _data.address,
              (v) => _update((d) => d.copyWith(address: v)),
            ),
            const SizedBox(height: 12),
            Text(
              'Date: ${DateFormat('dd-MM-yyyy').format(_data.date)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    void Function(String) onChanged,
  ) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: GSColors.white,
      ),
      onChanged: onChanged,
    );
  }

  void _update(QuotationData Function(QuotationData) fn) {
    setState(() => _data = fn(_data.copyWith()));
  }

  void _resetToDefaults() {
    setState(() {
      _data = QuotationData(
        date: DateTime.now(),
        consumerName: 'RAJDEPSINH',
        contactNumber: '9824963973',
        address: 'KATHAVA',
      );
    });
  }
}
