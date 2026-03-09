import 'package:flutter/material.dart';
import '../../../../models/campaign_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class CampaignDetailsScreen extends StatelessWidget {
  final CampaignModel campaign;

  const CampaignDetailsScreen({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = DateFormat('MMM d, yyyy');

    String dateStr = '';
    if (campaign.startDate != null && campaign.endDate != null) {
      dateStr = '${formatter.format(campaign.startDate!)} - ${formatter.format(campaign.endDate!)}';
    } else if (campaign.startDate != null) {
      dateStr = 'Starts ${formatter.format(campaign.startDate!)}';
    }

    double progress = 0.0;
    if (campaign.treeGoal > 0) {
      progress = (campaign.treePlanted / campaign.treeGoal).clamp(0.0, 1.0);
    }

    return Scaffold(
      backgroundColor: AppColors.ivorySand,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.oliveGrey.withValues(alpha: 0.3),
                child: const Center(
                  child: Icon(Icons.nature_people, size: 80, color: AppColors.linenWhite),
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: AppColors.slateCharcoal),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0.0, -24.0, 0.0),
              decoration: const BoxDecoration(
                color: AppColors.linenWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slateCharcoal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildStatusBadge(campaign.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.mossForest,
                          child: Icon(Icons.group, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          campaign.organizerId ?? 'Organizer',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.oliveGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats Row
                    Row(
                      children: [
                        _buildStatItem(Icons.park, '${campaign.treePlanted} / ${campaign.treeGoal}', l10n.target),
                        const SizedBox(width: 24),
                        _buildStatItem(Icons.calendar_month, dateStr, 'Date'),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    // Progress
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.ivorySand,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mossForest),
                        minHeight: 10,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    const Text(
                      'About Campaign', // Translation needed
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slateCharcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      campaign.description ?? 'No description provided.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.oliveGrey,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    const Text(
                      'Participants', // Translation needed
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slateCharcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Participant Avatars (Placeholder)
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Align(
                            widthFactor: 0.6,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.mossForest.withValues(alpha: 0.2 + (index * 0.1)),
                                child: const Icon(Icons.person, color: AppColors.mossForest, size: 20),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Spacing for bottom button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: AppColors.linenWhite,
        padding: const EdgeInsets.all(24),
        child: PrimaryButton(
          text: l10n.participateNow,
          onPressed: () {
            // Navigate to Map with campaign selected
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.ivorySand,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.oliveGrey.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: AppColors.mossForest, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.slateCharcoal,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.oliveGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'active':
        bgColor = AppColors.mossForest.withValues(alpha: 0.1);
        textColor = AppColors.mossForest;
        text = 'نشطة'; 
        break;
      case 'upcoming':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade800;
        text = 'قريباً';
        break;
      case 'completed':
        bgColor = AppColors.oliveGrey.withValues(alpha: 0.1);
        textColor = AppColors.oliveGrey;
        text = 'مكتملة';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey.shade700;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
