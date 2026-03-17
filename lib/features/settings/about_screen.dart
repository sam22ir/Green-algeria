import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _shareApp() async {
    const String appLink = 'https://github.com/sam22ir/Green-algeria/releases/tag/Algeria';
    final String message = 'share_app_message'.tr(args: [appLink]);
    await Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRtl = context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'about_app'.tr(),
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              isRtl ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_ios_new_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // 1. BRANDING SECTION
              _buildBrandingSection(colorScheme),
              const SizedBox(height: 40),

              // 2. MISSION SECTION
              _buildSectionHeader('our_mission'.tr(), colorScheme),
              const SizedBox(height: 12),
              _buildMissionCard(colorScheme),
              const SizedBox(height: 32),

              // 3. TEAM SECTION
              _buildSectionHeader('project_team'.tr(), colorScheme),
              const SizedBox(height: 12),
              _buildTeamMemberCard(
                name: 'brother_fouad'.tr(),
                role: 'head_of_project'.tr(),
                avatarChar: 'fouad_initial'.tr(),
                colorScheme: colorScheme,
                onTap: null, // رقم الواتس آب محذوف مؤقتاً
              ),
              const SizedBox(height: 12),
              _buildTeamMemberCard(
                name: 'saadi_samir'.tr(),
                role: 'lead_developer'.tr(),
                avatarChar: 'samir_initial'.tr(),
                colorScheme: colorScheme,
                onTapLinks: [
                  ('GitHub', Icons.code_rounded, 'https://github.com/sam22ir'),
                  ('Instagram', Icons.camera_alt_outlined, 'https://www.instagram.com/sam__22__ir/'),
                ],
              ),
              const SizedBox(height: 32),

              // 4. SOCIAL SECTION
              _buildSectionHeader('follow_us'.tr(), colorScheme),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSocialChip(
                    'facebook'.tr(), 
                    Icons.facebook_rounded, 
                    colorScheme,
                    () => _launchUrl('https://www.facebook.com/Greenest.Algeria?mibextid=ZbWKwL'),
                  ),
                  _buildSocialChip(
                    'instagram'.tr(), 
                    Icons.camera_alt_outlined, 
                    colorScheme,
                    () => _launchUrl('https://www.instagram.com/eljazayer_elkhadhra?igsh=MWhyejVobXZvMTZxNg=='),
                  ),
                  _buildSocialChip(
                    'twitter_x'.tr(), 
                    Icons.close_rounded, 
                    colorScheme,
                    () => _launchUrl('https://x.com/GreenestAlgeria'),
                  ),
                  _buildSocialChip(
                    'tiktok'.tr(), 
                    Icons.music_note_rounded, 
                    colorScheme,
                    () => _launchUrl('https://tiktok.com/@eljazayer_elkhadhra'),
                  ),
                  _buildSocialChip(
                    'youtube'.tr(), 
                    Icons.play_circle_outline_rounded, 
                    colorScheme,
                    () => _launchUrl('https://youtube.com/@eljazayer_elkhadhra'),
                  ),
                  _buildSocialChip(
                    'share_app'.tr(), 
                    Icons.share_rounded, 
                    colorScheme,
                    _shareApp,
                    isHighlight: true,
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              // Memorial section — دعاء لوالدة المطور
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.favorite_rounded, color: colorScheme.primary, size: 22),
                    const SizedBox(height: 10),
                    Text(
                      'دعواتكم لأمي بالرحمة والمغفرة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // App Footer
              Text(
                '${'app_name'.tr()} © 2024',
                style: TextStyle(color: colorScheme.outline, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingSection(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1), width: 1),
          ),
          child: Center(
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 75,
                height: 75,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'app_name_ar'.tr(),
          style: TextStyle(
            fontSize: 28, 
            fontWeight: FontWeight.bold, 
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'app_name'.tr(),
          style: TextStyle(
            fontSize: 16, 
            color: colorScheme.primary, 
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
          ),
          child: Text(
            'app_version'.tr(),
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco_rounded, color: colorScheme.secondary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'mission_content'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15, 
              height: 1.6, 
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard({
    required String name,
    required String role,
    required String avatarChar,
    required ColorScheme colorScheme,
    VoidCallback? onTap,
    List<(String, IconData, String)>? onTapLinks,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatarChar,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
            ],
          ),
          // أزرار روابط إضافية (للمطور)
          if (onTapLinks != null && onTapLinks.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: onTapLinks.map((link) {
                final (label, icon, url) = link;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: InkWell(
                    onTap: () => _launchUrl(url),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(label,
                              style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialChip(String label, IconData icon, ColorScheme colorScheme, VoidCallback onTap, {bool isHighlight = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isHighlight ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withValues(alpha: isHighlight ? 0 : 0.1)),
          boxShadow: [
            BoxShadow(
              color: isHighlight ? colorScheme.primary.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isHighlight ? colorScheme.onPrimary : colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHighlight ? colorScheme.onPrimary : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
