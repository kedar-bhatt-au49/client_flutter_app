import '../core/constants.dart';
import '../models/app_settings.dart';
import '../models/client.dart';
import '../models/follow_up.dart';
import '../models/installation.dart';
import '../models/payment.dart';
import '../models/quote.dart';
import 'database_service.dart';

/// Generates realistic mock data on first launch so the app is fully
/// functional without a Firebase backend.
class SeedData {
  void populate(DatabaseService db) {
    final now = DateTime.now();
    final uid = GSUsers.founderUid;

    // ── Clients ────────────────────────────────────────────────────
    final clients = <ClientModel>[
      ClientModel(
        id: db.generateId(),
        name: 'Ramesh Patel',
        phone: '9876543210',
        area: GSArea.talaja,
        propertyType: GSPropertyType.residential,
        monthlyBill: 3800,
        preferredPackage: '4.31',
        source: GSSource.whatsapp,
        status: 'quoted',
        ownerUid: uid,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      ClientModel(
        id: db.generateId(),
        name: 'Sita Devi',
        phone: '9876543211',
        area: GSArea.bhavnagar,
        propertyType: GSPropertyType.residential,
        monthlyBill: 4200,
        preferredPackage: '3.69',
        source: GSSource.website,
        status: 'contacted',
        ownerUid: uid,
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      ClientModel(
        id: db.generateId(),
        name: 'Mohan Lal',
        phone: '9876543212',
        area: GSArea.talaja,
        propertyType: GSPropertyType.residential,
        monthlyBill: 5500,
        preferredPackage: '6.15',
        source: GSSource.walkIn,
        status: 'booked',
        ownerUid: uid,
        notes: 'Confirmed booking. Wants elevated structure.',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      ClientModel(
        id: db.generateId(),
        name: 'Priya & Co.',
        phone: '9876543213',
        area: GSArea.bhavnagar,
        propertyType: GSPropertyType.commercial,
        monthlyBill: 18000,
        preferredPackage: 'not-sure',
        source: GSSource.referral,
        status: 'new',
        ownerUid: uid,
        createdAt: now,
        updatedAt: now,
      ),
      ClientModel(
        id: db.generateId(),
        name: 'Kantilal Builder',
        phone: '9876543214',
        area: GSArea.village,
        village: 'Kaliyabid',
        propertyType: GSPropertyType.commercial,
        monthlyBill: 32000,
        preferredPackage: '5.54',
        source: GSSource.walkIn,
        status: 'installed',
        ownerUid: uid,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
      ClientModel(
        id: db.generateId(),
        name: 'Bhavinbhai',
        phone: '9876543215',
        area: GSArea.talaja,
        propertyType: GSPropertyType.residential,
        monthlyBill: 2900,
        preferredPackage: '3.08',
        source: GSSource.whatsapp,
        status: 'site-visit',
        ownerUid: uid,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
      ClientModel(
        id: db.generateId(),
        name: 'Dr. Shyam Mishra',
        phone: '9876543216',
        area: GSArea.bhavnagar,
        propertyType: GSPropertyType.residential,
        monthlyBill: 7800,
        preferredPackage: '4.92',
        source: GSSource.website,
        status: 'lost',
        ownerUid: uid,
        notes: 'Went with competitor (lower price).',
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 40)),
      ),
    ];

    final ids = <String>[];
    for (final c in clients) {
      db.saveClient(c);
      ids.add(c.id);
    }

    // ── Quotes ───────────────────────────────────────────────────
    final pkgP5 = gsPackages.firstWhere((p) => p.id == 'p5');
    final pkgP4 = gsPackages.firstWhere((p) => p.id == 'p4');
    final pkgP3 = gsPackages.firstWhere((p) => p.id == 'p3');
    final pkgP8 = gsPackages.firstWhere((p) => p.id == 'p8');

    db.saveQuote(QuoteModel(
      id: db.generateId(),
      clientId: clients[0].id,
      packageId: pkgP5.id,
      kw: pkgP5.kw,
      panels: pkgP5.panels,
      upfront: pkgP5.upfront,
      afterSubsidy: pkgP5.afterSubsidy,
      structureCost: pkgP5.structureCost,
      total: pkgP5.upfront,
      status: 'sent',
      sentAt: now.subtract(const Duration(days: 2)),
      isResidential: true,
    ));

    db.saveQuote(QuoteModel(
      id: db.generateId(),
      clientId: clients[1].id,
      packageId: pkgP4.id,
      kw: pkgP4.kw,
      panels: pkgP4.panels,
      upfront: pkgP4.upfront,
      afterSubsidy: pkgP4.afterSubsidy,
      structureCost: pkgP4.structureCost,
      total: pkgP4.upfront,
      status: 'draft',
      sentAt: now.subtract(const Duration(days: 1)),
      isResidential: true,
    ));

    db.saveQuote(QuoteModel(
      id: db.generateId(),
      clientId: clients[2].id,
      packageId: pkgP8.id,
      kw: pkgP8.kw,
      panels: pkgP8.panels,
      upfront: pkgP8.upfront,
      afterSubsidy: pkgP8.afterSubsidy,
      structureCost: pkgP8.structureCost,
      total: pkgP8.upfront,
      status: 'accepted',
      sentAt: now.subtract(const Duration(days: 15)),
      acceptedAt: now.subtract(const Duration(days: 10)),
      isResidential: true,
    ));

    db.saveQuote(QuoteModel(
      id: db.generateId(),
      clientId: clients[5].id,
      packageId: pkgP3.id,
      kw: pkgP3.kw,
      panels: pkgP3.panels,
      upfront: pkgP3.upfront,
      afterSubsidy: pkgP3.afterSubsidy,
      structureCost: pkgP3.structureCost,
      total: pkgP3.upfront,
      status: 'draft',
      sentAt: now,
      isResidential: true,
    ));

    // ── Payments ─────────────────────────────────────────────────
    db.savePayment(PaymentModel(
      id: db.generateId(),
      clientId: clients[0].id,
      registrationPaid: true,
      registrationDate: now.subtract(const Duration(days: 2)),
      balancePaid: false,
    ));

    db.savePayment(PaymentModel(
      id: db.generateId(),
      clientId: clients[1].id,
      registrationPaid: true,
      registrationDate: now.subtract(const Duration(days: 1)),
      balancePaid: false,
    ));

    db.savePayment(PaymentModel(
      id: db.generateId(),
      clientId: clients[2].id,
      registrationPaid: true,
      registrationDate: now.subtract(const Duration(days: 15)),
      balancePaid: true,
      balanceDate: now.subtract(const Duration(days: 3)),
    ));

    // ── Installations ───────────────────────────────────────────
    final installDate = now.subtract(const Duration(days: 15));
    db.saveInstallation(InstallationModel(
      id: db.generateId(),
      clientId: clients[2].id,
      stage: 'pvcl-inspection',
      warrantyExpiry: WarrantyExpiry.fromInstallDate(installDate),
      installDate: installDate,
      notes: 'Net meter application submitted.',
    ));

    // ── Follow-ups ───────────────────────────────────────────────
    db.saveFollowUp(FollowUpModel(
      id: db.generateId(),
      clientId: clients[0].id,
      date: now.subtract(const Duration(days: 1)),
      time: '15:00',
      status: 'done',
      note: 'Shown the quote on WhatsApp. Client interested.',
      createdAt: now.subtract(const Duration(days: 2)),
      doneAt: now.subtract(const Duration(days: 1)),
    ));

    db.saveFollowUp(FollowUpModel(
      id: db.generateId(),
      clientId: clients[0].id,
      date: now.add(const Duration(days: 1)),
      time: '10:30',
      status: 'pending',
      note: 'Follow up on quote acceptance.',
      createdAt: now,
    ));

    db.saveFollowUp(FollowUpModel(
      id: db.generateId(),
      clientId: clients[1].id,
      date: now,
      time: '16:00',
      status: 'pending',
      note: 'Call to schedule site visit.',
      createdAt: now.subtract(const Duration(days: 1)),
    ));

    db.saveFollowUp(FollowUpModel(
      id: db.generateId(),
      clientId: clients[5].id,
      date: now.subtract(const Duration(days: 3)),
      time: '11:00',
      status: 'missed',
      note: 'Client was not available.',
      createdAt: now.subtract(const Duration(days: 5)),
    ));

    // Today's follow-up
    db.saveFollowUp(FollowUpModel(
      id: db.generateId(),
      clientId: clients[3].id,
      date: now,
      time: '14:00',
      status: 'pending',
      note: 'Initial call for commercial inquiry.',
      createdAt: now,
    ));

    // ── Settings ─────────────────────────────────────────────────
    db.saveSettings(AppSettingsModel());
  }
}
