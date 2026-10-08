import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/widgets/image_viewer.dart';
import '../../models/client.dart';
import '../../models/installation.dart';
import '../../providers/data_hub.dart';
import '../../services/storage_service.dart';

/// Installation tracking — exact design: navy header, stage banner,
/// timeline, photos, warranty, notes, fixed bottom bar.
class InstallationScreen extends StatefulWidget {
  final ClientModel? client;

  const InstallationScreen({super.key, this.client});

  @override
  State<InstallationScreen> createState() => _InstallationScreenState();
}

class _InstallationScreenState extends State<InstallationScreen> {
  static const _gold = Color(0xFFF9B417);
  static const _goldLight = Color(0xFFFFCA40);
  static const _goldDark = Color(0xFFD9980B);
  static const _navy900 = Color(0xFF071440);
  static const _navy800 = Color(0xFF0B1F5C);
  static const _sky = Color(0xFFEAF4FF);
  static const _skyBorder = Color(0xFFDBEAFE);
  static const _dark = Color(0xFF0F1B3D);
  static const _slate = Color(0xFF627193);
  static const _green = Color(0xFF059669);
  static const _greenLight = Color(0xFF10B981);
  static const _blue = Color(0xFF1E5BD8);

  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final clientId = widget.client?.id;
    final installation =
        clientId != null ? hub.getInstallationForClient(clientId) : null;

    return Scaffold(
      backgroundColor: _sky,
      body: installation == null
          ? _buildEmptyState(context, hub)
          : Column(
              children: [
                _buildHeader(context, hub, installation),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStageBanner(installation),
                        const SizedBox(height: 16),
                        _buildTimeline(context, hub, installation),
                        const SizedBox(height: 16),
                        _buildPhotos(context, hub, installation),
                        const SizedBox(height: 16),
                        _buildWarranty(installation),
                        const SizedBox(height: 16),
                        _buildNotes(context, hub, installation),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(context, hub, installation),
              ],
            ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, DataHub hub,
      InstallationModel installation) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_navy900, _navy800],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Installation',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.4)),
                        SizedBox(width: 6),
                        _PulseDot(),
                      ],
                    ),
                    Text(widget.client?.name ?? 'Client',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xCCD0E6FF))),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _addPhoto(context, hub, installation),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_gold, _goldLight],
                    ),
                    boxShadow: [
                      BoxShadow(color: _gold.withValues(alpha: 0.4), blurRadius: 10),
                    ],
                  ),
                  child:
                      const Icon(Icons.photo_camera_rounded, color: _navy900, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, DataHub hub) {
    return Column(
      children: [
        _buildHeader(context, hub,
            InstallationModel(id: '', clientId: '')),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _sky,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _skyBorder),
                    ),
                    child: const Icon(Icons.construction_rounded,
                        size: 40, color: _navy800),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.client == null
                        ? 'No installations yet'
                        : 'No installation tracking\nstarted for ${widget.client!.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _navy900),
                  ),
                  if (widget.client != null) ...[
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () => _startTracking(context, hub),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_gold, _goldLight]),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                                color: _gold.withValues(alpha: 0.35),
                                blurRadius: 12),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                size: 18, color: _navy900),
                            SizedBox(width: 6),
                            Text('Start Tracking',
                                style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _navy900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startTracking(BuildContext context, DataHub hub) {
    if (widget.client == null) return;
    final install = InstallationModel(
      id: hub.generateId(),
      clientId: widget.client!.id,
      stage: GSInstallStage.materialsDispatched,
      installDate: DateTime.now(),
      warrantyExpiry: WarrantyExpiry.fromInstallDate(DateTime.now()),
    );
    hub.saveInstallation(install);
    setState(() {});
  }

  // ── Stage banner ───────────────────────────────────────────────
  Widget _buildStageBanner(InstallationModel installation) {
    final stages = GSInstallStage.all;
    final currentIdx = installation.currentStageIndex;
    final isComplete = installation.isComplete;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy800, _navy900, _navy900],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x4D071440), blurRadius: 25, offset: Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border:
                            Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.construction_rounded,
                          size: 16, color: _goldLight),
                    ),
                    const SizedBox(width: 8),
                    const Text('CURRENT STAGE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Color(0xCCD0E6FF))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isComplete ? _greenLight : _gold)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: (isComplete ? _greenLight : _gold)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isComplete ? _greenLight : _goldLight,
                              boxShadow: [
                                BoxShadow(
                                    color: (isComplete
                                            ? _greenLight
                                            : _goldLight)
                                        .withValues(alpha: 0.7),
                                    blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(isComplete ? 'COMPLETED ✓' : 'IN PROGRESS',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: isComplete ? _greenLight : _goldLight)),
                        ],
                      ),
                    ),
                  ],
                ),
                // Stage title
                const SizedBox(height: 12),
                Text(GSInstallStage.labelOf(installation.stage),
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(
                  isComplete
                      ? 'All 5 steps complete'
                      : 'Step ${currentIdx + 1} of 5 • ${currentIdx < stages.length - 1 ? '${GSInstallStage.labelOf(stages[currentIdx + 1])} next' : 'Final step'}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xCCD0E6FF)),
                ),
                // Stepper
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(stages.length, (i) {
                    final done = i < currentIdx || isComplete;
                    final current = i == currentIdx && !isComplete;
                    return _stepperDot(i, done, current, stages.length);
                  }),
                ),
                // Bottom stats
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Installed on',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xB3D0E6FF))),
                            const SizedBox(height: 2),
                            Text(
                              installation.installDate != null
                                  ? DateFormat('dd MMM yyyy')
                                      .format(installation.installDate!)
                                  : '—',
                              style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Warranty till',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xB3D0E6FF))),
                            const SizedBox(height: 2),
                            Text(
                              installation.warrantyExpiry.om > 0
                                  ? '${installation.warrantyExpiry.om}'
                                  : '—',
                              style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _goldLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperDot(int index, bool done, bool current, int total) {
    const labels = ['Dispatch', 'Fitting', 'PGVCL', 'Meter', 'Subsidy'];
    final label = labels[index];

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_gold, _goldLight])
                : null,
            color: done ? null : Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: current
                  ? _goldLight
                  : (done ? _goldLight : Colors.white.withValues(alpha: 0.25)),
              width: current ? 3 : 1,
            ),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 14, color: _navy900)
              : Center(
                  child: Text('${index + 1}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: current
                              ? _goldLight
                              : Colors.white.withValues(alpha: 0.6))),
                ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: done || current ? FontWeight.w600 : FontWeight.w400,
                color: done || current
                    ? _goldLight
                    : Colors.white.withValues(alpha: 0.5))),
      ],
    );
  }

  // ── Timeline card ──────────────────────────────────────────────
  Widget _buildTimeline(
      BuildContext context, DataHub hub, InstallationModel installation) {
    final stages = GSInstallStage.all;
    final currentIdx = installation.currentStageIndex;
    final isComplete = installation.isComplete;
    final nextStage =
        !isComplete && currentIdx < stages.length - 1 ? stages[currentIdx + 1] : null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.timeline_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Progress Timeline',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text('On track',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _green)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(stages.length, (i) {
            final stage = stages[i];
            final done = i < currentIdx || isComplete;
            final current = i == currentIdx && !isComplete;
            final isLast = i == stages.length - 1;
            return _timelineRow(
              index: i,
              label: GSInstallStage.labelOf(stage),
              done: done,
              current: current,
              isLast: isLast,
              installDate: installation.installDate,
            );
          }),
          const SizedBox(height: 10),
          if (nextStage != null)
            InkWell(
              onTap: () => _advanceStage(hub, installation, nextStage),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [_gold, _goldLight],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                        color: _gold.withValues(alpha: 0.3), blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Mark ${GSInstallStage.labelOf(nextStage)} Complete',
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _navy900)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 14, color: _navy900.withValues(alpha: 0.8)),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: _green),
                  SizedBox(width: 6),
                  Text('All stages complete • Subsidy ₹78,000 credited',
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _green)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _timelineRow({
    required int index,
    required String label,
    required bool done,
    required bool current,
    required bool isLast,
    DateTime? installDate,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_gold, _goldLight])
                : null,
            color: done
                ? null
                : (current
                    ? _navy800
                    : const Color(0xFFE2E8F0)),
            border: Border.all(
              color: current
                  ? _gold
                  : (done ? _goldLight : Colors.transparent),
              width: current ? 2 : 1,
            ),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 14, color: _navy900)
              : Center(
                  child: Text('${index + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: current
                              ? Colors.white
                              : const Color(0xFF94A3B8))),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(label,
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight:
                                  done || current ? FontWeight.w700 : FontWeight.w500,
                              color: done || current ? _dark : _slate)),
                    ),
                    if (current) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Current',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? 'Done ${installDate != null ? DateFormat('dd MMM').format(installDate) : ''}'
                      : (current ? 'In progress now' : 'Upcoming'),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: done ? _green : const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _advanceStage(DataHub hub, InstallationModel installation, String next) {
    final updated = installation.copyWith(
      stage: next,
      installDate: installation.installDate ?? DateTime.now(),
      warrantyExpiry: installation.installDate != null
          ? installation.warrantyExpiry
          : WarrantyExpiry.fromInstallDate(DateTime.now()),
    );
    hub.saveInstallation(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${GSInstallStage.labelOf(next)} marked complete')),
    );
  }

  // ── Photos card ────────────────────────────────────────────────
  Widget _buildPhotos(
      BuildContext context, DataHub hub, InstallationModel installation) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.photo_library_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Installation Photos',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _sky,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _skyBorder.withValues(alpha: 0.6)),
                ),
                child: Text('${installation.photos.length} photos',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _slate)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (installation.photos.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xB3F4F9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _skyBorder),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_outlined,
                      size: 16, color: _slate),
                  SizedBox(width: 6),
                  Text('No photos uploaded yet',
                      style: TextStyle(fontSize: 12, color: _slate)),
                ],
              ),
            )
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                ...installation.photos.map((p) => _photoTile(p)),
                _addPhotoTile(context, hub, installation),
              ],
            ),
        ],
      ),
    );
  }

  Widget _photoTile(InstallationPhoto photo) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ImageViewerScreen(url: photo.url, title: 'Photo'),
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFFDBEAFE),
                child: Icon(Icons.photo_camera_rounded,
                    size: 20,
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.5)),
              ),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _navy900.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_shortStage(photo.stage),
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortStage(String stage) {
    switch (stage) {
      case 'materials-dispatched':
        return 'Dispatch';
      case 'fitting':
        return 'Fitting';
      case 'pvcl-inspection':
        return 'PGVCL';
      case 'net-meter':
        return 'Meter';
      case 'subsidy-credited':
        return 'Subsidy';
      default:
        return stage;
    }
  }

  Widget _addPhotoTile(
      BuildContext context, DataHub hub, InstallationModel installation) {
    return InkWell(
      onTap: () => _addPhoto(context, hub, installation),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x1AF9B417),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, size: 22, color: _goldDark),
            SizedBox(height: 4),
            Text('+ Add',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _navy900)),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhoto(BuildContext context, DataHub hub,
      InstallationModel installation) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _navy900),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_rounded, color: _navy900),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ImagePicker()
          .pickImage(source: source, imageQuality: 70, maxWidth: 1600);
      if (file == null) return;
      messenger.showSnackBar(const SnackBar(content: Text('Uploading…')));
      final bytes = await file.readAsBytes();
      final url = await StorageService.instance.uploadBytes(
          bytes, file.name, folder: 'installations/${installation.clientId}');
      final updated = installation.copyWith(
        photos: [
          ...installation.photos,
          InstallationPhoto(
            id: hub.generateId(),
            url: url,
            stage: installation.stage,
            uploadedAt: DateTime.now(),
          ),
        ],
      );
      await hub.saveInstallation(updated);
      messenger.showSnackBar(const SnackBar(content: Text('Photo uploaded')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  // ── Warranty card ──────────────────────────────────────────────
  Widget _buildWarranty(InstallationModel installation) {
    final w = installation.warrantyExpiry;
    final hasWarranty = w.om > 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.shield_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Warranty Coverage',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
              ),
              if (hasWarranty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Text('Active',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _green)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasWarranty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xB3F4F9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _skyBorder),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: _slate),
                  SizedBox(width: 6),
                  Text('Warranty calculated after install date',
                      style: TextStyle(fontSize: 12, color: _slate)),
                ],
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _warrantyBadge('OM / Workmanship', w.om.toString(),
                    const Color(0xFF1E5BD8), const Color(0xFFDBEAFE)),
                _warrantyBadge('Solar Panels', w.panel.toString(),
                    _green, const Color(0xFFA7F3D0)),
                _warrantyBadge('Performance', w.performance.toString(),
                    _goldDark, const Color(0xFFFDE68A)),
                _warrantyBadge('Inverter', w.inverter.toString(),
                    _navy800, const Color(0xFFC7D2FE)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _warrantyBadge(String label, String value, Color color, Color tint) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: _slate)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(width: 3),
              Text('yrs',
                  style: TextStyle(fontSize: 10, color: _slate)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Notes card ─────────────────────────────────────────────────
  Widget _buildNotes(
      BuildContext context, DataHub hub, InstallationModel installation) {
    _notesController.text = installation.notes ?? '';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.edit_note_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Installation Notes',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Optional',
                    style: TextStyle(
                        fontSize: 10, color: _slate)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              const Positioned(
                left: 12,
                top: 12,
                child:
                    Icon(Icons.edit_note_rounded, size: 18, color: _slate),
              ),
              TextField(
                controller: _notesController,
                maxLines: 3,
                minLines: 3,
                style: const TextStyle(
                    fontSize: 12, color: _dark, height: 1.5),
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText:
                      'Roof access note, meter room location, grid status...',
                  hintStyle: TextStyle(
                      fontSize: 12,
                      color: _slate.withValues(alpha: 0.7),
                      height: 1.5),
                  filled: true,
                  fillColor: _sky,
                  contentPadding:
                      const EdgeInsets.fromLTRB(40, 12, 12, 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _skyBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _navy800, width: 1.2),
                  ),
                ),
                onChanged: (v) {
                  hub.saveInstallation(installation.copyWith(notes: v));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────
  Widget _buildBottomBar(
      BuildContext context, DataHub hub, InstallationModel installation) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: _skyBorder)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x26F9B417), blurRadius: 25, offset: Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                hub.saveInstallation(installation.copyWith(
                    notes: _notesController.text.trim().isNotEmpty
                        ? _notesController.text.trim()
                        : null));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Changes saved to client record')),
                );
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [_gold, _goldLight, _goldDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: _gold.withValues(alpha: 0.35), blurRadius: 16),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 20, color: _navy900),
                    SizedBox(width: 8),
                    Text('Update & Save',
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _navy900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Changes auto-sync to client record',
                style: TextStyle(fontSize: 11, color: _slate)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D0F1B3D), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _iconTile(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _sky,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 19, color: _blue),
    );
  }
}

/// Pulsing gold dot in header.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1400), vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFCA40),
          boxShadow: [BoxShadow(color: Color(0xFFFFCA40), blurRadius: 8)],
        ),
      ),
    );
  }
}