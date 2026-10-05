/// ---------------------------------------------------------------------------
/// Global Solar 2.0 â€” Create Estimate Wizard Data Model
///
/// Holds all wizard state across the 4 steps + the Price Calculator sub-flow.
/// Master data (panels, inverters, structure pipes, currencies, GST profiles)
/// is loaded from `assets/data/estimate_master.json` so SKUs can be added
/// without code changes.
/// ---------------------------------------------------------------------------
library;

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

// â”€â”€ Master data value objects â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class CurrencyOpt {
  final String code;
  final String name;
  final String symbol;

  CurrencyOpt({required this.code, required this.name, required this.symbol});

  factory CurrencyOpt.fromJson(Map<String, dynamic> j) => CurrencyOpt(
        code: j['code'] as String,
        name: j['name'] as String,
        symbol: j['symbol'] as String,
      );
}

class LeadStageOpt {
  final String id;
  final String label;
  final String dotColorHex;

  LeadStageOpt(
      {required this.id, required this.label, required this.dotColorHex});

  factory LeadStageOpt.fromJson(Map<String, dynamic> j) => LeadStageOpt(
        id: j['id'] as String,
        label: j['label'] as String,
        dotColorHex: j['dot_color'] as String,
      );
}

class PanelMaster {
  final String id;
  final String name;
  final String brand;
  final List<String> warranties;
  final List<int> wattages;
  final Map<String, int> wattageRates; // wattage -> rate per watt-peak (â‚¹)

  PanelMaster({
    required this.id,
    required this.name,
    required this.brand,
    required this.warranties,
    required this.wattages,
    required this.wattageRates,
  });

  int rateForWattage(int w) => wattageRates[w.toString()] ?? 0;

  factory PanelMaster.fromJson(Map<String, dynamic> j) => PanelMaster(
        id: j['id'] as String,
        name: j['name'] as String,
        brand: j['brand'] as String,
        warranties: List<String>.from(j['warranties'] as List),
        wattages: List<int>.from(j['wattages'] as List),
        wattageRates: Map<String, int>.from(
            (j['wattage_rates'] as Map).map((k, v) => MapEntry(k, v as int))),
      );
}

class InverterMaster {
  final String id;
  final String name;
  final String brand;
  final List<double> compatibleRatings;
  final Map<String, int> ratingPrices; // rating -> price (â‚¹)

  InverterMaster({
    required this.id,
    required this.name,
    required this.brand,
    required this.compatibleRatings,
    required this.ratingPrices,
  });

  int priceForRating(double r) => ratingPrices[r.toStringAsFixed(1)] ?? 0;

  factory InverterMaster.fromJson(Map<String, dynamic> j) => InverterMaster(
        id: j['id'] as String,
        name: j['name'] as String,
        brand: j['brand'] as String,
        compatibleRatings:
            List<double>.from((j['compatible_ratings'] as List).map((e) => (e as num).toDouble())),
        ratingPrices: Map<String, int>.from((j['rating_prices'] as Map)
            .map((k, v) => MapEntry(k, v as int))),
      );
}

class StructurePipe {
  final String label;
  final String description;
  final int ratePerMeter;

  StructurePipe(
      {required this.label, required this.description, required this.ratePerMeter});

  factory StructurePipe.fromJson(Map<String, dynamic> j) => StructurePipe(
        label: j['label'] as String,
        description: j['description'] as String,
        ratePerMeter: j['rate_per_meter'] as int,
      );
}

class BosItem {
  final String name;
  final int qty;
  final String unit;
  final int rate;

  BosItem(
      {required this.name,
      required this.qty,
      required this.unit,
      required this.rate});

  factory BosItem.fromJson(Map<String, dynamic> j) => BosItem(
        name: j['name'] as String,
        qty: (j['qty'] as num?)?.toInt() ??
            int.tryParse((j['qty'] as String?)?.trim() ?? '') ??
            0,
        unit: j['unit'] as String,
        rate: (j['rate'] as num?)?.toInt() ?? 0,
      );

  int get total => qty * rate;
}

class GstProfile {
  final String label;
  final double cgst;
  final double sgst;

  GstProfile({required this.label, required this.cgst, required this.sgst});

  double get totalPercent => cgst + sgst;

  factory GstProfile.fromJson(Map<String, dynamic> j) => GstProfile(
        label: j['label'] as String,
        cgst: (j['cgst'] as num).toDouble(),
        sgst: (j['sgst'] as num).toDouble(),
      );
}

// â”€â”€ Master data container â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class MasterData {
  final String estimateNumberPrefix;
  final String defaultCurrency;
  final String defaultLeadStage;
  final int expiryDays;
  final List<int> moduleCountRange;
  final int discountCapPerKw;
  final double insuranceCapPercent;
  final int insuranceMaxAmount;
  final List<CurrencyOpt> currencies;
  final List<LeadStageOpt> leadStages;
  final List<PanelMaster> panels;
  final List<InverterMaster> inverters;
  final List<StructurePipe> structurePipes;
  final List<BosItem> bosItems;
  final List<GstProfile> gstProfiles;
  final String defaultPanelId;
  final int defaultPanelWattage;
  final String defaultInverterId;
  final double defaultInverterKw;

  MasterData({
    required this.estimateNumberPrefix,
    required this.defaultCurrency,
    required this.defaultLeadStage,
    required this.expiryDays,
    required this.moduleCountRange,
    required this.discountCapPerKw,
    required this.insuranceCapPercent,
    required this.insuranceMaxAmount,
    required this.currencies,
    required this.leadStages,
    required this.panels,
    required this.inverters,
    required this.structurePipes,
    required this.bosItems,
    required this.gstProfiles,
    required this.defaultPanelId,
    required this.defaultPanelWattage,
    required this.defaultInverterId,
    required this.defaultInverterKw,
  });

  factory MasterData.fromJson(Map<String, dynamic> j) => MasterData(
        estimateNumberPrefix: j['estimate_number_prefix'] as String? ?? 'EST',
        defaultCurrency: j['default_currency'] as String? ?? 'INR',
        defaultLeadStage: j['default_lead_stage'] as String? ?? 'new',
        expiryDays: j['expiry_days'] as int? ?? 7,
        moduleCountRange: List<int>.from(j['module_count_range'] as List),
        discountCapPerKw: j['discount_cap_per_kw'] as int? ?? 1500,
        insuranceCapPercent:
            (j['insurance_cap_percent'] as num?)?.toDouble() ?? 2.0,
        insuranceMaxAmount: j['insurance_max_amount'] as int? ?? 5000,
        currencies: (j['currencies'] as List)
            .map((e) => CurrencyOpt.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        leadStages: (j['lead_stages'] as List)
            .map((e) => LeadStageOpt.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        panels: (j['panels'] as List)
            .map((e) => PanelMaster.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        inverters: (j['inverters'] as List)
            .map((e) => InverterMaster.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        structurePipes: (j['structure_pipes'] as List)
            .map((e) => StructurePipe.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        bosItems: (j['bos_items'] as List)
            .map((e) => BosItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        gstProfiles: (j['gst_profiles'] as List)
            .map((e) => GstProfile.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        defaultPanelId: j['default_panel'] as String? ?? '',
        defaultPanelWattage: j['default_panel_wattage'] as int? ?? 610,
        defaultInverterId: j['default_inverter'] as String? ?? '',
        defaultInverterKw:
            (j['default_inverter_kw'] as num?)?.toDouble() ?? 3.6,
      );

  static Future<MasterData> load() async {
    final raw = await rootBundle.loadString('assets/data/estimate_master.json');
    return MasterData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  PanelMaster? panelById(String id) =>
      panels.firstWhere((p) => p.id == id, orElse: () => panels.first);

  InverterMaster? inverterById(String id) =>
      inverters.firstWhere((i) => i.id == id, orElse: () => inverters.first);

  CurrencyOpt currencyByCode(String code) =>
      currencies.firstWhere((c) => c.code == code, orElse: () => currencies.first);

  LeadStageOpt stageById(String id) =>
      leadStages.firstWhere((s) => s.id == id, orElse: () => leadStages.first);

  GstProfile profileByLabel(String label) =>
      gstProfiles.firstWhere((g) => g.label == label, orElse: () => gstProfiles.first);
}

// â”€â”€ Line item produced by the Price Calculator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class EstimateLineItem {
  final String description;
  final String specs;
  final int qty;
  final int rate;
  final int discount;
  final double cgstPercent;
  final double sgstPercent;
  final bool taxable;

  EstimateLineItem({
    required this.description,
    this.specs = '',
    required this.qty,
    required this.rate,
    this.discount = 0,
    this.cgstPercent = 0,
    this.sgstPercent = 0,
    this.taxable = true,
  });

  int get taxableAmount => (rate * qty) - discount;
  int get cgstAmount => (taxable ? (taxableAmount * cgstPercent) / 100 : 0).round();
  int get sgstAmount => (taxable ? (taxableAmount * sgstPercent) / 100 : 0).round();
  int get total => taxableAmount + cgstAmount + sgstAmount;

  EstimateLineItem copyWith({int? rate, int? qty, int? discount}) =>
      EstimateLineItem(
        description: description,
        specs: specs,
        qty: qty ?? this.qty,
        rate: rate ?? this.rate,
        discount: discount ?? this.discount,
        cgstPercent: cgstPercent,
        sgstPercent: sgstPercent,
        taxable: taxable,
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'specs': specs,
        'qty': qty,
        'rate': rate,
        'discount': discount,
        'cgst_percent': cgstPercent,
        'sgst_percent': sgstPercent,
        'taxable': taxable,
      };

  factory EstimateLineItem.fromJson(Map<String, dynamic> j) => EstimateLineItem(
        description: j['description'] as String,
        specs: j['specs'] as String? ?? '',
        qty: j['qty'] as int,
        rate: j['rate'] as int,
        discount: j['discount'] as int? ?? 0,
        cgstPercent: (j['cgst_percent'] as num?)?.toDouble() ?? 0,
        sgstPercent: (j['sgst_percent'] as num?)?.toDouble() ?? 0,
        taxable: j['taxable'] as bool? ?? true,
      );
}

// â”€â”€ Price breakdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class PriceBreakdown {
  final int panelCost;
  final int inverterCost;
  final int structureCost;
  final int bosCost;
  final int discountTotal;
  final int subtotal;
  final GstProfile gstProfile;
  final int cgstTotal;
  final int sgstTotal;
  final int taxTotal;
  final bool insuranceIncluded;
  final double? insurancePercent;
  final int? insuranceAmount;
  final int insuranceTotal;
  final int grandTotal;
  final double capacityKw;

  PriceBreakdown({
    required this.panelCost,
    required this.inverterCost,
    required this.structureCost,
    required this.bosCost,
    required this.discountTotal,
    required this.subtotal,
    required this.gstProfile,
    required this.cgstTotal,
    required this.sgstTotal,
    required this.taxTotal,
    required this.insuranceIncluded,
    this.insurancePercent,
    this.insuranceAmount,
    required this.insuranceTotal,
    required this.grandTotal,
    required this.capacityKw,
  });

  Map<String, dynamic> toJson() => {
        'panel_cost': panelCost,
        'inverter_cost': inverterCost,
        'structure_cost': structureCost,
        'bos_cost': bosCost,
        'discount_total': discountTotal,
        'subtotal': subtotal,
        'gst_cgst': cgstTotal,
        'gst_sgst': sgstTotal,
        'tax_total': taxTotal,
        'insurance_included': insuranceIncluded,
        'insurance_percent': insurancePercent,
        'insurance_amount': insuranceAmount,
        'insurance_total': insuranceTotal,
        'grand_total': grandTotal,
        'capacity_kw': capacityKw,
        'gst_profile': gstProfile.label,
      };

  factory PriceBreakdown.fromJson(
      Map<String, dynamic> j, MasterData master) {
    return PriceBreakdown(
      panelCost: j['panel_cost'] as int,
      inverterCost: j['inverter_cost'] as int,
      structureCost: j['structure_cost'] as int,
      bosCost: j['bos_cost'] as int,
      discountTotal: j['discount_total'] as int,
      subtotal: j['subtotal'] as int,
      gstProfile: master.profileByLabel(j['gst_profile'] as String),
      cgstTotal: j['gst_cgst'] as int,
      sgstTotal: j['gst_sgst'] as int,
      taxTotal: j['tax_total'] as int,
      insuranceIncluded: j['insurance_included'] as bool,
      insurancePercent: j['insurance_percent'] as double?,
      insuranceAmount: j['insurance_amount'] as int?,
      insuranceTotal: j['insurance_total'] as int,
      grandTotal: j['grand_total'] as int,
      capacityKw: (j['capacity_kw'] as num).toDouble(),
    );
  }
}

// â”€â”€ Price Calculator selection state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class PriceCalcState {
  String? panelId;
  int? wattage;
  int? moduleCount; // 2-9
  String? inverterId;
  double? inverterKw;
  final Map<String, int> structureQuantities; // pipe label -> meters
  double discountPerKw;
  String gstProfileLabel;
  bool insuranceIncluded;
  String insuranceType; // 'percent' | 'amount'
  double insurancePercent;
  int insuranceAmount;

  PriceCalcState({
    this.panelId,
    this.wattage,
    this.moduleCount,
    this.inverterId,
    this.inverterKw,
    Map<String, int>? structureQuantities,
    this.discountPerKw = 0,
    this.gstProfileLabel = '',
    this.insuranceIncluded = false,
    this.insuranceType = 'percent',
    this.insurancePercent = 0,
    this.insuranceAmount = 0,
  }) : structureQuantities =
            Map<String, int>.from(structureQuantities ?? {});

  PriceCalcState copyWith({
    String? panelId,
    int? wattage,
    int? moduleCount,
    String? inverterId,
    double? inverterKw,
    Map<String, int>? structureQuantities,
    double? discountPerKw,
    String? gstProfileLabel,
    bool? insuranceIncluded,
    String? insuranceType,
    double? insurancePercent,
    int? insuranceAmount,
  }) =>
      PriceCalcState(
        panelId: panelId ?? this.panelId,
        wattage: wattage ?? this.wattage,
        moduleCount: moduleCount ?? this.moduleCount,
        inverterId: inverterId ?? this.inverterId,
        inverterKw: inverterKw ?? this.inverterKw,
        structureQuantities:
            Map<String, int>.from(structureQuantities ?? this.structureQuantities),
        discountPerKw: discountPerKw ?? this.discountPerKw,
        gstProfileLabel: gstProfileLabel ?? this.gstProfileLabel,
        insuranceIncluded: insuranceIncluded ?? this.insuranceIncluded,
        insuranceType: insuranceType ?? this.insuranceType,
        insurancePercent: insurancePercent ?? this.insurancePercent,
        insuranceAmount: insuranceAmount ?? this.insuranceAmount,
      );
}

// â”€â”€ Result returned from the Price Calculator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class PriceCalculationResult {
  final double capacityKw;
  final List<EstimateLineItem> lineItems;
  final PriceBreakdown breakdown;
  final Map<String, int> structureQuantities;
  final double discountPerKw;
  final String gstProfileLabel;
  final bool insuranceIncluded;
  final String insuranceType;
  final double insurancePercent;
  final int insuranceAmount;
  final PriceCalcState stateUsed;

  PriceCalculationResult({
    required this.capacityKw,
    required this.lineItems,
    required this.breakdown,
    required this.structureQuantities,
    required this.discountPerKw,
    required this.gstProfileLabel,
    required this.insuranceIncluded,
    required this.insuranceType,
    required this.insurancePercent,
    required this.insuranceAmount,
    required this.stateUsed,
  });
}

// â”€â”€ Pricing engine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class PriceEngine {
  final MasterData master;

  PriceEngine(this.master);

  /// Compute capacity from the selection state.
  double capacityKw(String? panelId, int? wattage, int? moduleCount) {
    if (wattage == null || moduleCount == null) return 0;
    return (wattage * moduleCount) / 1000;
  }

  PriceCalculationResult calculate(PriceCalcState state) {
    final panel = state.panelId != null ? master.panelById(state.panelId!) : null;
    final inverter = state.inverterId != null
        ? master.inverterById(state.inverterId!)
        : null;

    // Panel cost
    final w = state.wattage ?? 0;
    final modules = state.moduleCount ?? 0;
    final panelRate = panel?.rateForWattage(w) ?? 0;
    final panelCost = w * modules * panelRate;

    // Inverter cost
    final invPrice = inverter?.priceForRating(state.inverterKw ?? 0) ?? 0;

    // Structure cost
    var structureCost = 0;
    for (final pipe in master.structurePipes) {
      final qty = state.structureQuantities[pipe.label] ?? 0;
      structureCost += qty * pipe.ratePerMeter;
    }

    // BOS cost
    final bosCost = master.bosItems.fold(0, (s, b) => s + b.total);

    final capacity = w * modules / 1000;

    final discountTotal = (state.discountPerKw * capacity).round();

    // Tax profile
    final gst = master.gstProfiles.isNotEmpty
        ? master.profileByLabel(state.gstProfileLabel.isEmpty
            ? master.gstProfiles.last.label
            : state.gstProfileLabel)
        : GstProfile(label: 'GST0 [0%]', cgst: 0, sgst: 0);

    final taxable = (panelCost + invPrice + structureCost + bosCost) - discountTotal;

    final cgstTotal = (taxable * gst.cgst / 100).round();
    final sgstTotal = (taxable * gst.sgst / 100).round();
    final taxTotal = cgstTotal + sgstTotal;

    // Insurance
    var insuranceTotal = 0;
    if (state.insuranceIncluded) {
      if (state.insuranceType == 'percent') {
        insuranceTotal = (taxable * state.insurancePercent / 100).round();
      } else {
        insuranceTotal = state.insuranceAmount;
      }
      // enforce cap
      final cap = (master.insuranceCapPercent * capacity).round();
      final capAmount =
          cap < master.insuranceMaxAmount ? cap : master.insuranceMaxAmount;
      if (insuranceTotal > capAmount) insuranceTotal = capAmount;
    }

    final grandTotal = taxable + taxTotal + insuranceTotal;

    // Build line items
    final items = <EstimateLineItem>[];

    if (panelCost > 0) {
      items.add(EstimateLineItem(
        description: 'Solar Panels',
        specs: panel != null
            ? '${panel!.brand} ${w}Wp (${panel.warranties.join(', ')})'
            : '',
        qty: modules,
        rate: (w * panelRate),
        cgstPercent: gst.cgst,
        sgstPercent: gst.sgst,
      ));
    }
    if (invPrice > 0) {
      items.add(EstimateLineItem(
        description: 'Inverter',
        specs: inverter != null
            ? '${inverter!.brand} @ ${state.inverterKw?.toStringAsFixed(1)}kW'
            : '',
        qty: 1,
        rate: invPrice,
        cgstPercent: gst.cgst,
        sgstPercent: gst.sgst,
      ));
    }
    if (structureCost > 0) {
      items.add(EstimateLineItem(
        description: 'Structure & Mounting',
        specs: 'Hot-dip galvanized MS structure',
        qty: state.structureQuantities.values.fold(0, (s, v) => s + v),
        rate: structureCost ~/
            (state.structureQuantities.values.fold(0, (s, v) => s + v) == 0
                ? 1
                : state.structureQuantities.values.fold(0, (s, v) => s + v)),
        cgstPercent: gst.cgst,
        sgstPercent: gst.sgst,
      ));
    }
    // BOS line items
    for (final b in master.bosItems) {
      items.add(EstimateLineItem(
        description: b.name,
        qty: b.qty,
        rate: b.rate,
        cgstPercent: gst.cgst,
        sgstPercent: gst.sgst,
      ));
    }
    items.add(EstimateLineItem(
      description: 'Discount (â‚¹/kW)',
      qty: 1,
      rate: -discountTotal,
      cgstPercent: 0,
      sgstPercent: 0,
      taxable: false,
    ));
    items.add(EstimateLineItem(
      description: 'Tax (GST ${gst.totalPercent.toStringAsFixed(1)}%)',
      qty: 1,
      rate: taxTotal,
      cgstPercent: 0,
      sgstPercent: 0,
      taxable: false,
    ));
    if (insuranceTotal > 0) {
      items.add(EstimateLineItem(
        description: 'Insurance',
        qty: 1,
        rate: insuranceTotal,
        cgstPercent: 0,
        sgstPercent: 0,
        taxable: false,
      ));
    }

    final breakdown = PriceBreakdown(
      panelCost: panelCost,
      inverterCost: invPrice,
      structureCost: structureCost,
      bosCost: bosCost,
      discountTotal: discountTotal,
      subtotal: panelCost + invPrice + structureCost + bosCost,
      gstProfile: gst,
      cgstTotal: cgstTotal,
      sgstTotal: sgstTotal,
      taxTotal: taxTotal,
      insuranceIncluded: state.insuranceIncluded,
      insurancePercent:
          state.insuranceType == 'percent' ? state.insurancePercent : null,
      insuranceAmount:
          state.insuranceType == 'amount' ? state.insuranceAmount : null,
      insuranceTotal: insuranceTotal,
      grandTotal: grandTotal,
      capacityKw: capacity,
    );

    return PriceCalculationResult(
      capacityKw: capacity,
      lineItems: items,
      breakdown: breakdown,
      structureQuantities: Map<String, int>.from(state.structureQuantities),
      discountPerKw: state.discountPerKw,
      gstProfileLabel: state.gstProfileLabel,
      insuranceIncluded: state.insuranceIncluded,
      insuranceType: state.insuranceType,
      insurancePercent: state.insurancePercent,
      insuranceAmount: state.insuranceAmount,
      stateUsed: state,
    );
  }
}

// â”€â”€ Main estimate model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class EstimateModel {
  // â”€â”€ Step 1: Lead Details â”€â”€
  String clientType; // 'individual' | 'business'
  String? companyName;
  String leadName;
  String mobileNumber; // digits only (10 digits)
  String? whatsappNumber;
  bool autoFillWhatsApp;
  String leadStage; // stage id, default 'new'
  String? description;
  String? email;
  String? address;

  // â”€â”€ Step 2: Estimate Details â”€â”€
  String estimateNumber;
  String? referenceNo;
  DateTime expiryDate;
  String currency; // currency code, default 'INR'
  double? capacityKw; // auto-filled from Price Calculator
  String? systemId; // selected system (gsQuoteSystems), drives pricing + panel image
  String? wiringSqMm; // manual wiring size (e.g. "4 sq.mm")
  double? inverterKwManual; // manual inverter kW capacity
  int? totalPayableOverride; // manual price override (GST-inclusive)
  bool gstIncluded; // show prices with GST (true) or without (false)
  String taxMode; // 'exclusive' | 'inclusive'
  List<EstimateLineItem> lineItems;

  // â”€â”€ Step 3: Structure Details â”€â”€
  final Map<String, int> structureQuantities; // pipe label -> meters

  // â”€â”€ Step 4: Financial Details â”€â”€
  double discountPerKw;
  String gstProfileLabel;
  bool insuranceIncluded;
  String insuranceType; // 'percent' | 'amount'
  double insurancePercent;
  int insuranceAmount;

  // â”€â”€ Computed â”€â”€
  PriceBreakdown? priceBreakdown;

  EstimateModel({
    this.clientType = 'individual',
    this.companyName,
    this.leadName = '',
    this.mobileNumber = '',
    this.whatsappNumber,
    this.autoFillWhatsApp = false,
    this.leadStage = 'new',
    this.description,
    this.email,
    this.address,
    this.estimateNumber = '',
    this.referenceNo,
    DateTime? expiryDate,
    this.currency = 'INR',
    this.capacityKw,
    this.systemId,
    this.wiringSqMm,
    this.inverterKwManual,
    this.totalPayableOverride,
    this.gstIncluded = true,
    this.taxMode = 'exclusive',
    List<EstimateLineItem>? lineItems,
    Map<String, int>? structureQuantities,
    this.discountPerKw = 0,
    this.gstProfileLabel = '',
    this.insuranceIncluded = false,
    this.insuranceType = 'percent',
    this.insurancePercent = 0,
    this.insuranceAmount = 0,
    this.priceBreakdown,
  })  : expiryDate = expiryDate ??
            DateTime.now().add(const Duration(days: 7)),
        lineItems = lineItems ?? [],
        structureQuantities =
            Map<String, int>.from(structureQuantities ?? {});

  /// Auto-generate a sequential estimate number like `EST-004`.
  static String generateNumber(String prefix, int index) {
    final num = (index + 1).toString().padLeft(3, '0');
    return '$prefix-$num';
  }

  String get currencySymbol =>
      _currencySymbol(currency);

  static String _currencySymbol(String code) {
    switch (code) {
      case 'INR':
        return '\u20B9';
      case 'USD':
        return '\$';
      case 'EUR':
        return '\u20AC';
      default:
        return '\u20B9';
    }
  }

  String get expiryDateFormatted =>
      DateFormat('dd MMM yyyy').format(expiryDate);

  /// Convert price-calculator results back into this estimate.
  void applyPriceCalculation(PriceCalculationResult result) {
    capacityKw = result.capacityKw;
    lineItems = List<EstimateLineItem>.from(result.lineItems);
    priceBreakdown = result.breakdown;
    structureQuantities
      ..clear()
      ..addAll(result.structureQuantities);
    discountPerKw = result.discountPerKw;
    gstProfileLabel = result.gstProfileLabel;
    insuranceIncluded = result.insuranceIncluded;
    insuranceType = result.insuranceType;
    insurancePercent = result.insurancePercent;
    insuranceAmount = result.insuranceAmount;
  }

  /// Build a PriceCalcState from the current estimate (for re-opening calculator).
  PriceCalcState toPriceCalcState() => PriceCalcState(
        structureQuantities: Map<String, int>.from(structureQuantities),
        discountPerKw: discountPerKw,
        gstProfileLabel: gstProfileLabel,
        insuranceIncluded: insuranceIncluded,
        insuranceType: insuranceType,
        insurancePercent: insurancePercent,
        insuranceAmount: insuranceAmount,
      );

  Map<String, dynamic> toJson() => {
        'client_type': clientType,
        'company_name': companyName,
        'lead_name': leadName,
        'mobile_number': mobileNumber,
        'whatsapp_number': whatsappNumber,
        'auto_fill_whatsapp': autoFillWhatsApp,
        'lead_stage': leadStage,
        'description': description,
        'email': email,
        'address': address,
        'estimate_number': estimateNumber,
        'reference_no': referenceNo,
        'expiry_date': expiryDate.toIso8601String(),
        'currency': currency,
        'capacity_kw': capacityKw,
        'system_id': systemId,
        'wiring_sq_mm': wiringSqMm,
        'inverter_kw_manual': inverterKwManual,
        'total_payable_override': totalPayableOverride,
        'gst_included': gstIncluded,
        'tax_mode': taxMode,
        'line_items': lineItems.map((e) => e.toJson()).toList(),
        'structure_quantities': structureQuantities,
        'discount_per_kw': discountPerKw,
        'gst_profile_label': gstProfileLabel,
        'insurance_included': insuranceIncluded,
        'insurance_type': insuranceType,
        'insurance_percent': insurancePercent,
        'insurance_amount': insuranceAmount,
        'price_breakdown': priceBreakdown?.toJson(),
      };

  factory EstimateModel.fromJson(
      Map<String, dynamic> j, MasterData master) {
    final structureQty = Map<String, int>.from(
        (j['structure_quantities'] as Map? ?? {})
            .map((k, v) => MapEntry(k as String, v as int)));
    return EstimateModel(
      clientType: j['client_type'] as String? ?? 'individual',
      companyName: j['company_name'] as String?,
      leadName: j['lead_name'] as String? ?? '',
      mobileNumber: j['mobile_number'] as String? ?? '',
      whatsappNumber: j['whatsapp_number'] as String?,
      autoFillWhatsApp: j['auto_fill_whatsapp'] as bool? ?? false,
      leadStage: j['lead_stage'] as String? ?? 'new',
      description: j['description'] as String?,
      email: j['email'] as String?,
      address: j['address'] as String?,
      estimateNumber: j['estimate_number'] as String? ?? '',
      referenceNo: j['reference_no'] as String?,
      expiryDate: j['expiry_date'] != null
          ? DateTime.parse(j['expiry_date'] as String)
          : null,
      currency: j['currency'] as String? ?? 'INR',
      capacityKw: (j['capacity_kw'] as num?)?.toDouble(),
      systemId: j['system_id'] as String?,
      wiringSqMm: j['wiring_sq_mm'] as String?,
      inverterKwManual: (j['inverter_kw_manual'] as num?)?.toDouble(),
      totalPayableOverride: j['total_payable_override'] as int?,
      gstIncluded: j['gst_included'] as bool? ?? true,
      taxMode: j['tax_mode'] as String? ?? 'exclusive',
      lineItems: (j['line_items'] as List? ?? [])
          .map((e) =>
              EstimateLineItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      structureQuantities: structureQty,
      discountPerKw: (j['discount_per_kw'] as num?)?.toDouble() ?? 0,
      gstProfileLabel: j['gst_profile_label'] as String? ?? '',
      insuranceIncluded: j['insurance_included'] as bool? ?? false,
      insuranceType: j['insurance_type'] as String? ?? 'percent',
      insurancePercent:
          (j['insurance_percent'] as num?)?.toDouble() ?? 0,
      insuranceAmount: j['insurance_amount'] as int? ?? 0,
      priceBreakdown: j['price_breakdown'] != null
          ? PriceBreakdown.fromJson(
              Map<String, dynamic>.from(j['price_breakdown'] as Map), master)
          : null,
    );
  }
}

// â”€â”€ Estimate wrapper for persistence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class EstimateRecord {
  final String id;
  final EstimateModel data;
  final DateTime createdAt;
  final DateTime updatedAt;

  EstimateRecord({
    required this.id,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toJson(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory EstimateRecord.fromJson(
      Map<String, dynamic> j, MasterData master) {
    return EstimateRecord(
      id: j['id'] as String,
      data: EstimateModel.fromJson(
          Map<String, dynamic>.from(j['data'] as Map), master),
      createdAt: j['created_at'] != null
          ? DateTime.parse(j['created_at'] as String)
          : DateTime.now(),
      updatedAt: j['updated_at'] != null
          ? DateTime.parse(j['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
