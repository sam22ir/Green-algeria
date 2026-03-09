import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../models/campaign_model.dart';
import 'package:intl/intl.dart';

class CampaignCard extends StatelessWidget {
  final CampaignModel campaign;
  final VoidCallback onTap;
  final VoidCallback onJoinTap;

  const CampaignCard({
    super.key,
    required this.campaign,
    required this.onTap,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = DateFormat('MMM d, yyyy');
    
    // Calculate progress
    double progress = 0.0;
    if (campaign.treeGoal > 0) {
      progress = (campaign.treePlanted / campaign.treeGoal).clamp(0.0, 1.0);
    }

    String dateStr = '';
    if (campaign.startDate != null && campaign.endDate != null) {
      dateStr = '${formatter.format(campaign.startDate!)} - ${formatter.format(campaign.endDate!)}';
    } else if (campaign.startDate != null) {
      dateStr = 'Starts ${formatter.format(campaign.startDate!)}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: CustomCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Placeholder - later fetch from Supabase if available
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.oliveGrey.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Center(
                child: Icon(Icons.nature_people, size: 48, color: AppColors.ivorySand),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          campaign.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slateCharcoal,
                          ),
                        ),
                      ),
                      _buildStatusBadge(campaign.status, context),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Organizer info (placeholder for now, needs user fetch)
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.mossForest,
                        child: Icon(Icons.group, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          campaign.organizerId ?? 'Unknown Organizer',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.oliveGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.park, size: 16, color: AppColors.mossForest),
                          const SizedBox(width: 4),
                          Text(
                            '${l10n.target}: ${campaign.treeGoal}',
                            style: const TextStyle(
                              color: AppColors.slateCharcoal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (dateStr.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 16, color: AppColors.mossForest),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: AppColors.slateCharcoal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress Bar
                  Row(
                    children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.ivorySand,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mossForest),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                            '${campaign.treePlanted} / ${campaign.treeGoal}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mossForest,
                            ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  SecondaryButton(
                    text: l10n.participateNow,
                    onPressed: onJoinTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    // Translation keys could be added for these
    switch (status.toLowerCase()) {
      case 'active':
        bgColor = AppColors.mossForest.withValues(alpha: 0.1);
        textColor = AppColors.mossForest;
        text = 'نشطة'; // Active
        break;
      case 'upcoming':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade800;
        text = 'قريباً'; // Upcoming
        break;
      case 'completed':
        bgColor = AppColors.oliveGrey.withValues(alpha: 0.1);
        textColor = AppColors.oliveGrey;
        text = 'مكتملة'; // Completed
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey.shade700;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
