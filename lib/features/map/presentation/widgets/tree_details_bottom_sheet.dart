import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../leaderboard/presentation/public_profile_screen.dart';

class TreeDetailsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> treeData;

  const TreeDetailsBottomSheet({
    super.key,
    required this.treeData,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRtl = context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header with Drag Handle & Close
              _buildHeader(context),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 2. Tree Main Info
                      _buildTreeHeader(colorScheme, isRtl),
                      const SizedBox(height: 24),

                      // 3. Planter Card
                      _buildPlanterCard(context, colorScheme),
                      const SizedBox(height: 16),

                      // 4. Location Section
                      _buildLocationSection(colorScheme),
                      const SizedBox(height: 32),

                      // 5. Action Row
                      _buildActionRow(context, colorScheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildTreeHeader(ColorScheme colorScheme, bool isRtl) {
    final treeType = treeData['tree_type'] ?? 'tree_planting'.tr();
    final treeTypeEn = treeData['tree_type_en'] ?? 'Tree';
    
    return Row(
      children: [
        Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: (treeData['tree_species'] != null && treeData['tree_species']['image_asset_path'] != null)
                ? Image.asset(
                    treeData['tree_species']['image_asset_path'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.park_rounded, color: colorScheme.primary, size: 48),
                  )
                : Icon(Icons.park_rounded, color: colorScheme.primary, size: 48),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                treeData['tree_species'] != null 
                    ? (isRtl ? treeData['tree_species']['name_ar'] : treeData['tree_species']['name_en'])
                    : treeType,
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                treeData['tree_species']?['name_scientific'] ?? treeTypeEn,
                style: TextStyle(
                  fontSize: 14, 
                  fontStyle: FontStyle.italic, 
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildPlanterCard(BuildContext context, ColorScheme colorScheme) {
    final planterName = (treeData['planter_name'] as String?)?.isNotEmpty == true
        ? treeData['planter_name'] as String
        : 'anonymous'.tr();
    final planterId = treeData['planter_id'] as String?;
    final rawDate = treeData['planted_at'];
    final plantingDate = rawDate != null
        ? DateFormat.yMMMMd(context.locale.languageCode).format(DateTime.parse(rawDate as String))
        : 'unknown_date'.tr();

    final bool canNavigate = planterId != null && planterId.isNotEmpty;

    return GestureDetector(
      onTap: canNavigate
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PublicProfileScreen(userId: planterId),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                planterName.isNotEmpty ? planterName[0].toUpperCase() : '?',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'planter'.tr(),
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    planterName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: canNavigate ? colorScheme.primary : null,
                      decoration: canNavigate ? TextDecoration.underline : null,
                      decorationColor: colorScheme.primary,
                    ),
                  ),
                  Text(
                    plantingDate,
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ),
            ),
            Icon(
              canNavigate ? Icons.arrow_forward_ios_rounded : Icons.person_outline_rounded,
              size: 14,
              color: canNavigate
                  ? colorScheme.primary.withValues(alpha: 0.6)
                  : colorScheme.outline.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(ColorScheme colorScheme) {
    final lat = treeData['latitude'];
    final lon = treeData['longitude'];
    final String latStr = (lat is num) ? lat.toStringAsFixed(5) : '--';
    final String lonStr = (lon is num) ? lon.toStringAsFixed(5) : '--';
    final String coordLabel = '$latStr° N, $lonStr° E';

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: coordLabel));
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on_rounded, color: colorScheme.secondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'location'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  coordLabel,
                  style: TextStyle(fontSize: 13, color: colorScheme.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, ColorScheme colorScheme) {
    final lat = treeData['latitude'];
    final lon = treeData['longitude'];
    final latStr = (lat is num) ? lat.toStringAsFixed(5) : '--';
    final lonStr = (lon is num) ? lon.toStringAsFixed(5) : '--';
    final speciesAr = treeData['tree_species']?['name_ar'] ?? 'tree_planting'.tr();
    final planterName = (treeData['planter_name'] as String?)?.isNotEmpty == true
        ? treeData['planter_name'] as String
        : 'anonymous'.tr();
    final shareText = '${'share_tree'.tr()}\n$speciesAr\n${'planter'.tr()}: $planterName\n${'location'.tr()}: $latStr° N, $lonStr° E';

    return ElevatedButton.icon(
      onPressed: () async {
        try {
          await Share.share(shareText);
        } catch (_) {
          // Fallback: copy to clipboard
          await Clipboard.setData(ClipboardData(text: shareText));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('copied_to_clipboard'.tr())),
            );
          }
        }
      },
      icon: const Icon(Icons.share_rounded, size: 20),
      label: Text('share_tree'.tr()),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }
}
