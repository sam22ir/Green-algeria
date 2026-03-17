import 'package:flutter/material.dart';
import '../../../../models/campaign_model.dart';
import '../../../../widgets/custom_buttons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/supabase_service.dart';

class CampaignDetailsScreen extends StatefulWidget {
  final CampaignModel campaign;

  const CampaignDetailsScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends State<CampaignDetailsScreen> {
  late CampaignModel _campaign;
  bool _isAuthorized = false;



  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    try {
      final user = await SupabaseService().getUserProfile();
      if (user != null) {
        final isAdminRole = user.role == 'developer' || user.role == 'initiative_owner';
        final isOrganizerOfThis = user.id == _campaign.organizerId &&
            (user.role == 'provincial_organizer' || user.role == 'local_organizer');
        setState(() {
          _isAuthorized = isAdminRole || isOrganizerOfThis;
        });
      }
    } catch (e) {
      debugPrint('Error checking authorization: $e');
    }
  }

  Future<void> _showEndCampaignDialog() async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('end_campaign'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('confirm_end_campaign'.tr()),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'end_reason'.tr(),
                hintText: 'optional_reason'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text('end_now'.tr()),
          ),
        ],
      ),
    );

    if (result == true) {
      _endCampaign(reasonController.text);
    }
  }

  Future<void> _endCampaign(String reason) async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) return;

      await SupabaseService().endCampaign(
        campaignId: _campaign.id,
        adminId: currentUser.id,
        reason: reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('campaign_ended_success'.tr()),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh local data (status changes to completed in UI)
      setState(() {
        _campaign = CampaignModel(
          id: _campaign.id,
          title: _campaign.title,
          description: _campaign.description,
          type: _campaign.type,
          provinceId: _campaign.provinceId,
          organizerId: _campaign.organizerId,
          startDate: _campaign.startDate,
          endDate: _campaign.endDate,
          status: 'completed',
          treeGoal: _campaign.treeGoal,
          treePlanted: _campaign.treePlanted,
          coverImageAsset: _campaign.coverImageAsset,
          hasZone: _campaign.hasZone,
          zonePolygon: _campaign.zonePolygon,
          endedAt: DateTime.now(),
          endedBy: currentUser.id,
          endReason: reason,
          createdAt: _campaign.createdAt,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'error'.tr()}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCode = context.locale.languageCode;
    final formatter = DateFormat('MMM d, yyyy', languageCode);

    String dateStr = '';
    if (_campaign.startDate != null && _campaign.endDate != null) {
      dateStr = '${formatter.format(_campaign.startDate!)} - ${formatter.format(_campaign.endDate!)}';
    } else if (_campaign.startDate != null) {
      dateStr = '${'starts'.tr()} ${formatter.format(_campaign.startDate!)}';
    }

    double progress = 0.0;
    if (_campaign.treeGoal > 0) {
      progress = (_campaign.treePlanted / _campaign.treeGoal).clamp(0.0, 1.0);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                ),
                child: _campaign.coverImageAsset != null
                    ? Image.asset(
                        _campaign.coverImageAsset!,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Hero(
                          tag: 'campaign_icon_${_campaign.id}',
                          child: Icon(
                            Icons.park_rounded,
                            size: 80,
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
            ),
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {
                  final text = '${'about_campaign'.tr()}: ${_campaign.title}\n${'target'.tr()}: ${_campaign.treeGoal} ${'trees'.tr()}\n\n${'app_name'.tr()}';
                  Share.share(text);
                },
              ),
              if (_isAuthorized && _campaign.status != 'completed')
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: 'end_campaign'.tr(),
                  onPressed: _showEndCampaignDialog,
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0.0, -24.0, 0.0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
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
                            _campaign.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildStatusBadge(theme, _campaign.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_rounded, size: 16, color: colorScheme.primary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _campaign.organizerId ?? 'unknown_organizer'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    if (_campaign.status == 'completed' && _campaign.endReason != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'end_reason'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_campaign.endReason!, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    
                    // Stats Row
                    Row(
                      children: [
                        Expanded(child: _buildStatItem(theme, Icons.park_rounded, '${_campaign.treePlanted} / ${_campaign.treeGoal}', 'target'.tr())),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatItem(theme, Icons.calendar_month_rounded, dateStr, 'date'.tr())),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    // Progress
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              'planting_progress'.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            minHeight: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    Text(
                      'about_campaign'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _campaign.description ?? 'no_description'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    Text(
                      'participants'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Participant Avatars (Placeholder)
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: 8,
                        itemBuilder: (context, index) {
                          return Align(
                            widthFactor: 0.7,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.scaffoldBackgroundColor, width: 2.5),
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: colorScheme.primary.withValues(alpha: 0.1 + (index * 0.1)),
                                child: Icon(Icons.person_rounded, color: colorScheme.primary, size: 20),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 120), // Spacing for bottom button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _campaign.status != 'completed' ? Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SafeArea(
          child: PrimaryButton(
            text: 'participate_now'.tr(),
            onPressed: () {
              // Navigate to Map with campaign selected
            },
          ),
        ),
      ) : null,
    );
  }

  Widget _buildStatItem(ThemeData theme, IconData icon, String value, String label) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
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
        textColor = Colors.orange.shade900;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
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
