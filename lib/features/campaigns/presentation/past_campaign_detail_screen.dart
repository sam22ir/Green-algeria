import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/campaign_model.dart';
import '../../../widgets/custom_card.dart';

class PastCampaignDetailScreen extends StatefulWidget {
  final CampaignModel campaign;

  const PastCampaignDetailScreen({super.key, required this.campaign});

  @override
  State<PastCampaignDetailScreen> createState() => _PastCampaignDetailScreenState();
}

class _PastCampaignDetailScreenState extends State<PastCampaignDetailScreen> {
  int _participantCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Count distinct users who planted in this campaign
      final res = await Supabase.instance.client
          .from('tree_plantings')
          .select('user_id')
          .eq('campaign_id', widget.campaign.id);
      final List<dynamic> rows = List<dynamic>.from(res);
      final uniqueUsers = rows.map((r) => r['user_id']).toSet().length;
      if (mounted) {
        setState(() {
          _participantCount = uniqueUsers;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final campaign = widget.campaign;

    final double progress = campaign.treeGoal > 0
        ? (campaign.treePlanted / campaign.treeGoal).clamp(0.0, 1.0)
        : 0.0;

    String? startStr;
    String? endStr;
    int? durationDays;
    if (campaign.startDate != null && campaign.endDate != null) {
      final fmt = DateFormat('d MMMM yyyy', context.locale.languageCode);
      startStr = fmt.format(campaign.startDate!);
      endStr = fmt.format(campaign.endDate!);
      durationDays = campaign.endDate!.difference(campaign.startDate!).inDays;
    }

    String typeLabel;
    switch (campaign.type) {
      case 'national':
        typeLabel = 'national_type'.tr();
        break;
      case 'provincial':
        typeLabel = 'provincial_type'.tr();
        break;
      default:
        typeLabel = 'local_type'.tr();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          campaign.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 16, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: cs.primary,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // ────── Stat Cards Row ──────
            Row(
              children: [
                Expanded(child: _StatCard(
                  icon: Icons.park_rounded,
                  value: _formatCount(campaign.treePlanted),
                  label: 'trees_planted'.tr(),
                  color: cs.primary,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: Icons.group_rounded,
                  value: _isLoadingStats ? '...' : _formatCount(_participantCount),
                  label: 'participants'.tr(),
                  color: cs.secondary,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: Icons.flag_rounded,
                  value: '${(progress * 100).toInt()}%',
                  label: 'completion_rate'.tr(),
                  color: Colors.amber.shade700,
                )),
              ],
            ),
            const SizedBox(height: 24),

            // ────── Progress Bar ──────
            CustomCard(
              padding: const EdgeInsets.all(20),
              color: cs.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'tree_goal_label'.tr(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface, fontSize: 14),
                      ),
                      Text(
                        '${_formatCount(campaign.treePlanted)} / ${_formatCount(campaign.treeGoal)} ${'trees'.tr()}',
                        style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ────── Timeline ──────
            if (startStr != null) ...[
              CustomCard(
                padding: const EdgeInsets.all(20),
                color: cs.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'timeline'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    _TimelineRow(
                      icon: Icons.play_circle_rounded,
                      label: 'started_at'.tr(),
                      value: startStr!,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    _TimelineRow(
                      icon: Icons.flag_circle_rounded,
                      label: 'ended_at'.tr(),
                      value: endStr!,
                      color: Colors.red.shade400,
                    ),
                    if (durationDays != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$durationDays ${'days'.tr()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ────── End Reason (if available) ──────
            if (campaign.endReason != null && campaign.endReason!.isNotEmpty) ...[
              CustomCard(
                padding: const EdgeInsets.all(20),
                color: cs.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 8),
                        Text(
                          'end_reason'.tr(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      campaign.endReason!,
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ────── Description ──────
            if (campaign.description != null && campaign.description!.isNotEmpty) ...[
              CustomCard(
                padding: const EdgeInsets.all(20),
                color: cs.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'description'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      campaign.description!,
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 14, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimelineRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w500)),
            Text(value, style: TextStyle(fontSize: 14, color: cs.onSurface, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
