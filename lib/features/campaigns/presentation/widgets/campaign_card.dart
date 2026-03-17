import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../widgets/custom_card.dart';
import '../../../../widgets/custom_buttons.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../models/campaign_model.dart';
import '../../../../constants/campaign_covers.dart';

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
    final languageCode = context.locale.languageCode;
    final formatter = DateFormat('MMM d, yyyy', languageCode);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate progress
    double progress = 0.0;
    if (campaign.treeGoal > 0) {
      progress = (campaign.treePlanted / campaign.treeGoal).clamp(0.0, 1.0);
    }

    String dateStr = '';
    if (campaign.startDate != null && campaign.endDate != null) {
      dateStr = '${formatter.format(campaign.startDate!)} - ${formatter.format(campaign.endDate!)}';
    } else if (campaign.startDate != null) {
      dateStr = '${'starts'.tr()} ${formatter.format(campaign.startDate!)}';
    }

    // Use campaign's DB cover, or a beautiful local fallback by type
    final coverAsset = campaign.coverImageAsset ?? AppCampaignCovers.forType(campaign.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: CustomCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        color: colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    child: Image.asset(
                      coverAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(
                        child: Icon(
                          Icons.nature_people_rounded,
                          size: 48,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                if (campaign.hasZone)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'geographic_zone'.tr(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(theme, campaign.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Organizer info — only show if name is available
                  if (campaign.organizerName != null && campaign.organizerName!.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_rounded, size: 14, color: colorScheme.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            campaign.organizerName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.park_rounded, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${'target'.tr()}: ${campaign.treeGoal}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (dateStr.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Progress Bar
                  Row(
                    children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                            '${campaign.treePlanted} / ${campaign.treeGoal}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                            ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  SecondaryButton(
                    text: 'participate_now'.tr(),
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

  Widget _buildStatusBadge(ThemeData theme, String status) {
    final colorScheme = theme.colorScheme;
    Color bgColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'active':
        bgColor = colorScheme.primary.withValues(alpha: 0.1);
        textColor = colorScheme.primary;
        text = 'active'.tr();
        break;
      case 'upcoming':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade800;
        text = 'upcoming'.tr();
        break;
      case 'completed':
        bgColor = colorScheme.onSurface.withValues(alpha: 0.1);
        textColor = colorScheme.onSurface.withValues(alpha: 0.5);
        text = 'completed_status'.tr();
        break;
      default:
        bgColor = colorScheme.onSurface.withValues(alpha: 0.05);
        textColor = colorScheme.onSurface.withValues(alpha: 0.4);
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
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
