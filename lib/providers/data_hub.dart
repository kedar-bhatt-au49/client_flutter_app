import 'dart:async';

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
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

/// Central data hub — loads, caches, and manages all application data.
///
/// Each method persists to Hive and notifies UI listeners.
class DataHub extends ChangeNotifier {
  final DatabaseService _db;
  final FirestoreService _fire;
  StreamSubscription<List<ClientModel>>? _clientsSub;
  StreamSubscription<List<EstimateRecord>>? _estimatesSub;
  StreamSubscription<List<FollowUpModel>>? _followUpsSub;
  StreamSubscription<List<QuoteModel>>? _quotesSub;
  StreamSubscription<List<PaymentModel>>? _paymentsSub;
  StreamSubscription<List<InstallationModel>>? _installationsSub;
  StreamSubscription<AppSettingsModel>? _settingsSub;
  final Set<String> _seenClients = {};
  final Set<String> _seenEstimates = {};
  final Set<String> _seenFollowUps = {};
  bool _initialClients = true;
  bool _initialEstimates = true;
  bool _initialFollowUps = true;
  DateTime? _lastLocalWrite;
  bool get _recentLocalWrite =>
      _lastLocalWrite != null &&
      DateTime.now().difference(_lastLocalWrite!).inSeconds < 8;
  bool _loading = true;
  String? _error;

  List<ClientModel> _clients = [];
  List<FollowUpModel> _followUps = [];
  List<QuoteModel> _quotes = [];
  List<PaymentModel> _payments = [];
  List<InstallationModel> _installations = [];
  List<EstimateRecord> _estimates = [];
  AppSettingsModel? _settings;

  DataHub(this._db, this._fire);

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

  /// Starts real-time Firestore sync for clients + quotations.
  /// Must be called AFTER the user is authenticated (security rules require
  /// an authenticated session, otherwise the listener errors and dies).
  Future<void> startSync() async {
    if (_clientsSub != null) return;
    final master = await MasterData.load();
    _clientsSub = _fire.watchClients().listen(_onClients, onError: _onError);
    _estimatesSub =
        _fire.watchEstimates(master).listen(_onEstimates, onError: _onError);
    _followUpsSub =
        _fire.watchFollowUps().listen(_onFollowUps, onError: _onError);
    _quotesSub = _fire.watchQuotes().listen(_onQuotes, onError: _onError);
    _paymentsSub =
        _fire.watchPayments().listen(_onPayments, onError: _onError);
    _installationsSub = _fire
        .watchInstallations()
        .listen(_onInstallations, onError: _onError);
    _settingsSub = _fire.watchSettings().listen(_onSettings, onError: _onError);
  }

  void stopSync() {
    _clientsSub?.cancel();
    _estimatesSub?.cancel();
    _followUpsSub?.cancel();
    _quotesSub?.cancel();
    _paymentsSub?.cancel();
    _installationsSub?.cancel();
    _settingsSub?.cancel();
    _clientsSub = null;
    _estimatesSub = null;
    _followUpsSub = null;
    _quotesSub = null;
    _paymentsSub = null;
    _installationsSub = null;
    _settingsSub = null;
    _clients = [];
    _estimates = [];
    _followUps = [];
    _quotes = [];
    _payments = [];
    _installations = [];
    notifyListeners();
  }

  void _onFollowUps(List<FollowUpModel> list) {
    final ids = list.map((f) => f.id).toSet();
    if (!_initialFollowUps && !_recentLocalWrite) {
      for (final f in list) {
        if (!_seenFollowUps.contains(f.id)) {
          NotificationService.instance.showAlert(
              'New follow-up', '${f.dateFormatted} • ${f.timeFormatted}');
        }
      }
    }
    _seenFollowUps
      ..clear()
      ..addAll(ids);
    _initialFollowUps = false;
    _followUps = list;
    _sortFollowUps();
    notifyListeners();
  }

  void _onQuotes(List<QuoteModel> list) {
    _quotes = list..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    notifyListeners();
  }

  void _onPayments(List<PaymentModel> list) {
    _payments = list;
    notifyListeners();
  }

  void _onInstallations(List<InstallationModel> list) {
    _installations = list;
    notifyListeners();
  }

  void _onSettings(AppSettingsModel s) {
    _settings = s;
    notifyListeners();
  }

  void _onClients(List<ClientModel> list) {
    final ids = list.map((c) => c.id).toSet();
    if (!_initialClients && !_recentLocalWrite) {
      for (final c in list) {
        if (!_seenClients.contains(c.id)) {
          NotificationService.instance.showAlert('New client added', c.name);
        }
      }
    }
    _seenClients
      ..clear()
      ..addAll(ids);
    _initialClients = false;
    _clients = list..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _loading = false;
    _error = null;
    notifyListeners();
  }

  void _onEstimates(List<EstimateRecord> list) {
    final ids = list.map((e) => e.id).toSet();
    if (!_initialEstimates && !_recentLocalWrite) {
      for (final e in list) {
        if (!_seenEstimates.contains(e.id)) {
          NotificationService.instance.showAlert('New quotation',
              '${e.data.estimateNumber} • ${e.data.leadName}');
        }
      }
    }
    _seenEstimates
      ..clear()
      ..addAll(ids);
    _initialEstimates = false;
    _estimates = list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void _onError(Object e) {
    _error = e.toString();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadAll() async {
    // Firestore is now the source of truth for all data; the lists are
    // populated by startSync() once the user is authenticated.
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _clientsSub?.cancel();
    _estimatesSub?.cancel();
    super.dispose();
  }

  // ── Clients ───────────────────────────────────────────────────

  Future<void> addClient(ClientModel client) async {
    _lastLocalWrite = DateTime.now();
    await _fire.saveClient(client); // the listener refreshes _clients
  }

  Future<void> updateClient(ClientModel client) async {
    _lastLocalWrite = DateTime.now();
    await _fire.saveClient(client);
  }

  Future<void> deleteClient(String id) async {
    await _fire.deleteClient(id);
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
    _lastLocalWrite = DateTime.now();
    await _fire.saveFollowUp(followUp);
    _scheduleReminder(followUp);
  }

  Future<void> updateFollowUp(FollowUpModel followUp) async {
    _lastLocalWrite = DateTime.now();
    await _fire.saveFollowUp(followUp);
    _scheduleReminder(followUp);
  }

  Future<void> deleteFollowUp(String id) async {
    await _fire.deleteFollowUp(id);
    NotificationService.instance.cancelFollowUp(id.hashCode & 0x7fffffff);
  }

  /// Schedules (or cancels) the local reminder for a follow-up.
  void _scheduleReminder(FollowUpModel f) {
    final id = f.id.hashCode & 0x7fffffff;
    final parts = f.time.split(':');
    final h = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 9) : 9;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final due = DateTime(f.date.year, f.date.month, f.date.day, h, m);
    if (f.status == 'pending' && due.isAfter(DateTime.now())) {
      NotificationService.instance.scheduleFollowUpReminder(
        id: id,
        title: 'Follow-up reminder',
        body: (f.note != null && f.note!.isNotEmpty)
            ? f.note!
            : 'You have a follow-up due now.',
        scheduledDate: due,
      );
    } else {
      NotificationService.instance.cancelFollowUp(id);
    }
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
    await _fire.saveQuote(quote);
  }

  QuoteModel? getQuoteForClient(String clientId) {
    final qs = _quotes.where((q) => q.clientId == clientId).toList();
    if (qs.isEmpty) return null;
    qs.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return qs.first;
  }

  Future<void> deleteQuote(String id) async {
    await _fire.deleteQuote(id);
  }

  // ── Payments ──────────────────────────────────────────────────

  Future<void> savePayment(PaymentModel payment) async {
    await _fire.savePayment(payment);
  }

  PaymentModel? getPaymentForClient(String clientId) {
    final idx = _payments.indexWhere((p) => p.clientId == clientId);
    return idx >= 0 ? _payments[idx] : null;
  }

  // ── Installations ──────────────────────────────────────────────

  Future<void> saveInstallation(InstallationModel installation) async {
    await _fire.saveInstallation(installation);
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
    await _fire.saveSettings(settings);
    _settings = settings;
    notifyListeners();
  }

  // ── Estimates ───────────────────────────────────────────────────

  Future<EstimateRecord> addEstimate(EstimateModel estimate) async {
    _lastLocalWrite = DateTime.now();
    return _fire.saveEstimate(estimate); // the listener refreshes _estimates
  }

  /// Updates a previously-saved estimate (no duplicate row).
  Future<EstimateRecord> updateEstimate(
      EstimateRecord existing, EstimateModel estimate) async {
    _lastLocalWrite = DateTime.now();
    return _fire.saveEstimate(estimate,
        id: existing.id, createdAt: existing.createdAt);
  }

  int get estimateCount => _estimates.length;

  Future<EstimateRecord?> updateEstimatePdfPath(
      String recordId, String? pdfPath) async {
    // PDF path is device-local; not synced.
    final i = _estimates.indexWhere((r) => r.id == recordId);
    if (i != -1 && pdfPath != null) {
      _estimates[i] = _estimates[i].copyWith(pdfPath: pdfPath);
      notifyListeners();
      return _estimates[i];
    }
    return null;
  }

  Future<void> deleteEstimate(String recordId) async {
    await _fire.deleteEstimate(recordId);
    _estimates.removeWhere((r) => r.id == recordId);
    notifyListeners();
  }

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
