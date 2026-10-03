import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/data_hub.dart';
import 'add_edit_client_screen.dart';
import 'client_detail_screen.dart';

/// Client / lead list — exact design: navy header + search + chips + cards.
class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterArea = 'all';
  String? _filterStatus;
  bool _showFilters = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _applyFilters(DataHub hub) {
    var clients = <dynamic>[];
    if (_searchQuery.isNotEmpty) {
      clients = hub.searchClients(_searchQuery);
    } else {
      clients = hub.clients;
    }
    if (_filterArea != 'all') {
      clients = clients
          .where((c) => c.area == _filterArea || c.displayArea == _filterArea)
          .toList();
    }
    if (_filterStatus != null) {
      clients = clients.where((c) => c.status == _filterStatus).toList();
    }
    return clients;
  }

  int _countByArea(DataHub hub, String area) {
    if (area == 'all') return hub.clients.length;
    return hub.clients
        .where((c) => c.area == area || c.displayArea == area)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final filtered = _applyFilters(hub);

    return Scaffold(
      backgroundColor: GSColors.sky100,
      body: Column(
        children: [
          // ── Navy header ────────────────────────────────────────
          _buildHeader(context),
          // ── Search bar (overlapping) ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Transform.translate(
              offset: const Offset(0, -14),
              child: _buildSearchBar(),
            ),
          ),
          // ── Filter chips (toggled by filter button) ─────────────
          if (_showFilters)
            Transform.translate(
              offset: const Offset(0, -10),
              child: _buildFilterChips(hub),
            ),
          // ── Results count + sort ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${filtered.length} clients',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GSColors.ink.withValues(alpha: 0.55))),
                Row(
                  children: [
                    Text('Sort by Date',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: GSColors.ink.withValues(alpha: 0.55))),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 14, color: GSColors.ink.withValues(alpha: 0.55)),
                  ],
                ),
              ],
            ),
          ),
          // ── Client list ─────────────────────────────────────────
          Expanded(
            child: hub.loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final client = filtered[i];
                          return _ClientCard(
                            client: client,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) =>
                                      ClientDetailScreen(client: client)));
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071440), Color(0xFF0B1F5C)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF9B417), Color(0xFFFFCA28), Color(0xFFFFE082)],
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0x40F9B417), blurRadius: 12, spreadRadius: 1),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF050E26),
                  ),
                  child: const Icon(Icons.solar_power_rounded,
                      color: GSColors.gold500, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clients',
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3)),
                    Text('Bhavnagar & Talaja',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xBFEAF4FF))),
                  ],
                ),
              ),
              // Add client button
              InkWell(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddEditClientScreen()),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF9B417), Color(0xFFFFCA28), Color(0xFFFFE082)],
                    ),
                    boxShadow: [
                      BoxShadow(color: GSColors.gold500.withValues(alpha: 0.45), blurRadius: 12),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Color(0xFF050E26), size: 26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
        boxShadow: const [BoxShadow(color: Color(0x1A1E3A8A), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search by name, phone, area...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F1B3D)),
            ),
          ),
          const SizedBox(width: 10),
          // Filter button — toggles the filter chips
          InkWell(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Container(
              margin: const EdgeInsets.only(right: 2),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showFilters ? const Color(0xFFFFF3CD) : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _showFilters
                        ? const Color(0xFFFFCA28)
                        : const Color(0xCCDBEAFE)),
              ),
              child: Icon(
                _showFilters ? Icons.filter_alt_rounded : Icons.tune_rounded,
                size: 17,
                color: _showFilters ? const Color(0xFFB45309) : const Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(DataHub hub) {
    return Column(
      children: [
        // Area chips
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chipLabel('Area'),
              _areaChip('All', 'all', hub),
              _areaChip('Talaja', GSArea.talaja, hub),
              _areaChip('Bhavnagar', GSArea.bhavnagar, hub),
              _areaChip('Villages', GSArea.village, hub),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Status chips
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chipLabel('Status'),
              _statusChip('All Statuses', null),
              ...GSClientStatus.all.map((s) => _statusChip(GSClientStatus.labelOf(s), s)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chipLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Align(
        alignment: Alignment.center,
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF94A3B8))),
      ),
    );
  }

  Widget _areaChip(String label, String value, DataHub hub) {
    final selected = _filterArea == value;
    final count = _countByArea(hub, value);
    return _chip(
      label: '$label ($count)',
      selected: selected,
      onTap: () => setState(() => _filterArea = value),
      color: GSColors.blue500,
    );
  }

  Widget _statusChip(String label, String? value) {
    final selected = _filterStatus == value;
    final statusColor = value == null ? GSColors.gold500 : _statusColor(value);
    return _chip(
      label: label,
      selected: selected,
      onTap: () => setState(() => _filterStatus = value),
      color: statusColor,
      showDot: value != null && !selected,
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
    bool showDot = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [Color(0xFFF9B417), Color(0xFFFFB300)])
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFCA28)
                  : color.withValues(alpha: 0.35),
            ),
            boxShadow: selected
                ? [BoxShadow(color: GSColors.gold500.withValues(alpha: 0.3), blurRadius: 6)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDot) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? const Color(0xFF050E26) : color)),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case GSClientStatus.newLead:
        return const Color(0xFF2196F3);
      case GSClientStatus.contacted:
      case GSClientStatus.siteVisit:
        return const Color(0xFF9C27B0);
      case GSClientStatus.quoted:
        return const Color(0xFFFF9800);
      case GSClientStatus.booked:
        return const Color(0xFFF44336);
      case GSClientStatus.installed:
      case GSClientStatus.subsidized:
        return GSColors.green600;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search_rounded, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 10),
          Text('No clients found',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F1B3D))),
          SizedBox(height: 2),
          Text('Try adjusting your search or filters.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

/// Client card — exact design.
class _ClientCard extends StatelessWidget {
  final dynamic client;
  final VoidCallback onTap;

  const _ClientCard({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final letter = client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';
    final statusColor = _statusColor(client.status);
    final statusLabel = GSClientStatus.labelOf(client.status).toUpperCase();
    final pkg = client.preferredPackage != 'not-sure' ? client.preferredPackage : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xB3DBEAFE)),
          boxShadow: const [BoxShadow(color: Color(0x0D1E3A8A), blurRadius: 8)],
        ),
        child: Row(
          children: [
            // Avatar with status ring
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0B1F5C),
                    boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
                  ),
                  child: Center(
                    child: Text(letter,
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Middle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(client.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF050E26))),
                      ),
                      if (pkg != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('$pkg kW',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${client.phone}  •  ${client.displayArea}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                            ),
                            const SizedBox(width: 5),
                            Text(statusLabel,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(client.createdAtFormatted,
                          style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
                    ],
                  ),
                ],
              ),
            ),
            // Chevron
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case GSClientStatus.newLead:
        return const Color(0xFF2196F3);
      case GSClientStatus.contacted:
      case GSClientStatus.siteVisit:
        return const Color(0xFF9C27B0);
      case GSClientStatus.quoted:
        return const Color(0xFFFF9800);
      case GSClientStatus.booked:
        return const Color(0xFFF44336);
      case GSClientStatus.installed:
      case GSClientStatus.subsidized:
        return GSColors.green600;
      default:
        return Colors.grey;
    }
  }
}