import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/gs_button.dart';
import '../../core/widgets/gs_card.dart';
import '../../models/client.dart';
import '../../models/installation.dart';
import '../../providers/data_hub.dart';

/// Installation stage tracker — timeline, photos, warranty, notes.
class InstallationScreen extends StatefulWidget {
  final ClientModel? client;

  const InstallationScreen({super.key, this.client});

  @override
  State<InstallationScreen> createState() => _InstallationScreenState();
}

class _InstallationScreenState extends State<InstallationScreen> {
  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final clientId = widget.client?.id;
    final installation = clientId != null
        ? hub.getInstallationForClient(clientId)
        : null;

    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      appBar: AppBar(title: const Text('Installation Tracking')),
      body: installation == null
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTimeline(installation),
                  const SizedBox(height: 16),
                  _buildPhotos(installation),
                  const SizedBox(height: 16),
                  _buildWarranty(installation),
                  const SizedBox(height: 16),
                  _buildNotes(installation, hub),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 64, color: GSColors.navy700),
            const SizedBox(height: 16),
            Text(
              widget.client == null
                  ? 'No installations yet'
                  : 'No installation tracking started for ${widget.client!.name}',
              style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900),
              textAlign: TextAlign.center,
            ),
            if (widget.client != null) ...[
              const SizedBox(height: 24),
              GsButton(
                text: 'Start Tracking',
                onPressed: () => _startTracking(context),
                icon: Icons.play_arrow,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startTracking(BuildContext context) {
    final hub = context.read<DataHub>();
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

  Widget _buildTimeline(InstallationModel installation) {
    final stages = GSInstallStage.all;

    return GsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Installation Timeline',
              style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
          const SizedBox(height: 16),
          Column(
            children: List.generate(stages.length, (i) {
              final stage = stages[i];
              final isComplete = i <= installation.currentStageIndex;
              final isCurrent = i == installation.currentStageIndex;
              final isLast = i == stages.length - 1;

              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isComplete ? GSGradients.sun : null,
                          color: isComplete
                              ? null
                              : GSColors.ink.withValues(alpha: 0.15),
                          border: Border.all(
                            color: isCurrent
                                ? GSColors.gold500
                                : (isComplete
                                    ? GSColors.navy900
                                    : GSColors.ink.withValues(alpha: 0.2)),
                            width: isCurrent ? 3 : 2,
                          ),
                        ),
                        child: isComplete
                            ? const Icon(Icons.check, size: 16, color: GSColors.navy900)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(GSInstallStage.labelOf(stage),
                                style: GSTextStyles.bodyMediumSemiBold.copyWith(
                                    color: isComplete
                                        ? GSColors.navy900
                                        : GSColors.ink.withValues(alpha: 0.5))),
                            if (installation.installDate != null && i == 1)
                              Text(
                                  'Started: ${installation.installDateFormatted}',
                                  style: GSTextStyles.bodySmall
                                      .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 24,
                          color: isComplete
                              ? GSColors.gold500
                              : GSColors.ink.withValues(alpha: 0.1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ),
          if (!installation.isComplete)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _StageUpdateButtons(
                installation: installation,
                onStageChanged: () {
                  setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotos(InstallationModel installation) {
    return GsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Installation Photos',
              style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
          const SizedBox(height: 12),
          if (installation.photos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No photos uploaded yet',
                  style: TextStyle(color: GSColors.ink)),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...installation.photos.map((p) => _PhotoThumbnail(photo: p)),
              if (installation.photos.isNotEmpty)
                _AddPhotoButton(
                  stage: installation.stage,
                  onAdded: () => setState(() {}),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarranty(InstallationModel installation) {
    final w = installation.warrantyExpiry;
    return GsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Warranty Expiry',
              style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
          const SizedBox(height: 12),
          if (w.om == 0)
            const Text('Not calculated',
                style: TextStyle(color: GSColors.ink))
          else
            Wrap(
              spacing: 16,
              children: [
                _WarrantyBadge('OM / Workmanship\n${w.om}', GSColors.blue500),
                _WarrantyBadge('Solar Panels\n${w.panel} yrs', GSColors.green600),
                _WarrantyBadge('Performance\n${w.performance} yrs', GSColors.gold500),
                _WarrantyBadge('Inverter\n${w.inverter} yrs', GSColors.navy700),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNotes(InstallationModel installation, DataHub hub) {
    final controller = TextEditingController(text: installation.notes ?? '');
    return GsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes',
              style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Add installation notes...',
              hintStyle: GSTextStyles.bodyMedium.copyWith(color: GSColors.ink.withValues(alpha: 0.4)),
            ),
            maxLines: 4,
            onChanged: (v) {
              // Auto-save after debounce could be added
            },
            onFieldSubmitted: (v) {
              hub.saveInstallation(installation.copyWith(notes: v));
            },
          ),
        ],
      ),
    );
  }
}

class _StageUpdateButtons extends StatelessWidget {
  final InstallationModel installation;
  final VoidCallback onStageChanged;

  const _StageUpdateButtons({required this.installation, required this.onStageChanged});

  @override
  Widget build(BuildContext context) {
    final hub = context.read<DataHub>();
    final currentIdx = installation.currentStageIndex;
    final stages = GSInstallStage.all;

    return Wrap(
      spacing: 8,
      children: List.generate(stages.length - currentIdx, (i) {
        final targetIdx = currentIdx + i;
        final stage = stages[targetIdx];
        if (stage == installation.stage) {
          return const SizedBox.shrink();
        }
        return GsButton(
          text: GSInstallStage.labelOf(stage),
          onPressed: () {
            final updated = installation.copyWith(
              stage: stage,
              installDate: installation.installDate ?? DateTime.now(),
              warrantyExpiry: installation.installDate != null
                  ? installation.warrantyExpiry
                  : WarrantyExpiry.fromInstallDate(DateTime.now()),
            );
            hub.saveInstallation(updated);
            onStageChanged();
          },
          height: 36,
        );
      }),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final dynamic photo;

  const _PhotoThumbnail({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: GSColors.navy700.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: AssetImage('assets/images/solar_panel_placeholder.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// Placeholder image path — will be provided by asset
class _AddPhotoButton extends StatelessWidget {
  final String stage;
  final VoidCallback onAdded;

  const _AddPhotoButton({required this.stage, required this.onAdded});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add photo for $stage (coming soon)')),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: GSColors.gold500.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GSColors.gold500, style: BorderStyle.none),
        ),
        child: const Icon(Icons.add_a_photo, color: GSColors.gold500, size: 28),
      ),
    );
  }
}

class _WarrantyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _WarrantyBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GSTextStyles.bodySmall.copyWith(color: color, height: 1.4)),
    );
  }
}
