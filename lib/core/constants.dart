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
