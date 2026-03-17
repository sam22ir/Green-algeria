import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../models/campaign_model.dart';
import '../../../services/supabase_service.dart';
import '../../../constants/campaign_covers.dart';
import 'past_campaign_detail_screen.dart';


class PastCampaignsScreen extends StatefulWidget {
  const PastCampaignsScreen({super.key});

  @override
  State<PastCampaignsScreen> createState() => _PastCampaignsScreenState();
}

class _PastCampaignsScreenState extends State<PastCampaignsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CampaignModel> _allPast = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPastCampaigns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPastCampaigns() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getPastCampaigns();
      if (mounted) {
        setState(() {
          _allPast = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CampaignModel> _filtered(String type) =>
      _allPast.where((c) => c.type == type).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'past_campaigns'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.4),
          indicatorColor: cs.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(text: 'national_type'.tr()),
            Tab(text: 'provincial_type'.tr()),
            Tab(text: 'local_type'.tr()),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : RefreshIndicator(
              onRefresh: _loadPastCampaigns,
              color: cs.primary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_filtered('national')),
                  _buildList(_filtered('provincial')),
                  _buildList(_filtered('local')),
                ],
              ),
            ),
    );
  }

  Widget _buildList(List<CampaignModel> campaigns) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: cs.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              'no_past_campaigns'.tr(),
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: campaigns.length,
      itemBuilder: (context, i) => _buildCard(campaigns[i]),
    );
  }

  Widget _buildCard(CampaignModel campaign) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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

    String? dateRange;
    if (campaign.startDate != null && campaign.endDate != null) {
      final fmt = DateFormat('d MMM yyyy', context.locale.languageCode);
      dateRange = '${fmt.format(campaign.startDate!)} — ${fmt.format(campaign.endDate!)}';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PastCampaignDetailScreen(campaign: campaign),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ صورة الغلاف
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.asset(
                campaign.coverImageAsset ?? AppCampaignCovers.forType(campaign.type),
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 110,
                  color: cs.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.park_rounded, color: cs.primary, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: type badge + status badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'completed'.tr(),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    campaign.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Stats row
                  Row(
                    children: [
                      _InfoChip(icon: Icons.park_rounded, label: '${campaign.treePlanted} ${'trees'.tr()}', color: cs.primary),
                      const SizedBox(width: 16),
                      if (dateRange != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  dateRange,
                                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.25)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
