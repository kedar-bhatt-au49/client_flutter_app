/// ---------------------------------------------------------------------------
/// Price Calculator — Step 2a sub-flow.
///
/// Opens as a full-screen route from the Create Estimate wizard.
/// Collects panel, inverter, structure, and financial selections, then
/// computes a price breakdown and returns a [PriceCalculationResult] to the
/// caller via Navigator.pop.
///
/// Master data (panels, inverters, pipe sizes, BOS items, GST profiles) is
/// loaded from `assets/data/estimate_master.json` — fully data-driven.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/estimate_widgets.dart';
import '../../core/widgets/searchable_selector_sheet.dart';
import '../../models/estimate.dart';

class PriceCalculatorScreen extends StatefulWidget {
  final MasterData master;
  final PriceCalcState initialState;

  const PriceCalculatorScreen({
    super.key,
    required this.master,
    required this.initialState,
  });

  @override
  State<PriceCalculatorScreen> createState() => _PriceCalculatorScreenState();
}

class _PriceCalculatorScreenState extends State<PriceCalculatorScreen> {
  late PriceCalcState _state;
  final _discountCtrl = TextEditingController();
  final _insPercentCtrl = TextEditingController();
  final _insAmountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _discountCtrl.text =
        _state.discountPerKw > 0 ? _state.discountPerKw.toStringAsFixed(0) : '';
    _insPercentCtrl.text = _state.insurancePercent > 0
        ? _state.insurancePercent.toStringAsFixed(1)
        : '';
    _insAmountCtrl.text =
        _state.insuranceAmount > 0 ? _state.insuranceAmount.toString() : '';
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _insPercentCtrl.dispose();
    _insAmountCtrl.dispose();
    super.dispose();
  }

  void _setPanel(String? id) {
    setState(() {
      _state.panelId = id;
      if (id != null) {
        final p = widget.master.panelById(id)!;
        _state.wattage = p.wattages.first;
      } else {
        _state.wattage = null;
        _state.moduleCount = null;
      }
    });
  }

  void _setWattage(int? w) => setState(() => _state.wattage = w);
  void _setModuleCount(int? c) => setState(() => _state.moduleCount = c);

  void _setInverter(String? id) {
    setState(() {
      _state.inverterId = id;
      if (id != null) {
        _state.inverterKw =
            widget.master.inverterById(id)!.compatibleRatings.first;
      } else {
        _state.inverterKw = null;
      }
    });
  }

  void _setInverterKw(double? kw) => setState(() => _state.inverterKw = kw);

  void _setStructureQty(String label, int val) =>
      setState(() => _state.structureQuantities[label] = val);

  void _setGst(String? label) => setState(() => _state.gstProfileLabel = label ?? '');

  void _toggleInsurance(bool v) =>
      setState(() => _state.insuranceIncluded = v);

  void _setInsuranceType(String t) =>
      setState(() => _state.insuranceType = t);

  void _calculate() {
    final engine = PriceEngine(widget.master);

    if (_state.panelId == null ||
        _state.wattage == null ||
        _state.moduleCount == null ||
        _state.inverterId == null ||
        _state.inverterKw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select panel, wattage, modules and inverter first')),
      );
      return;
    }

    // Validate discount cap
    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;
    if (discount > widget.master.discountCapPerKw) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Max discount is \u20B9${widget.master.discountCapPerKw}/kW'),
        ),
      );
      return;
    }

    _state
      ..discountPerKw = discount
      ..gstProfileLabel = _state.gstProfileLabel.isEmpty
          ? (widget.master.gstProfiles.isNotEmpty
              ? widget.master.gstProfiles.last.label
              : '')
          : _state.gstProfileLabel;

    final result = engine.calculate(_state);
    Navigator.of(context).pop(result);
  }

  void _reset() {
    setState(() {
      _state = PriceCalcState(
        gstProfileLabel: widget.master.gstProfiles.isNotEmpty
            ? widget.master.gstProfiles.last.label
            : '',
      );
      _discountCtrl.clear();
      _insPercentCtrl.clear();
      _insAmountCtrl.clear();
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────

  PanelMaster? get _panel =>
      _state.panelId != null ? widget.master.panelById(_state.panelId!) : null;
  InverterMaster? get _inverter => _state.inverterId != null
      ? widget.master.inverterById(_state.inverterId!)
      : null;

  double get _systemSize => (_state.wattage ?? 0) * (_state.moduleCount ?? 0) / 1000;

  Widget _fieldCard({
    required String label,
    required bool required,
    required Widget input,
    String? helperText,
  }) {
    return GsInputCard(
      label: label,
      required: required,
      input: input,
      helperText: helperText,
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final panel = _panel;
    final inverter = _inverter;
    final wattageOpts = panel?.wattages ?? [];
    final moduleMin = widget.master.moduleCountRange.first;
    final moduleMax = widget.master.moduleCountRange.last;
    final moduleOpts = List.generate(
        (moduleMax - moduleMin + 1).clamp(1, 20), (i) => moduleMin + i);
    final invKwOpts = inverter?.compatibleRatings ?? [];

    return Scaffold(
      backgroundColor: GSColors.pageBg,
      appBar: AppBar(
        backgroundColor: GSColors.navy900,
        foregroundColor: GSColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'PRICE CALCULATOR',
          style: GSTextStyles.headlineMedium.copyWith(color: GSColors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            // Progress bar
            const EstimateProgressBar(stepCount: 4, currentStep: 0),

            // ── Solar Panel Details ──
            const EstimateSectionHeader(
              icon: Icons.solar_power,
              title: 'Solar Panel Details',
            ),
            // Panel Name (searchable)
            _fieldCard(
              label: 'Panel Name',
              required: true,
              input: _buildSelectorTile(
                value: panel?.name ?? 'Select Panel',
                valueColor: panel == null
                    ? GSColors.ink.withValues(alpha: 0.4)
                    : GSColors.navy900,
                onTap: () => SearchableSelectorSheet.show<String>(
                  context: context,
                  title: 'Panel',
                  hint: 'Search panels...',
                  items: widget.master.panels.map((p) => p.id).toList(),
                  labelBuilder: (id) => widget.master.panelById(id)!.name,
                  sublabelBuilder: (id) {
                    final p = widget.master.panelById(id)!;
                    return '${p.brand} \u2032 ${p.warranties.join(', ')} \u2032 ${p.wattages.join(', ')}Wp';
                  },
                  initialValue: _state.panelId,
                  onSelected: _setPanel,
                ),
              ),
            ),
            // Wattage (dropdown, disabled until panel)
            _fieldCard(
              label: 'Wattage',
              required: true,
              input: _buildDropdown<int>(
                value: _state.wattage,
                items: wattageOpts,
                itemLabel: (w) => '$w Wp',
                onChanged: _setWattage,
                enabled: panel != null,
                disabledHint: 'Select Panel first',
              ),
            ),
            // No. of Modules (searchable number-picker)
            _fieldCard(
              label: 'No. of Modules',
              required: true,
              input: _buildSelectorTile(
                value: _state.moduleCount != null
                     ? '${_state.moduleCount} Modules'
                    : 'Select Panel first',
                valueColor:
                    panel == null || _state.moduleCount == null
                        ? GSColors.ink.withValues(alpha: 0.4)
                        : GSColors.navy900,
                enabled: panel != null,
                onTap: panel == null
                    ? null
                    : () => SearchableSelectorSheet.show<int>(
                        context: context,
                        title: 'Modules',
                        hint: 'Search modules...',
                        items: moduleOpts,
                        labelBuilder: (n) => '$n Modules',
                        initialValue: _state.moduleCount,
                        onSelected: _setModuleCount,
                      ),
              ),
            ),
            // System Size (read-only)
            _fieldCard(
              label: 'System Size (KW)',
              required: false,
              input: _buildReadOnlyField(
                value: _state.wattage != null && _state.moduleCount != null
                    ? '${_systemSize.toStringAsFixed(2)} kW'
                    : '—',
                placeholder: 'Auto-calculated',
              ),
            ),

            // ── Inverter Details ──
            const EstimateSectionHeader(
              icon: Icons.bolt,
              title: 'Inverter Details',
            ),
            _fieldCard(
              label: 'Inverter Name',
              required: true,
              input: _buildSelectorTile(
                value: inverter?.name ?? 'Select Inverter',
                valueColor: inverter == null
                    ? GSColors.ink.withValues(alpha: 0.4)
                    : GSColors.navy900,
                onTap: () => SearchableSelectorSheet.show<String>(
                  context: context,
                  title: 'Inverter',
                  hint: 'Search inverters...',
                  items: widget.master.inverters.map((i) => i.id).toList(),
                  labelBuilder: (id) => widget.master.inverterById(id)!.name,
                  sublabelBuilder: (id) {
                    final inv = widget.master.inverterById(id)!;
                    return '${inv.brand} \u2032 Ratings: ${inv.compatibleRatings.join(', ')}';
                  },
                  initialValue: _state.inverterId,
                  onSelected: _setInverter,
                ),
              ),
            ),
            _fieldCard(
              label: 'Inverter KW',
              required: true,
              input: _buildDropdown<double>(
                value: _state.inverterKw,
                items: invKwOpts,
                itemLabel: (kw) => '$kw kW',
                onChanged: _setInverterKw,
                enabled: inverter != null,
                disabledHint: 'Select Inverter first',
              ),
            ),

            // ── Structure Details ──
            const EstimateSectionHeader(
              icon: Icons.build,
              title: 'Structure Details',
            ),
            ...widget.master.structurePipes.map((pipe) {
              final ctrl = TextEditingController(
                  text: (_state.structureQuantities[pipe.label] ?? 0) > 0
                      ? _state.structureQuantities[pipe.label].toString()
                      : '');
              return _fieldCard(
                label: pipe.label,
                required: false,
                input: _buildNumberFieldWithSuffix(
                  controller: ctrl,
                  hint: '0',
                  suffix: 'm',
                  onChanged: (v) => _setStructureQty(
                      pipe.label, int.tryParse(v) ?? 0),
                ),
              );
            }),

            // ── Financial Details ──
            const EstimateSectionHeader(
              icon: Icons.currency_rupee,
              title: 'Financial Details',
            ),
            _fieldCard(
              label: 'Discount per KW',
              required: false,
              input: _buildCurrencyField(
                controller: _discountCtrl,
                hint: '0',
                currencySymbol: '\u20B9',
                suffix: '/kW',
              ),
              helperText:
                  'Max: \u20B9${widget.master.discountCapPerKw.toInt()}/kW',
            ),
            _fieldCard(
              label: 'Tax (GSTIN)',
              required: true,
              input: _buildDropdown<String>(
                value: _state.gstProfileLabel.isEmpty
                    ? null
                    : _state.gstProfileLabel,
                items: widget.master.gstProfiles.map((g) => g.label).toList(),
                itemLabel: (l) => l,
                onChanged: _setGst,
                enabled: true,
              ),
            ),
            _insuranceCard(),

            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: GSColors.white,
          boxShadow: [
            BoxShadow(
              color: GSColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Reset (outline)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon:
                      const Icon(Icons.refresh, size: 18, color: GSColors.navy500),
                  label: Text('Reset',
                      style: GSTextStyles.labelLarge
                          .copyWith(color: GSColors.navy500)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: GSColors.ink.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Calculate Price (navy filled)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate, size: 18),
                  label: Text('Calculate Price',
                      style: GSTextStyles.labelLarge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GSColors.navy500,
                    foregroundColor: GSColors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Field builders ───────────────────────────────────────────────

  Widget _buildSelectorTile({
    required String value,
    required Color valueColor,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: GSTextStyles.bodyMedium.copyWith(
                color: valueColor,
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: GSColors.ink.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    required bool enabled,
    String? disabledHint,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        disabledColor: GSColors.ink.withValues(alpha: 0.3),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(itemLabel(e),
                      style: GSTextStyles.bodyMedium),
                ))
            .toList(),
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: enabled
              ? 'Select'
              : (disabledHint ?? 'Select first'),
          hintStyle: GSTextStyles.bodyMedium
              .copyWith(color: GSColors.ink.withValues(alpha: 0.4)),
        ),
        style: GSTextStyles.bodyMedium.copyWith(
          color: enabled
              ? GSColors.navy900
              : GSColors.ink.withValues(alpha: 0.4),
        ),
        icon: Icon(Icons.chevron_right,
            size: 20, color: GSColors.ink.withValues(alpha: 0.3)),
        iconDisabledColor: GSColors.ink.withValues(alpha: 0.2),
        iconEnabledColor: GSColors.ink.withValues(alpha: 0.4),
        disabledHint: Text(
          disabledHint ?? '',
          style: GSTextStyles.bodyMedium
              .copyWith(color: GSColors.ink.withValues(alpha: 0.4)),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required String placeholder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        value,
        style: GSTextStyles.bodyMedium.copyWith(
          color: value == placeholder || value == '—'
              ? GSColors.ink.withValues(alpha: 0.4)
              : GSColors.navy900,
          fontWeight:
              value != placeholder && value != '—' ? FontWeight.w600 : null,
        ),
      ),
    );
  }

  Widget _buildNumberFieldWithSuffix({
    required TextEditingController controller,
    required String hint,
    required String suffix,
    required void Function(String) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GSTextStyles.bodyMedium
                  .copyWith(color: GSColors.ink.withValues(alpha: 0.4)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged,
          ),
        ),
        Text(suffix,
            style: GSTextStyles.bodyMedium
                .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String hint,
    required String currencySymbol,
    required String suffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GSTextStyles.bodyMedium.copyWith(color: GSColors.ink.withValues(alpha: 0.4)),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        prefixText: '$currencySymbol ',
        prefixStyle: GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900),
        suffixText: suffix,
        suffixStyle:
            GSTextStyles.bodyMedium.copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
      ),
      style: GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  // ── Insurance card ───────────────────────────────────────────────

  Widget _buildInlineLabel(String label, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(label.toUpperCase(),
                style: GSTextStyles.labelMedium
                    .copyWith(color: GSColors.navy900)),
            if (required)
              Text(' *',
                  style: GSTextStyles.labelMedium.copyWith(color: GSColors.errorRed)),
          ],
        ),
      );

  Widget _insuranceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: GSColors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: GSColors.ink.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
              color: GSColors.shadowLight, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle row
          InkWell(
            onTap: () => _toggleInsurance(!_state.insuranceIncluded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Insurance',
                          style: GSTextStyles.labelMedium
                              .copyWith(color: GSColors.navy900)),
                      Text('Click to include insurance',
                          style: GSTextStyles.bodySmall
                              .copyWith(color: GSColors.ink.withValues(alpha: 0.5))),
                    ],
                  ),
                  Switch(
                    value: _state.insuranceIncluded,
                    onChanged: _toggleInsurance,
                    activeColor: GSColors.teal500,
                    activeTrackColor:
                        GSColors.teal500.withValues(alpha: 0.4),
                    inactiveThumbColor: GSColors.ink.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
          // Expanded section
          if (_state.insuranceIncluded) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildInlineLabel('Insurance Mode'),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Percent
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInlineLabel('Percent'),
                        TextFormField(
                          controller: _insPercentCtrl,
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: GSTextStyles.bodyMedium.copyWith(
                                color: GSColors.ink.withValues(alpha: 0.4)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            suffixText: '%',
                            suffixStyle: GSTextStyles.bodyMedium.copyWith(
                                color: GSColors.ink.withValues(alpha: 0.6)),
                          ),
                          style: GSTextStyles.bodyMedium
                              .copyWith(color: GSColors.navy900),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) {
                            setState(() {
                              _state.insuranceType = 'percent';
                              _state.insurancePercent = double.tryParse(v) ?? 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Or Amount
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInlineLabel('Or Amount'),
                        TextFormField(
                          controller: _insAmountCtrl,
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: GSTextStyles.bodyMedium.copyWith(
                                color: GSColors.ink.withValues(alpha: 0.4)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            prefixText: '\u20B9 ',
                            prefixStyle: GSTextStyles.bodyMedium
                                .copyWith(color: GSColors.navy900),
                          ),
                          style: GSTextStyles.bodyMedium
                              .copyWith(color: GSColors.navy900),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) {
                            setState(() {
                              _state.insuranceType = 'amount';
                              _state.insuranceAmount = int.tryParse(v) ?? 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Mode selector (radio)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GsRadioGroup(
                groupValue: _state.insuranceType,
                onChanged: (v) =>
                    setState(() => _state.insuranceType = v ?? 'percent'),
                options: [
                  RadioOption(label: '%', value: 'percent'),
                  RadioOption(label: 'Amount', value: 'amount'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
