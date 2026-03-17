import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/tutorial_service.dart';

/// Data class for each screen's tutorial content.
class TutorialData {
  final String screenId;
  final IconData icon;
  final String titleKey;
  final String bodyKey;
  final String tipKey;

  const TutorialData({
    required this.screenId,
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
    required this.tipKey,
  });
}

/// Pre-defined tutorial data for each screen.
class AppTutorials {
  static const home = TutorialData(
    screenId: 'home',
    icon: Icons.home_rounded,
    titleKey: 'tutorial_home_title',
    bodyKey: 'tutorial_home_body',
    tipKey: 'tutorial_home_tip',
  );

  static const map = TutorialData(
    screenId: 'map',
    icon: Icons.map_rounded,
    titleKey: 'tutorial_map_title',
    bodyKey: 'tutorial_map_body',
    tipKey: 'tutorial_map_tip',
  );

  static const campaigns = TutorialData(
    screenId: 'campaigns',
    icon: Icons.campaign_rounded,
    titleKey: 'tutorial_campaigns_title',
    bodyKey: 'tutorial_campaigns_body',
    tipKey: 'tutorial_campaigns_tip',
  );

  static const leaderboard = TutorialData(
    screenId: 'leaderboard',
    icon: Icons.emoji_events_rounded,
    titleKey: 'tutorial_leaderboard_title',
    bodyKey: 'tutorial_leaderboard_body',
    tipKey: 'tutorial_leaderboard_tip',
  );

  static const profile = TutorialData(
    screenId: 'profile',
    icon: Icons.person_rounded,
    titleKey: 'tutorial_profile_title',
    bodyKey: 'tutorial_profile_body',
    tipKey: 'tutorial_profile_tip',
  );
}

/// Wraps any screen with an optional tutorial overlay.
/// Checks SharedPreferences and shows the card only once.
class TutorialOverlay extends StatefulWidget {
  final Widget child;
  final TutorialData tutorial;

  const TutorialOverlay({
    super.key,
    required this.child,
    required this.tutorial,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _olive = Color(0xFF606C38);
  static const _oliveDark = Color(0xFF4A5629);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    // Check after first frame so child has rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final show = await TutorialService.shouldShow(widget.tutorial.screenId);
      if (show && mounted) {
        setState(() => _visible = true);
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    await TutorialService.markSeen(widget.tutorial.screenId);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible) _buildOverlay(context),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        onTap: _dismiss, // tap outside → dismiss
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // absorb taps inside card
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _buildCard(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: _olive.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Icon badge
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25), width: 2),
                  ),
                  child: Icon(widget.tutorial.icon,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  widget.tutorial.titleKey.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Body
                Text(
                  widget.tutorial.bodyKey.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),

                // Tip row
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          color: Color(0xFFD4C26A), size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.tutorial.tipKey.tr(),
                          style: const TextStyle(
                            color: Color(0xFFD4C26A),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dismiss button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _dismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _oliveDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'tutorial_got_it'.tr(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
