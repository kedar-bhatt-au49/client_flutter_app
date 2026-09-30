import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gs_card.dart';
import '../../core/widgets/status_chip.dart';
import '../../providers/data_hub.dart';
import 'add_edit_client_screen.dart';
import 'client_detail_screen.dart';

/// Client / lead list — search + filter chips + card list.
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

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();

    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      appBar: AppBar(
        title: const Text('Clients'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const AddEditClientScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Client'),
      ),
      body: Column(
        children: [
          // ── Search ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name, phone, area...',
                prefixIcon:
                    const Icon(Icons.search, color: GSColors.navy700),
                filled: true,
                fillColor: GSColors.white,
              ),
              style: GSTextStyles.bodyLarge,
            ),
          ),

          // ── Area filter chips ───────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filterArea == 'all',
                  onTap: () => setState(() => _filterArea = 'all'),
                ),
                ...GSArea.all.map((area) => _FilterChip(
                      label: area,
                      selected: _filterArea == area,
                      onTap: () => setState(() => _filterArea = area),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Status filter chips ─────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All Statuses',
                  selected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                ...GSClientStatus.all.map((status) => _FilterChip(
                      label: GSClientStatus.labelOf(status),
                      selected: _filterStatus == status,
                      onTap: () => setState(() => _filterStatus = status),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Client list ─────────────────────────────────────────
          Expanded(
            child: hub.loading
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      final filtered =
                          _applyFilters(hub);
                      if (filtered.isEmpty) {
                        return const EmptyState(
                          title: 'No clients found',
                          message:
                              'Try adjusting your search or filters.',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                color: selected ? GSColors.navy900 : GSColors.ink,
                fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: GSColors.white,
        selectedColor: GSColors.gold500,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? GSColors.gold500 : GSColors.ink.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final dynamic client;
  final VoidCallback onTap;

  const _ClientCard({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GsCard(
      padding: const EdgeInsets.all(16),
      goldAccent: client.status == 'booked' || client.status == 'installed',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: GSColors.navy700.withValues(alpha: 0.15),
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                style: GSTextStyles.headlineMedium.copyWith(
                    color: GSColors.navy700, fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name,
                      style: GSTextStyles.headlineSmall
                          .copyWith(color: GSColors.navy900)),
                  const SizedBox(height: 2),
                  Text('${client.phone} · ${client.displayArea}',
                      style: GSTextStyles.bodySmall
                          .copyWith(color: GSColors.ink.withValues(alpha: 0.7))),
                  if (client.preferredPackage != 'not-sure')
                    Text('Package: ${client.preferredPackage} kW',
                        style: GSTextStyles.bodySmall.copyWith(
                            color: GSColors.blue500, fontSize: 11)),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      GSStatusChip(status: client.status),
                      const SizedBox(width: 8),
                      Text(
                        client.createdAtFormatted,
                        style: GSTextStyles.bodySmall
                            .copyWith(color: GSColors.ink.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trailing icon
            const Icon(Icons.chevron_right,
                color: GSColors.ink, size: 20),
          ],
        ),
      ),
    );
  }
}
