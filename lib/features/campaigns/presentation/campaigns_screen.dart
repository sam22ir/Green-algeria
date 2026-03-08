import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.linenWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(l10n),
            _buildTabBar(l10n),
            Expanded(
              child: _buildCampaignList(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        l10n.campaigns,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.slateCharcoal,
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ivorySand.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTab(0, l10n.national),
          _buildTab(1, l10n.wilaya),
          _buildTab(2, l10n.individual),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mossForest : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.mossForest.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.slateCharcoal,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignList(AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: CustomCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Placeholder
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.oliveGrey.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 48, color: AppColors.ivorySand),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'حملة تشجير جبال جرجرة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slateCharcoal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.park, size: 16, color: AppColors.mossForest),
                              const SizedBox(width: 4),
                              Text(
                                '${l10n.target}: 50,000',
                                style: const TextStyle(
                                  color: AppColors.oliveGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 16, color: AppColors.mossForest),
                              const SizedBox(width: 4),
                              Text(
                                '12 ${l10n.daysRemaining}',
                                style: const TextStyle(
                                  color: AppColors.oliveGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: 0.6,
                          backgroundColor: AppColors.ivorySand,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mossForest),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SecondaryButton(
                        text: l10n.participateNow,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
