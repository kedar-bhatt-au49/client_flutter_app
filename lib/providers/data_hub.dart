import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/app_settings.dart';
import '../models/client.dart';
import '../models/follow_up.dart';
import '../models/installation.dart';
import '../models/payment.dart';
import '../models/quote.dart';
import '../models/estimate.dart';
import '../services/database_service.dart';

/// Central data hub — loads, caches, and manages all application data.
///
/// Each method persists to Hive and notifies UI listeners.
class DataHub extends ChangeNotifier {
  final DatabaseService _db;
  bool _loading = true;
  String? _error;

  List<ClientModel> _clients = [];
  List<FollowUpModel> _followUps = [];
  List<QuoteModel> _quotes = [];
  List<PaymentModel> _payments = [];
  List<InstallationModel> _installations = [];
  List<EstimateRecord> _estimates = [];
  AppSettingsModel? _settings;

  DataHub(this._db);

  bool get loading => _loading;
  String? get error => _error;
  List<ClientModel> get clients => List.unmodifiable(_clients);
  List<FollowUpModel> get followUps => List.unmodifiable(_followUps);
  List<QuoteModel> get quotes => List.unmodifiable(_quotes);
  List<PaymentModel> get payments => List.unmodifiable(_payments);
  List<InstallationModel> get installations =>
      List.unmodifiable(_installations);
  List<EstimateRecord> get estimates => List.unmodifiable(_estimates);
  AppSettingsModel? get settings => _settings;

  String generateId() => _db.generateId();

  Future<void> init() async {
    await _db.init();
    await _db.seedIfNeeded();
    await _loadAll();
  }

  Future<void> _loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _clients = await _db.getAllClients();
      _followUps = await _db.getAllFollowUps();
      _quotes = await _db.getAllQuotes();
      _payments = await _db.getAllPayments();
      _installations = await _db.getAllInstallations();
      _estimates = await _db.getAllEstimates();
      _settings = await _db.getSettings();
      _loading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }
    notifyListeners();
  }

  // ── Clients ───────────────────────────────────────────────────

  Future<void> addClient(ClientModel client) async {
    await _db.saveClient(client);
    _clients.insert(0, client);
    _clients.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  Future<void> updateClient(ClientModel client) async {
    await _db.saveClient(client);
    final idx = _clients.indexWhere((c) => c.id == client.id);
    if (idx >= 0) {
      _clients[idx] = client;
      _clients.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }
  }

  Future<void> deleteClient(String id) async {
    await _db.deleteClient(id);
    _clients.removeWhere((c) => c.id == id);
    _followUps.removeWhere((f) => f.clientId == id);
    _quotes.removeWhere((q) => q.clientId == id);
    _payments.removeWhere((p) => p.clientId == id);
    _installations.removeWhere((i) => i.clientId == id);
    notifyListeners();
  }

  ClientModel? getClient(String id) {
    final idx = _clients.indexWhere((c) => c.id == id);
    return idx >= 0 ? _clients[idx] : null;
  }

  List<ClientModel> searchClients(String query) {
    final q = query.toLowerCase();
    return _clients.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.area.toLowerCase().contains(q) ||
          (c.village?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<ClientModel> getClientsByStatus(String status) =>
      _clients.where((c) => c.status == status).toList();

  List<ClientModel> getClientsByArea(String area) {
    if (area == 'all') return _clients;
    return _clients
        .where((c) => c.area == area || c.displayArea == area)
        .toList();
  }

  // ── Follow-ups ──────────────────────────────────────────────────

  Future<void> addFollowUp(FollowUpModel followUp) async {
    await _db.saveFollowUp(followUp);
    _followUps.add(followUp);
    _sortFollowUps();
    notifyListeners();
  }

  Future<void> updateFollowUp(FollowUpModel followUp) async {
    await _db.saveFollowUp(followUp);
    final idx = _followUps.indexWhere((f) => f.id == followUp.id);
    if (idx >= 0) {
      _followUps[idx] = followUp;
      _sortFollowUps();
      notifyListeners();
    }
  }

  Future<void> deleteFollowUp(String id) async {
    await _db.deleteFollowUp(id);
    _followUps.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  List<FollowUpModel> getFollowUpsForClient(String clientId) =>
      _followUps.where((f) => f.clientId == clientId).toList();

  List<FollowUpModel> get todayFollowUps {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _followUps.where((f) {
      final fDate = DateTime(f.date.year, f.date.month, f.date.day);
      return fDate == today;
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<FollowUpModel> get pendingFollowUps =>
      _followUps.where((f) => f.status == 'pending').toList();

  void _sortFollowUps() {
    _followUps.sort((a, b) {
      final cmp = a.date.compareTo(b.date);
      if (cmp != 0) return cmp;
      return a.time.compareTo(b.time);
    });
  }

  // ── Quotes ────────────────────────────────────────────────────

  Future<void> saveQuote(QuoteModel quote) async {
    await _db.saveQuote(quote);
    final idx = _quotes.indexWhere((q) => q.id == quote.id);
    if (idx >= 0) {
      _quotes[idx] = quote;
    } else {
      _quotes.insert(0, quote);
    }
    _quotes.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    notifyListeners();
  }

  QuoteModel? getQuoteForClient(String clientId) {
    final qs = _quotes.where((q) => q.clientId == clientId).toList();
    if (qs.isEmpty) return null;
    qs.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return qs.first;
  }

  Future<void> deleteQuote(String id) async {
    // Note: DatabaseService doesn't have deleteQuote by id directly
    // Would need to add it; for now skip
    _quotes.removeWhere((q) => q.id == id);
    notifyListeners();
  }

  // ── Payments ──────────────────────────────────────────────────

  Future<void> savePayment(PaymentModel payment) async {
    await _db.savePayment(payment);
    final idx = _payments.indexWhere((p) => p.clientId == payment.clientId);
    if (idx >= 0) {
      _payments[idx] = payment;
    } else {
      _payments.add(payment);
    }
    notifyListeners();
  }

  PaymentModel? getPaymentForClient(String clientId) {
    final idx = _payments.indexWhere((p) => p.clientId == clientId);
    return idx >= 0 ? _payments[idx] : null;
  }

  // ── Installations ──────────────────────────────────────────────

  Future<void> saveInstallation(InstallationModel installation) async {
    await _db.saveInstallation(installation);
    final idx = _installations.indexWhere(
        (i) => i.clientId == installation.clientId);
    if (idx >= 0) {
      _installations[idx] = installation;
    } else {
      _installations.add(installation);
    }
    notifyListeners();
  }

  InstallationModel? getInstallationForClient(String clientId) {
    final idx =
        _installations.indexWhere((i) => i.clientId == clientId);
    return idx >= 0 ? _installations[idx] : null;
  }

  // ── Dashboard stats ──────────────────────────────────────────

  DashboardStats getDashboardStats() {
    final newLeads = _clients.where((c) => c.status == 'new').length;
    final todayFU = todayFollowUps.length;
    final pendingQuotes = _quotes.where((q) => q.status == 'sent').length;
    final installed = _clients.where((c) => c.status == 'installed').length;
    final revenue = _payments.fold<int>(0,
        (sum, p) => sum + (p.registrationPaid ? p.registrationAmount : 0));

    return DashboardStats(
      totalClients: _clients.length,
      newLeads: newLeads,
      todayFollowUps: todayFU,
      pendingQuotes: pendingQuotes,
      installed: installed,
      totalRevenue: revenue,
    );
  }

  // ── Settings ──────────────────────────────────────────────────

  Future<void> updateSettings(AppSettingsModel settings) async {
    await _db.saveSettings(settings);
    _settings = settings;
    notifyListeners();
  }

  // ── Estimates ───────────────────────────────────────────────────

  Future<EstimateRecord> addEstimate(EstimateModel estimate) async {
    final record = await _db.saveEstimate(estimate);
    _estimates.insert(0, record);
    _estimates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
    return record;
  }

  /// Updates a previously-saved estimate (no duplicate row).
  Future<EstimateRecord> updateEstimate(
      EstimateRecord existing, EstimateModel estimate) async {
    final record =
        await _db.updateEstimate(existing.id, estimate, createdAt: existing.createdAt);
    final i = _estimates.indexWhere((r) => r.id == existing.id);
    if (i != -1) {
      _estimates[i] = record;
    } else {
      _estimates.insert(0, record);
    }
    notifyListeners();
    return record;
  }

  int get estimateCount => _estimates.length;

  // ── Pipeline ──────────────────────────────────────────────────

  Map<String, int> getPipelineCounts() {
    final counts = <String, int>{};
    for (final s in GSClientStatus.all) {
      counts[s] = _clients.where((c) => c.status == s).length;
    }
    return counts;
  }

  List<MapEntry<String, int>> get pipelineEntries {
    final data = getPipelineCounts();
    return GSClientStatus.all
        .map((s) => MapEntry(GSClientStatus.labelOf(s), data[s] ?? 0))
        .toList();
  }
}
