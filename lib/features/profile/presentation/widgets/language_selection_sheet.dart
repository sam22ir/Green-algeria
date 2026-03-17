import 'dart:ui';
import 'package:flutter/material.dart';

class LanguageSelectionSheet extends StatelessWidget {
  final String currentLanguageCode;
  final Function(String) onLanguageSelected;

  const LanguageSelectionSheet({
    super.key,
    required this.currentLanguageCode,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'اختر اللغة | Select Language',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),

            // Arabic Option
            _LanguageCard(
              title: 'العربية',
              subtitle: 'Arabic',
              flagEmoji: '🇩🇿',
              isSelected: currentLanguageCode == 'ar',
              onTap: () => onLanguageSelected('ar'),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),

            // English Option
            _LanguageCard(
              title: 'English',
              subtitle: 'الإنجليزية',
              flagEmoji: '🇬🇧',
              isSelected: currentLanguageCode == 'en',
              onTap: () => onLanguageSelected('en'),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String flagEmoji;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.flagEmoji,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.08) : colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? colorScheme.secondary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: colorScheme.secondary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(flagEmoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colorScheme.secondary, size: 28),
          ],
        ),
      ),
    );
  }
}
