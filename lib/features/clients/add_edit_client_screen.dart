import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client.dart';
import '../../providers/data_hub.dart';

/// Add / Edit client form — exact Stitch design match.
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
  String _preferredPackage = gsQuoteSystems.first.id;
  String _source = GSSource.website;

  static const _muted = Color(0xFF627193);
  static const _ink = Color(0xFF0F1B3D);
  static const _sky = Color(0xFFEAF4FF);
  static const _blue = Color(0xFF1E5BD8);
  static const _gold = Color(0xFFF9B417);
  static const _goldLight = Color(0xFFFFD86B);
  static const _goldDark = Color(0xFFD9980B);
  static const _navyDark = Color(0xFF071440);

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
      final p = c.preferredPackage;
      _preferredPackage = (p == 'not-sure' || gsQuoteSystemById(p) == null)
          ? gsQuoteSystems.first.id
          : p;
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
      backgroundColor: _sky,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── 1. NAVY HEADER ────────────────────────────────────
            _buildHeader(context),
            // ── 2. FORM BODY ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  children: [
                    // White rounded card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1A0B1F5C), blurRadius: 32, offset: Offset(0, 12)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Section header ──────────────────────
                          Container(
                            padding: const EdgeInsets.only(bottom: 10),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFEAF4FF))),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _sky,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.person_add_rounded,
                                      size: 16, color: _blue),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Client Particulars',
                                      style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _ink)),
                                ),
                                const Text('Step 1 of 1',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: _muted)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 1. Full Name
                          _label('Full Name', required: true),
                          const SizedBox(height: 6),
                          _input(
                            controller: _nameController,
                            icon: Icons.person_rounded,
                            hint: "Enter client's full name",
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 16),

                          // 2. Phone Number
                          _label('Phone Number', required: true),
                          const SizedBox(height: 6),
                          _input(
                            controller: _phoneController,
                            icon: Icons.call_rounded,
                            prefix: '+91',
                            hint: '10-digit mobile number',
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v == null || v.trim().length < 10 ? 'Valid phone required' : null,
                          ),
                          const SizedBox(height: 16),

                          // 3. Alternate Phone (optional)
                          Row(
                            children: [
                              _label('Alternate Phone'),
                              const Spacer(),
                              _optionalTag(),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _input(
                            controller: _altPhoneController,
                            icon: Icons.phone_iphone_rounded,
                            iconMuted: true,
                            prefix: '+91',
                            hint: 'Secondary contact number',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          // 4. Operational Area chips
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: _blue),
                              const SizedBox(width: 4),
                              _label('Operational Area', required: true),
                              const Spacer(),
                              const Text('Select Region',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _blue)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Chip wrapper (sky container)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _sky.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _sky),
                            ),
                            child: Row(
                              children: GSArea.all.map((a) {
                                final active = a == _area;
                                return Expanded(
                                  child: _areaChip(label: a, active: active, onTap: () {
                                    setState(() => _area = a);
                                  }),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 5. Village Name (when area = village)
                          if (_area == GSArea.village) ...[
                            _villageCard(),
                            const SizedBox(height: 16),
                          ],

                          // 6. Property Type chips
                          Row(
                            children: [
                              const Icon(Icons.domain_rounded, size: 14, color: _blue),
                              const SizedBox(width: 4),
                              _label('Property Type', required: true),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: GSPropertyType.all.map((p) {
                              final active = p == _propertyType;
                              final icon = p == GSPropertyType.residential
                                  ? Icons.cottage_rounded
                                  : Icons.corporate_fare_rounded;
                              return Expanded(
                                child: _propertyChip(
                                    label: p, icon: icon, active: active, onTap: () {
                                  setState(() => _propertyType = p);
                                }),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // 7. Monthly Electricity Bill
                          Row(
                            children: [
                              _label('Monthly Electricity Bill (₹)', required: true),
                              const Spacer(),
                              const Icon(Icons.energy_savings_leaf_rounded,
                                  size: 12, color: Color(0xFF1E8E3E)),
                              const SizedBox(width: 2),
                              const Text('PGVCL Tariff',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E8E3E))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _input(
                            controller: _billController,
                            icon: Icons.payments_rounded,
                            prefix: '₹',
                            hint: 'e.g. 3000',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final val = double.tryParse(v);
                              if (val == null || val <= 0) return 'Enter a valid amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                const Text('Recommended for 3-4 BHK',
                                    style: TextStyle(fontSize: 10, color: _muted)),
                                const Spacer(),
                                const Text('Eligible for ₹78,000 Subsidy',
                                    style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w500, color: _blue)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 8. Preferred Package dropdown
                          _label('Preferred Package', required: true),
                          const SizedBox(height: 6),
                          _dropdown(
                            icon: Icons.solar_power_rounded,
                            iconColor: _goldDark,
                            value: _preferredPackage,
                            items: [
                              const DropdownMenuItem(
                                  value: 'not-sure', child: Text('Not sure yet')),
                              ...gsQuoteSystems.map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                      '${p.kw.toStringAsFixed(2)} kW • ${p.panels} Panels — ${p.brandEn}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (v) => setState(
                                () => _preferredPackage =
                                    v ?? gsQuoteSystems.first.id),
                          ),
                          const SizedBox(height: 16),

                          // 9. Lead Source dropdown
                          _label('Lead Source'),
                          const SizedBox(height: 6),
                          _dropdown(
                            icon: Icons.groups_rounded,
                            iconColor: Color(0xFF1E8E3E),
                            value: _source,
                            items: GSSource.all
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _source = v ?? GSSource.website),
                          ),
                          const SizedBox(height: 16),

                          // 10. Notes (optional text area)
                          Row(
                            children: [
                              _label('Notes'),
                              const Spacer(),
                              _optionalTag(),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _notesInput(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── 3. BOTTOM FLOATING SAVE BAR ──────────────────────
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071440), Color(0xFF0B1E58), Color(0xFF0B1F5C)],
        ),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Ambient sun glow
            Positioned(
              right: 24,
              top: -40,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GSColors.gold500.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                        color: GSColors.gold500.withValues(alpha: 0.15),
                        blurRadius: 60),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Column(
                children: [
                  // Nav row
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4)],
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isEdit ? 'Edit Client' : 'Add Client',
                                style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3)),
                            const SizedBox(width: 6),
                            const _PulseDot(),
                          ],
                        ),
                      ),
                      // Help button (symmetry)
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {},
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: const Icon(Icons.help_outline_rounded,
                              size: 20, color: Color(0x80FFFFFF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Quick badge strip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        const Row(
                          children: [
                            _StatusDot(color: Color(0xFF4CC46A)),
                            SizedBox(width: 6),
                            Text('New Lead Intake',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xB3FFFFFF))),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: GSColors.gold500.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: GSColors.gold500.withValues(alpha: 0.3)),
                          ),
                          child: const Text('PM Surya Ghar 2.0',
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _goldLight)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom save bar ────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: const Border(top: BorderSide(color: Color(0xFFEAF4FF))),
        boxShadow: const [BoxShadow(color: Color(0x10071440), blurRadius: 20, offset: Offset(0, -8))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _loading ? null : _save,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_gold, _goldLight, _goldDark]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _goldLight.withValues(alpha: 0.6)),
                  boxShadow: [BoxShadow(color: GSColors.gold500.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _navyDark))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 22, color: _navyDark),
                            SizedBox(width: 8),
                            Text('Save Client',
                                style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: _navyDark)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 128,
              height: 4,
              decoration: BoxDecoration(
                color: _navyDark.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Label ──────────────────────────────────────────────────────
  Widget _label(String text, {bool required = false}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
              text: text.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _muted)),
          if (required)
            const TextSpan(
                text: ' *', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 11)),
        ],
      ),
    );
  }

  // ── Optional pill tag (matches Stitch) ─────────────────────────
  Widget _optionalTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _sky,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text('Optional',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _muted)),
    );
  }

  // ── Input field (matches Stitch) ───────────────────────────────
  Widget _input({
    required TextEditingController controller,
    required IconData icon,
    String? prefix,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool iconMuted = false,
    Color? iconColor,
    Color? fillColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: _muted.withValues(alpha: 0.7)),
        prefixIcon: maxLines > 1
            ? Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 0, left: 14),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Icon(icon,
                      size: 20,
                      color: iconColor ?? (iconMuted ? _muted : _blue)),
                ),
              )
            : Icon(icon,
                size: 20,
                color: iconColor ?? (iconMuted ? _muted : _blue)),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        prefixText: prefix,
        prefixStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: 0.5),
        filled: true,
        fillColor: fillColor ?? _sky,
        contentPadding: EdgeInsets.symmetric(
            horizontal: 16, vertical: maxLines > 1 ? 12 : 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: fillColor == Colors.white
                  ? _blue.withValues(alpha: 0.3)
                  : Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _blue, width: 1.2),
        ),
      ),
    );
  }

  // ── Notes text area (matches Stitch, icon top-left) ────────────
  Widget _notesInput() {
    return Container(
      decoration: BoxDecoration(
        color: _sky,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.transparent),
      ),
      child: Stack(
        children: [
          // Icon pinned to the top-left of the box
          const Positioned(
            left: 14,
            top: 14,
            child: Icon(Icons.edit_note_rounded, size: 20, color: _muted),
          ),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            minLines: 4,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: _ink, height: 1.4),
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText:
                  'Any notes about this lead (e.g. shadow on east wall, elevated structure requested, 3-phase meter needed)...',
              hintStyle: TextStyle(
                  fontSize: 14, color: _muted.withValues(alpha: 0.7), height: 1.4),
              contentPadding: const EdgeInsets.fromLTRB(44, 14, 16, 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dropdown (matches Stitch) ──────────────────────────────────
  Widget _dropdown({
    required IconData icon,
    required Color iconColor,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: iconColor),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        filled: true,
        fillColor: _sky,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _blue, width: 1.2),
        ),
      ),
      icon: const Icon(Icons.expand_more_rounded, color: _muted, size: 20),
      items: items,
      onChanged: onChanged,
    );
  }

  // ── Area chip (inside sky wrapper) ─────────────────────────────
  Widget _areaChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [_gold, _goldLight])
              : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? _goldLight.withValues(alpha: 0.4) : _sky),
          boxShadow: active
              ? [BoxShadow(color: GSColors.gold500.withValues(alpha: 0.35), blurRadius: 10)]
              : const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (active) ...[
              const Icon(Icons.check_circle_rounded, size: 15, color: _navyDark),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? _navyDark : _ink)),
          ],
        ),
      ),
    );
  }

  // ── Property chip ──────────────────────────────────────────────
  Widget _propertyChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [_gold, _goldLight])
                : null,
            color: active ? null : _sky,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: active ? _goldLight.withValues(alpha: 0.4) : Colors.transparent),
            boxShadow: active
                ? [BoxShadow(color: GSColors.gold500.withValues(alpha: 0.35), blurRadius: 10)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: active ? _navyDark : _muted),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active ? _navyDark : _ink)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Village card ───────────────────────────────────────────────
  Widget _villageCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F8FF), Color(0xFFE4F0FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.holiday_village_rounded, size: 15, color: _blue),
              const SizedBox(width: 4),
              Text('VILLAGE NAME *',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: _blue)),
              const Spacer(),
              const Text('Bhavnagar District',
                  style: TextStyle(fontSize: 10, color: Color(0xCC1E5BD8))),
            ],
          ),
          const SizedBox(height: 8),
          _input(
            controller: _villageController,
            icon: Icons.pin_drop_rounded,
            hint: 'Enter village name (e.g. Trapaj, Alang)',
            fillColor: Colors.white,
            iconColor: _blue,
          ),
        ],
      ),
    );
  }
}

/// Pulsing gold dot for the header title.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1400), vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF9B417),
          boxShadow: const [BoxShadow(color: Color(0xFFF9B417), blurRadius: 8)],
        ),
      ),
    );
  }
}

/// Small status dot.
class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}