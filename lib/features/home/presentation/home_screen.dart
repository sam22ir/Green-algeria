import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linenWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAppBar(),
              const SizedBox(height: 32),
              _buildTotalTreesCounter(),
              const SizedBox(height: 24),
              _buildCampaignCountdown(),
              const SizedBox(height: 32),
              _buildRecentCampaignsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.ivorySand,
              child: Icon(Icons.person, color: AppColors.mossForest),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً،',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.oliveGrey,
                  ),
                ),
                Text(
                  'محمد',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slateCharcoal,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.slateCharcoal),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildTotalTreesCounter() {
    return CustomCard(
      blur: 20,
      opacity: 0.85,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.park_rounded, size: 48, color: AppColors.mossForest),
          const SizedBox(height: 16),
          const Text(
            '1,245,390',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AppColors.mossForest,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'شجرة تم غرسها وطنياً',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.oliveGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCountdown() {
    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.ivorySand,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.timer_outlined, color: AppColors.mossForest, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حملة تشجير الأوراس',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slateCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تبدأ بعد 3 أيام و 5 ساعات',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mossForest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCampaignsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'أحدث الحملات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.slateCharcoal,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.mossForest,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 140,
                margin: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.ivorySand),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.oliveGrey.withOpacity(0.2),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: const Icon(Icons.image, color: AppColors.ivorySand, size: 40),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'غابة باينام',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.slateCharcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '10,000 شجرة',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mossForest,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
