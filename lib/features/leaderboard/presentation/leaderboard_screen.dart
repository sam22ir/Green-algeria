import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
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
            _buildToggle(l10n),
            const SizedBox(height: 24),
            _buildPodium(),
            const SizedBox(height: 32),
            Expanded(child: _buildRankingsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_outlined, color: AppColors.mossForest, size: 28),
          const SizedBox(width: 8),
          Text(
            l10n.leaderboardTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.slateCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ivorySand.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTab(0, l10n.individuals),
          _buildTab(1, l10n.wilayas),
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

  Widget _buildPodium() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPodiumPlace(2, 'أحمد م.', '2,100 شجرة', 100),
          _buildPodiumPlace(1, 'سليمان ك.', '3,450 شجرة', 140, isFirst: true),
          _buildPodiumPlace(3, 'فاطمة ز.', '1,950 شجرة', 90),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(int rank, String name, String trees, double height, {bool isFirst = false}) {
    return Column(
      children: [
        if (isFirst)
          const Icon(Icons.workspace_premium, color: Color(0xFFFFC107), size: 36),
        CircleAvatar(
          radius: isFirst ? 36 : 28,
          backgroundColor: AppColors.ivorySand,
          child: Icon(Icons.person, color: AppColors.mossForest, size: isFirst ? 36 : 28),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slateCharcoal),
        ),
        Text(
          trees,
          style: TextStyle(
            color: isFirst ? AppColors.mossForest : AppColors.oliveGrey,
            fontWeight: isFirst ? FontWeight.bold : FontWeight.w600,
            fontSize: isFirst ? 14 : 12,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: isFirst ? AppColors.mossForest : AppColors.mossForest.withOpacity(0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: 7,
      itemBuilder: (context, index) {
        final rank = index + 4;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.ivorySand,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.slateCharcoal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.oliveGrey,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'مشارك بالمركز',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.slateCharcoal,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Text(
                  '1,200 شجرة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.mossForest,
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
