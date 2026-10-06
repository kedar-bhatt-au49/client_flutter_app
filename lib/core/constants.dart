/// ---------------------------------------------------------------------------
/// Global Solar 2.0 — Client App Constants
///
/// All static configuration mirrors the website's siteConfig / prices.json.
/// ---------------------------------------------------------------------------
library;

/// Area options for client registration.
class GSArea {
  static const talaja = 'Talaja';
  static const bhavnagar = 'Bhavnagar';
  static const village = 'Village';

  static const all = [talaja, bhavnagar, village];

  static const map = {
    talaja: 'તળાજા',
    bhavnagar: 'ભાવનગર',
    village: 'ગામ',
  };
}

/// Property types.
class GSPropertyType {
  static const residential = 'Residential';
  static const commercial = 'Commercial';
  static const all = [residential, commercial];
}

/// Lead / enquiry sources.
class GSSource {
  static const website = 'Website';
  static const whatsapp = 'WhatsApp';
  static const walkIn = 'Walk-in';
  static const referral = 'Referral';
  static const all = [website, whatsapp, walkIn, referral];
}

/// Client pipeline statuses — used for filter chips and status chips.
class GSClientStatus {
  static const newLead = 'new';
  static const contacted = 'contacted';
  static const siteVisit = 'site-visit';
  static const quoted = 'quoted';
  static const booked = 'booked';
  static const installed = 'installed';
  static const subsidized = 'subsidized';
  static const lost = 'lost';

  static const all = [
    newLead,
    contacted,
    siteVisit,
    quoted,
    booked,
    installed,
    subsidized,
    lost,
  ];

  static String labelOf(String status) {
    switch (status) {
      case newLead:
        return 'New Lead';
      case contacted:
        return 'Contacted';
      case siteVisit:
        return 'Site Visit';
      case quoted:
        return 'Quoted';
      case booked:
        return 'Booked';
      case installed:
        return 'Installed';
      case subsidized:
        return 'Subsidized';
      case lost:
        return 'Lost';
      default:
        return status;
    }
  }
}

/// Follow-up statuses.
class GSFollowUpStatus {
  static const pending = 'pending';
  static const done = 'done';
  static const missed = 'missed';
  static const all = [pending, done, missed];
}

/// Quote statuses.
class GSQuoteStatus {
  static const draft = 'draft';
  static const sent = 'sent';
  static const accepted = 'accepted';
  static const rejected = 'rejected';
  static const all = [draft, sent, accepted, rejected];

  static String labelOf(String status) {
    switch (status) {
      case sent:
        return 'Sent';
      case accepted:
        return 'Accepted';
      case rejected:
        return 'Rejected';
      case draft:
        return 'Draft';
      default:
        return status;
    }
  }
}

/// Installation stages in order.
class GSInstallStage {
  static const materialsDispatched = 'materials-dispatched';
  static const fitting = 'fitting';
  static const pvclInspection = 'pvcl-inspection';
  static const netMeter = 'net-meter';
  static const subsidyCredited = 'subsidy-credited';

  static const all = [
    materialsDispatched,
    fitting,
    pvclInspection,
    netMeter,
    subsidyCredited,
  ];

  static String labelOf(String stage) {
    switch (stage) {
      case materialsDispatched:
        return 'Materials Dispatched';
      case fitting:
        return 'Fitting';
      case pvclInspection:
        return 'PGVCL Inspection';
      case netMeter:
        return 'Net Meter';
      case subsidyCredited:
        return 'Subsidy Credited';
      default:
        return stage;
    }
  }

  static int indexOf(String stage) => all.indexOf(stage);
  static bool isComplete(String stage) => indexOf(stage) >= 0;
  static bool isLast(String stage) => stage == subsidyCredited;
}

/// Required documents for payments.
class GSDocument {
  static const electricityBill = 'Electricity Bill';
  static const aadhaar = 'Aadhaar Card';
  static const cancelledCheque = 'Cancelled Cheque';
  static const all = [electricityBill, aadhaar, cancelledCheque];
}

/// Package / pricing data — mirrors src/content/prices.json.
class GSPackage {
  final String id; // e.g. "p3"
  final double kw;
  final int panels;
  final int upfront;
  final int afterSubsidy;
  final int structureCost;
  final String? tag; // e.g. "Most Popular Starter"
  final String? tagGu;

  const GSPackage({
    required this.id,
    required this.kw,
    required this.panels,
    required this.upfront,
    required this.afterSubsidy,
    required this.structureCost,
    this.tag,
    this.tagGu,
  });

  /// Compute the after-subsidy value for residential projects.
  static int computeAfterSubsidy(int upfront) => upfront - GSTax.subsidyMax;
}

/// Master pricing table (from website prices.json).
final List<GSPackage> gsPackages = [
  GSPackage(
      id: 'p3',
      kw: 3.08,
      panels: 5,
      upfront: 162000,
      afterSubsidy: 84000,
      structureCost: 8000,
      tag: 'Most Popular Starter',
      tagGu: 'સૌથી લોકપ્રિય સ્ટાર્ટર'),
  GSPackage(
      id: 'p4', kw: 3.69, panels: 6, upfront: 185000, afterSubsidy: 107000,
      structureCost: 10000),
  GSPackage(
      id: 'p5',
      kw: 4.31,
      panels: 7,
      upfront: 215000,
      afterSubsidy: 137000,
      structureCost: 12000,
      tag: 'Best Value',
      tagGu: 'શ્રેષ્ઠ મૂલ્ય'),
  GSPackage(
      id: 'p6',
      kw: 4.92,
      panels: 8,
      upfront: 242000,
      afterSubsidy: 164000,
      structureCost: 13000),
  GSPackage(
      id: 'p7',
      kw: 5.54,
      panels: 9,
      upfront: 265000,
      afterSubsidy: 187000,
      structureCost: 15000),
  GSPackage(
      id: 'p8',
      kw: 6.15,
      panels: 10,
      upfront: 290000,
      afterSubsidy: 212000,
      structureCost: 16000),
];

GSPackage? gsPackageById(String id) {
  for (final p in gsPackages) {
    if (p.id == id) return p;
  }
  return null;
}

/// Official quotation system table (rooftop solar).
///
/// [totalPayable] is **GST-inclusive** (CGST 4.45% + SGST 4.45% = 8.9%).
/// [afterSubsidy] = totalPayable − PM Surya Ghar subsidy (₹78,000).
class GSQuoteSystem {
  final String id;
  final String brandEn; // e.g. 'Adani Bi-Facial'
  final String brandGu; // e.g. 'અદાણી બાય એફિશિયલ'
  final String wattLabel; // e.g. '540/545/550'
  final double kw;
  final int panels;
  final int structureCost; // GST-excluded
  final int totalPayable; // GST-inclusive, pre-subsidy
  final int subsidy;
  final int afterSubsidy;
  final int moduleWarrantyYears; // panel linear-performance warranty

  const GSQuoteSystem({
    required this.id,
    required this.brandEn,
    required this.brandGu,
    required this.wattLabel,
    required this.kw,
    required this.panels,
    this.structureCost = 10000,
    required this.totalPayable,
    this.subsidy = GSTax.subsidyMax,
    required this.afterSubsidy,
    this.moduleWarrantyYears = 30,
  });

  int get stampCharge => GSTax.stampCharge;

  /// e.g. "3.27 kW  •  6 panels"
  String get label => '${kw.toStringAsFixed(2)} kW  •  $panels panels';

  /// e.g. "Adani Bi-Facial 540/545/550 W"
  String get brandLine => '$brandEn $wattLabel W';

  /// Panel-count design image (assets/images/solar_pannel_N).
  /// 6 panels uses the corrected PNG; the others are JPGs.
  String get panelImageAsset => panels == 6
      ? 'assets/images/solar_pannel_6.png'
      : 'assets/images/solar_pannel_$panels.jpg';
}

/// Master quotation systems — three panel brands (Adani Bi-Facial,
/// Adani TOPCon, Waaree TOPCon). Gross = after-subsidy + ₹78,000.
final List<GSQuoteSystem> gsQuoteSystems = const [
  // ── Adani Bi-Facial 540/545/550 W ──
  GSQuoteSystem(
      id: 'abf6', brandEn: 'Adani Bi-Facial', brandGu: 'અદાણી બાય એફિશિયલ',
      wattLabel: '540/545/550', moduleWarrantyYears: 25, kw: 3.27, panels: 6,
      totalPayable: 163000, afterSubsidy: 85000),
  GSQuoteSystem(
      id: 'abf7', brandEn: 'Adani Bi-Facial', brandGu: 'અદાણી બાય એફિશિયલ',
      wattLabel: '540/545/550', moduleWarrantyYears: 25, kw: 3.81, panels: 7,
      totalPayable: 193000, afterSubsidy: 115000),
  GSQuoteSystem(
      id: 'abf8', brandEn: 'Adani Bi-Facial', brandGu: 'અદાણી બાય એફિશિયલ',
      wattLabel: '540/545/550', moduleWarrantyYears: 25, kw: 4.36, panels: 8,
      totalPayable: 216000, afterSubsidy: 138000),
  GSQuoteSystem(
      id: 'abf9', brandEn: 'Adani Bi-Facial', brandGu: 'અદાણી બાય એફિશિયલ',
      wattLabel: '540/545/550', moduleWarrantyYears: 25, kw: 4.90, panels: 9,
      totalPayable: 244000, afterSubsidy: 166000),
  GSQuoteSystem(
      id: 'abf10', brandEn: 'Adani Bi-Facial', brandGu: 'અદાણી બાય એફિશિયલ',
      wattLabel: '540/545/550', moduleWarrantyYears: 25, kw: 5.45, panels: 10,
      totalPayable: 266000, afterSubsidy: 188000),
  // ── Adani TOPCon 610/615/620 W ──
  GSQuoteSystem(
      id: 'atc5', brandEn: 'Adani TOPCon', brandGu: 'અદાણી ટોપકોન',
      wattLabel: '610/615/620', kw: 3.08, panels: 5,
      totalPayable: 162000, afterSubsidy: 84000),
  GSQuoteSystem(
      id: 'atc6', brandEn: 'Adani TOPCon', brandGu: 'અદાણી ટોપકોન',
      wattLabel: '610/615/620', kw: 3.69, panels: 6,
      totalPayable: 185000, afterSubsidy: 107000),
  GSQuoteSystem(
      id: 'atc7', brandEn: 'Adani TOPCon', brandGu: 'અદાણી ટોપકોન',
      wattLabel: '610/615/620', kw: 4.31, panels: 7,
      totalPayable: 215000, afterSubsidy: 137000),
  GSQuoteSystem(
      id: 'atc8', brandEn: 'Adani TOPCon', brandGu: 'અદાણી ટોપકોન',
      wattLabel: '610/615/620', kw: 4.92, panels: 8,
      totalPayable: 242000, afterSubsidy: 164000),
  GSQuoteSystem(
      id: 'atc9', brandEn: 'Adani TOPCon', brandGu: 'અદાણી ટોપકોન',
      wattLabel: '610/615/620', kw: 5.54, panels: 9,
      totalPayable: 265000, afterSubsidy: 187000),
  GSQuoteSystem(
      id: 'atc10', brandEn: 'Adani TOPCon', brandGu: 'અદાણી ટોપકોન',
      wattLabel: '610/615/620', kw: 6.15, panels: 10,
      totalPayable: 290000, afterSubsidy: 212000),
  // ── Waaree TOPCon 610/615/620 W ──
  GSQuoteSystem(
      id: 'wtc5', brandEn: 'Waaree TOPCon', brandGu: 'વારી ટોપકોન',
      wattLabel: '610/615/620', kw: 3.07, panels: 5,
      totalPayable: 154000, afterSubsidy: 76000),
  GSQuoteSystem(
      id: 'wtc6', brandEn: 'Waaree TOPCon', brandGu: 'વારી ટોપકોન',
      wattLabel: '610/615/620', kw: 3.69, panels: 6,
      totalPayable: 178000, afterSubsidy: 100000),
  GSQuoteSystem(
      id: 'wtc7', brandEn: 'Waaree TOPCon', brandGu: 'વારી ટોપકોન',
      wattLabel: '610/615/620', kw: 4.30, panels: 7,
      totalPayable: 212000, afterSubsidy: 134000),
  GSQuoteSystem(
      id: 'wtc8', brandEn: 'Waaree TOPCon', brandGu: 'વારી ટોપકોન',
      wattLabel: '610/615/620', kw: 4.92, panels: 8,
      totalPayable: 234000, afterSubsidy: 156000),
  GSQuoteSystem(
      id: 'wtc9', brandEn: 'Waaree TOPCon', brandGu: 'વારી ટોપકોન',
      wattLabel: '610/615/620', kw: 5.54, panels: 9,
      totalPayable: 256000, afterSubsidy: 178000),
  GSQuoteSystem(
      id: 'wtc10', brandEn: 'Waaree TOPCon', brandGu: 'વારી ટોપકોન',
      wattLabel: '610/615/620', kw: 6.15, panels: 10,
      totalPayable: 279000, afterSubsidy: 201000),
];

/// Legacy system ids (pre brand split) → new ids.
const _legacySystemIds = {
  's6': 'abf6',
  's7': 'abf7',
  's8': 'abf8',
  's9': 'abf9',
  's10': 'abf10',
};

GSQuoteSystem? gsQuoteSystemById(String id) {
  for (final s in gsQuoteSystems) {
    if (s.id == id) return s;
  }
  final mapped = _legacySystemIds[id];
  if (mapped != null) {
    for (final s in gsQuoteSystems) {
      if (s.id == mapped) return s;
    }
  }
  return null;
}

/// GST for rooftop solar — CGST 4.45% + SGST 4.45% = 8.9% (GST-inclusive).
class GSGst {
  static const cgstPercent = 4.45;
  static const sgstPercent = 4.45;
  static const totalPercent = 8.9;

  /// Splits a GST-inclusive [total] into base + CGST + SGST such that
  /// `base + cgst + sgst == total` exactly (rounding noise absorbed by base).
  static ({int base, int cgst, int sgst}) splitInclusive(int total) {
    final cgst = (total * cgstPercent / (100 + totalPercent)).round();
    final sgst = (total * sgstPercent / (100 + totalPercent)).round();
    final base = total - cgst - sgst;
    return (base: base, cgst: cgst, sgst: sgst);
  }
}

/// Subsidy & tax constants (mirrors siteConfig).
class GSTax {
  static const subsidyMax = 78000; // ₹78,000 (PM Surya Ghar)
  static const stampCharge = 300; // ₹300 stamp charge
  static const registrationAmount = 10000; // ₹10,000
  static const pricesLastUpdated = '2026-09-29';
}

/// Warranty periods in years (from plan §8).
class GSWarranty {
  static const omYears = 5; // 2024 → 2029
  static const panelYears = 12; // → 2036
  static const performanceYears = 30; // → 2054
  static const inverterYears = 8; // → 2032
}

/// Pre-created user accounts (no sign-up — mirrors plan §2).
class GSUsers {
  static const founderUid = 'owner_jayrajsinh';
  static const coFounderUid = 'coowner_gopalsinh';

  static const founderEmail = 'jayrajumat7797@gmail.com';
  static const coFounderEmail = 'gopalsinh.parmar@gmail.com';
  static const founderPhone = '8488807797';
  static const coFounderPhone = '8866568543';
  static const whatsappNumber = '918488807797';

  static const appPassword = 'GS2_Solar@2026';
}

/// Working hours (mirrors siteConfig).
class GSWorkingHours {
  static const en = '9:00 AM – 8:00 PM, all days';
  static const gu = 'સવારે 9:00 થી રાત્રે 8:00, બધા દિવસ';
}

/// Navigation bar labels.
class GSNav {
  static const dashboard = 'Dashboard';
  static const clients = 'Clients';
  static const followups = 'Follow-ups';
  static const reports = 'Reports';
  static const settings = 'Settings';
}

/// Default padding values.
class GSPadding {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

/// Animation durations.
class GSAnimation {
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 400);
  static const slow = Duration(milliseconds: 800);
}

/// Extension for formatting currency.
extension GSPriceExtension on num {
  /// Format as Indian Rupee currency.
  String get inr => '₹${formatWithComma()}';

  /// Format with Indian-style comma grouping (e.g. 1,62,000).
  String formatWithComma() {
    final s = toStringAsFixed(0);
    // Simple Indian comma formatting
    final result = <String>[];
    final reversed = s.split('').reversed.toList();
    for (var j = 0; j < reversed.length; j++) {
      if (j > 0 && j % 2 == 0 && j < reversed.length - 3) {
        result.add(',');
      }
      result.add(reversed[j]);
    }
    return result.reversed.join();
  }

  /// Compact format for large numbers (e.g. 1.6L, 16.2K).
  String get compact {
    if (this >= 100000) {
      return '${(this / 100000).toStringAsFixed(1)}L';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toStringAsFixed(0);
  }
}

/// Standard Bill of Materials master list (Item + Brand / Details).
class GSBomItem {
  final String name;
  final String brand;
  final String unit;
  final int qty;
  const GSBomItem({
    required this.name,
    required this.brand,
    this.unit = 'Nos',
    this.qty = 1,
  });
}

const gsBomItems = <GSBomItem>[
  GSBomItem(
      name: 'Solar Panels',
      brand: 'ADANI TOPCON (610/615)',
      unit: 'Nos',
      qty: 8),
  GSBomItem(name: 'Inverter', brand: 'POLYCAB'),
  GSBomItem(
      name: 'Structure',
      brand: '80 × 40 × 2 MM (LEG & RAFTER) / 40 × 40 × 2 MM (PERLIN)',
      unit: 'Set'),
  GSBomItem(name: 'AC Cables', brand: 'POLYCAB', unit: 'Lot'),
  GSBomItem(name: 'DC Cables', brand: 'POLYCAB', unit: 'Lot'),
  GSBomItem(name: 'Earthing Cables', brand: 'POLYCAB', unit: 'Lot'),
  GSBomItem(name: 'LA Cable', brand: 'KANBERY / KOREMAN', unit: 'Lot'),
  GSBomItem(name: 'MCB', brand: 'HEVELLS'),
  GSBomItem(name: 'SPD', brand: 'ELMEX / PHOENIX'),
];
