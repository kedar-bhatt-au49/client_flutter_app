import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_flavor.dart';
import '../core/constants.dart';
import '../models/client.dart';
import '../models/estimate.dart';
import '../models/follow_up.dart';
import 'firestore_service.dart';

/// Fills a fresh demo project with believable sample data (first run only).
class DemoSeed {
  DemoSeed._();
  static const _flagKey = 'gs_demo_seeded_v1';

  static Future<void> seedIfNeeded() async {
    if (!kDemoMode) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_flagKey) == true) return;

    final fire = FirestoreService.instance;
    final now = DateTime.now();
    final stamp = now.millisecondsSinceEpoch;

    String cid(int i) => 'demo-c$i-$stamp';

    final clients = <ClientModel>[
      ClientModel(
        id: cid(1),
        name: 'Rameshbhai Patel',
        phone: '9876543210',
        area: GSArea.bhavnagar,
        propertyType: GSPropertyType.residential,
        monthlyBill: 3200,
        preferredPackage: 'abf8',
        source: GSSource.website,
        status: GSClientStatus.installed,
        ownerUid: '',
        notes: '5 kW rooftop installed. Subsidy claim in progress.',
        createdAt: now.subtract(const Duration(days: 42)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      ClientModel(
        id: cid(2),
        name: 'Meenaben Desai',
        phone: '9725012345',
        area: GSArea.talaja,
        propertyType: GSPropertyType.residential,
        monthlyBill: 2100,
        preferredPackage: 'wtc5',
        source: GSSource.whatsapp,
        status: GSClientStatus.quoted,
        ownerUid: '',
        notes: 'Wants 3 kW. Comparing Waaree vs Adani.',
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      ClientModel(
        id: cid(3),
        name: 'Shreeji Traders',
        phone: '9900112233',
        area: GSArea.bhavnagar,
        propertyType: GSPropertyType.commercial,
        monthlyBill: 9800,
        preferredPackage: 'atc10',
        source: GSSource.referral,
        status: GSClientStatus.booked,
        ownerUid: '',
        notes: 'Commercial 6 kW. Loan via SBI.',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      ClientModel(
        id: cid(4),
        name: 'Kantibhai Solanki',
        phone: '9812345678',
        area: GSArea.village,
        propertyType: GSPropertyType.residential,
        monthlyBill: 1500,
        preferredPackage: 'not-sure',
        source: GSSource.walkIn,
        status: GSClientStatus.contacted,
        ownerUid: '',
        notes: 'Site visit needed. Roof is asbestos.',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(hours: 20)),
      ),
      ClientModel(
        id: cid(5),
        name: 'Hiral Shah',
        phone: '9922334455',
        area: GSArea.bhavnagar,
        propertyType: GSPropertyType.residential,
        monthlyBill: 4400,
        preferredPackage: 'abf9',
        source: GSSource.phone,
        status: GSClientStatus.siteVisit,
        ownerUid: '',
        notes: 'Site visit done. Waiting for final quote approval.',
        createdAt: now.subtract(const Duration(days: 9)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      ClientModel(
        id: cid(6),
        name: 'Nileshbhai Rathod',
        phone: '9765432109',
        area: GSArea.talaja,
        propertyType: GSPropertyType.residential,
        monthlyBill: 2600,
        preferredPackage: 'atc6',
        source: GSSource.website,
        status: GSClientStatus.newLead,
        ownerUid: '',
        notes: 'New website enquiry.',
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
    ];

    for (final c in clients) {
      await fire.saveClient(c);
    }

    final today = DateTime(now.year, now.month, now.day);
    final followUps = <FollowUpModel>[
      FollowUpModel(
        id: 'demo-f1-$stamp',
        clientId: cid(6),
        date: today.add(const Duration(days: 1)),
        time: '11:00',
        status: 'pending',
        note: 'First call to new website lead.',
        createdAt: now,
      ),
      FollowUpModel(
        id: 'demo-f2-$stamp',
        clientId: cid(4),
        date: today.add(const Duration(days: 2)),
        time: '16:30',
        status: 'pending',
        note: 'Confirm site visit slot.',
        createdAt: now,
      ),
      FollowUpModel(
        id: 'demo-f3-$stamp',
        clientId: cid(2),
        date: today.add(const Duration(days: 3)),
        time: '10:30',
        status: 'pending',
        note: 'Share Adani vs Waaree comparison.',
        createdAt: now,
      ),
      FollowUpModel(
        id: 'demo-f4-$stamp',
        clientId: cid(3),
        date: today.subtract(const Duration(days: 1)),
        time: '12:00',
        status: 'done',
        note: 'Loan documents collected.',
        createdAt: now.subtract(const Duration(days: 3)),
        doneAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    for (final f in followUps) {
      await fire.saveFollowUp(f);
    }

    final estimates = <EstimateModel>[
      EstimateModel(
        clientType: 'individual',
        leadName: 'Meenaben Desai',
        mobileNumber: '9725012345',
        leadStage: 'quoted',
        estimateNumber: 'EST-101',
        capacityKw: 3.07,
        systemId: 'wtc5',
        description: '3 kW Waaree TOPCon rooftop system.',
        createdByName: 'Solar Client App',
        createdByRole: 'owner',
      ),
      EstimateModel(
        clientType: 'business',
        companyName: 'Shreeji Traders',
        leadName: 'Shreeji Traders',
        mobileNumber: '9900112233',
        leadStage: 'booked',
        estimateNumber: 'EST-102',
        capacityKw: 6.15,
        systemId: 'atc10',
        description: '6 kW Adani TOPCon commercial system.',
        createdByName: 'Solar Client App',
        createdByRole: 'owner',
      ),
    ];

    var n = 1;
    for (final e in estimates) {
      await fire.saveEstimate(
        e,
        id: 'demo-e$n-$stamp',
        createdAt: now.subtract(Duration(days: 15 - n)),
      );
      n++;
    }

    await prefs.setBool(_flagKey, true);
  }
}
