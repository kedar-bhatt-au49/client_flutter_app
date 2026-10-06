import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/follow_up.dart';
import '../models/installation.dart';
import '../models/payment.dart';
import '../models/quote.dart';
import '../models/estimate.dart';
import '../models/app_settings.dart';
import 'seed_data.dart';

/// Central data service — persists entities via Hive boxes.
///
/// In production this contract is implemented by Firestore; for v1 it is
/// backed by Hive so the app works fully offline.
class DatabaseService {
  static const _uuid = Uuid();

  // Box names
  static const boxClients = 'clients';
  static const boxFollowUps = 'followups';
  static const boxQuotes = 'quotes';
  static const boxPayments = 'payments';
  static const boxInstallations = 'installations';
  static const boxSettings = 'settings';
  static const boxApp = 'app';
  static const boxEstimates = 'estimates';

  // Keys
  static const keyFirstRun = 'first_run_done';
  static const keySettings = 'single';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.openBox(boxClients);
    await Hive.openBox(boxFollowUps);
    await Hive.openBox(boxQuotes);
    await Hive.openBox(boxPayments);
    await Hive.openBox(boxInstallations);
    await Hive.openBox(boxSettings);
    await Hive.openBox(boxApp);
    await Hive.openBox(boxEstimates);
    _initialized = true;
  }

  String generateId() => _uuid.v4();

  // ── First-run seed ────────────────────────────────────────────

  Future<bool> isFirstRun() async {
    final box = Hive.box(boxApp);
    return box.get(keyFirstRun) != true;
  }

  Future<void> markFirstRunDone() async {
    final box = Hive.box(boxApp);
    await box.put(keyFirstRun, true);
  }

  Future<void> seedIfNeeded() async {
    if (!await isFirstRun()) return;
    final seed = SeedData();
    seed.populate(this);
    await markFirstRunDone();
  }

  // ── Settings ──────────────────────────────────────────────────

  Future<AppSettingsModel> getSettings() async {
    final box = Hive.box(boxSettings);
    final data = box.get(keySettings);
    if (data != null) return AppSettingsModel.fromJson(Map<String, dynamic>.from(data as Map));
    final settings = AppSettingsModel();
    await box.put(keySettings, settings.toJson());
    return settings;
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    final box = Hive.box(boxSettings);
    await box.put(keySettings, settings.toJson());
  }

  // ── Clients ───────────────────────────────────────────────────

  Future<List<ClientModel>> getAllClients() async {
    final box = Hive.box(boxClients);
    return box.values
        .map((e) => ClientModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<ClientModel?> getClient(String id) async {
    final box = Hive.box(boxClients);
    final data = box.get(id);
    if (data == null) return null;
    return ClientModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveClient(ClientModel client) async {
    final box = Hive.box(boxClients);
    await box.put(client.id, client.toJson());
  }

  Future<void> deleteClient(String id) async {
    final box = Hive.box(boxClients);
    await box.delete(id);
    // Cascade: delete linked follow-ups, quotes, payments, installations
    await deleteFollowUpsForClient(id);
    await deleteQuotesForClient(id);
    await deletePaymentsForClient(id);
    await deleteInstallationsForClient(id);
  }

  Future<List<ClientModel>> searchClients(String query) async {
    final all = await getAllClients();
    final q = query.toLowerCase();
    return all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.area.toLowerCase().contains(q) ||
          (c.village?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<List<ClientModel>> getClientsByStatus(String status) async {
    final all = await getAllClients();
    return all.where((c) => c.status == status).toList();
  }

  Future<List<ClientModel>> getClientsByArea(String area) async {
    final all = await getAllClients();
    if (area == 'all') return all;
    return all.where((c) => c.area == area || c.displayArea == area).toList();
  }

  // ── Follow-ups ──────────────────────────────────────────────────

  Future<List<FollowUpModel>> getAllFollowUps() async {
    final box = Hive.box(boxFollowUps);
    final items = box.values
        .map((e) => FollowUpModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) {
        final cmp = a.date.compareTo(b.date);
        if (cmp != 0) return cmp;
        return a.time.compareTo(b.time);
      });
    return items;
  }

  Future<List<FollowUpModel>> getFollowUpsForClient(String clientId) async {
    final all = await getAllFollowUps();
    return all.where((f) => f.clientId == clientId).toList();
  }

  Future<List<FollowUpModel>> getTodayFollowUps() async {
    final all = await getAllFollowUps();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return all.where((f) {
      final fDate = DateTime(f.date.year, f.date.month, f.date.day);
      return fDate == today;
    }).toList();
  }

  Future<List<FollowUpModel>> getPendingFollowUps() async {
    final all = await getAllFollowUps();
    return all.where((f) => f.status == 'pending').toList();
  }

  Future<void> saveFollowUp(FollowUpModel followUp) async {
    final box = Hive.box(boxFollowUps);
    await box.put(followUp.id, followUp.toJson());
  }

  Future<void> deleteFollowUp(String id) async {
    final box = Hive.box(boxFollowUps);
    await box.delete(id);
  }

  Future<void> deleteFollowUpsForClient(String clientId) async {
    final all = await getAllFollowUps();
    final box = Hive.box(boxFollowUps);
    for (final f in all.where((f) => f.clientId == clientId)) {
      await box.delete(f.id);
    }
  }

  // ── Quotes ────────────────────────────────────────────────────

  Future<List<QuoteModel>> getAllQuotes() async {
    final box = Hive.box(boxQuotes);
    return box.values
        .map((e) => QuoteModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  Future<QuoteModel?> getQuoteForClient(String clientId) async {
    final all = await getAllQuotes();
    final sorted = all.where((q) => q.clientId == clientId).toList();
    if (sorted.isEmpty) return null;
    sorted.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return sorted.first;
  }

  Future<void> saveQuote(QuoteModel quote) async {
    final box = Hive.box(boxQuotes);
    await box.put(quote.id, quote.toJson());
  }

  Future<void> deleteQuotesForClient(String clientId) async {
    final all = await getAllQuotes();
    final box = Hive.box(boxQuotes);
    for (final q in all.where((q) => q.clientId == clientId)) {
      await box.delete(q.id);
    }
  }

  // ── Payments ──────────────────────────────────────────────────

  Future<PaymentModel?> getPaymentForClient(String clientId) async {
    final box = Hive.box(boxPayments);
    final data = box.get(clientId);
    if (data == null) return null;
    return PaymentModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> savePayment(PaymentModel payment) async {
    final box = Hive.box(boxPayments);
    await box.put(payment.clientId, payment.toJson());
  }

  Future<void> deletePaymentsForClient(String clientId) async {
    final box = Hive.box(boxPayments);
    await box.delete(clientId);
  }

  // ── Installations ──────────────────────────────────────────────

  Future<InstallationModel?> getInstallationForClient(String clientId) async {
    final box = Hive.box(boxInstallations);
    final data = box.get(clientId);
    if (data == null) return null;
    return InstallationModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveInstallation(InstallationModel installation) async {
    final box = Hive.box(boxInstallations);
    await box.put(installation.clientId, installation.toJson());
  }

  Future<void> deleteInstallationsForClient(String clientId) async {
    final box = Hive.box(boxInstallations);
    await box.delete(clientId);
  }

  // ── Estimates ──────────────────────────────────────────────────

  Future<EstimateRecord> saveEstimate(EstimateModel estimate,
      {String? id, MasterData? master}) async {
    master ??= await MasterData.load();
    id ??= DatabaseService._uuid.v4();
    final now = DateTime.now();
    final record = EstimateRecord(
      id: id,
      data: estimate,
      createdAt: now,
      updatedAt: now,
    );
    final box = Hive.box(boxEstimates);
    await box.put(id, record.toJson());
    return record;
  }

  /// Updates an existing estimate in place (keeps its id + createdAt).
  Future<EstimateRecord> updateEstimate(String id, EstimateModel estimate,
      {MasterData? master, DateTime? createdAt}) async {
    final existing = await getEstimate(id);
    final record = EstimateRecord(
      id: id,
      data: estimate,
      createdAt: createdAt ?? existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final box = Hive.box(boxEstimates);
    await box.put(id, record.toJson());
    return record;
  }

  Future<List<EstimateRecord>> getAllEstimates() async {    await init();
    final master = await MasterData.load();
    final box = Hive.box(boxEstimates);
    return box.values
        .map((e) => EstimateRecord.fromJson(
            Map<String, dynamic>.from(e as Map), master))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<EstimateRecord?> getEstimate(String id) async {
    final box = Hive.box(boxEstimates);
    final raw = box.get(id);
    if (raw == null) return null;
    return EstimateRecord.fromJson(
        Map<String, dynamic>.from(raw as Map), await MasterData.load());
  }

  Future<void> deleteEstimate(String id) async {
    final box = Hive.box(boxEstimates);
    await box.delete(id);
  }

  // ── Dashboard stats ──

  Future<DashboardStats> getDashboardStats() async {
    final clients = await getAllClients();
    final quotes = await getAllQuotes();
    final payments = await getAllPayments();

    final newLeads = clients.where((c) => c.status == 'new').length;
    final todayFollowUps = await getTodayFollowUps();
    final pendingQuotes = quotes.where((q) => q.status == 'sent').length;
    final installed = clients.where((c) => c.status == 'installed').length;
    final revenue = payments.fold<int>(
        0, (sum, p) => sum + (p.registrationPaid ? p.registrationAmount : 0));

    return DashboardStats(
      totalClients: clients.length,
      newLeads: newLeads,
      todayFollowUps: todayFollowUps.length,
      pendingQuotes: pendingQuotes,
      installed: installed,
      totalRevenue: revenue,
    );
  }

  Future<List<PaymentModel>> getAllPayments() async {
    final box = Hive.box(boxPayments);
    return box.values
        .map((e) => PaymentModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<InstallationModel>> getAllInstallations() async {
    final box = Hive.box(boxInstallations);
    return box.values
        .map((e) => InstallationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

/// Snapshot of dashboard metrics.
class DashboardStats {
  final int totalClients;
  final int newLeads;
  final int todayFollowUps;
  final int pendingQuotes;
  final int installed;
  final int totalRevenue;

  DashboardStats({
    required this.totalClients,
    required this.newLeads,
    required this.todayFollowUps,
    required this.pendingQuotes,
    required this.installed,
    required this.totalRevenue,
  });
}
