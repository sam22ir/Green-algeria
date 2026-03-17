import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/auth_service.dart';

class TechnicalSupportScreen extends StatefulWidget {
  const TechnicalSupportScreen({super.key});

  @override
  State<TechnicalSupportScreen> createState() => _TechnicalSupportScreenState();
}

class _TechnicalSupportScreenState extends State<TechnicalSupportScreen> {
  final _messageController = TextEditingController();
  late final TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().firebaseUser;
    _nameController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final colorScheme = Theme.of(context).colorScheme;
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_write_message'.tr())),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final currentUser = AuthService().firebaseUser;
      await Supabase.instance.client.from('support_messages').insert({
        'user_id': currentUser?.id,
        'name': _nameController.text.trim(),
        'message': _messageController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('message_sent_success'.tr()),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('report_submit_failed'.tr(args: [e.toString()])), 
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'technical_support'.tr(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brother Fouad Card
              _PremiumSupportContactCard(
                name: 'brother_fouad'.tr(),
                role: 'project_head'.tr(),
                actionText: 'chat_on_whatsapp'.tr(),
                icon: Icons.verified_user_outlined,
                isPrimary: true,
                onTap: () {
                  // WhatsApp number not configured yet — show coming soon dialog
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF25D366)),
                          const SizedBox(width: 8),
                          Text('chat_on_whatsapp'.tr()),
                        ],
                      ),
                      content: const Text(
                        'سوف يتوفر رقم واتساب للتواصل قريباً.\nيمكنك في الوقت الحالي إرسال رسالتك من خلال النموذج أدناه.',
                        textDirection: TextDirection.rtl,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('حسناً'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Report Problem Card
              _PremiumSupportContactCard(
                name: 'report_problem'.tr(),
                role: 'dev_team'.tr(),
                actionText: 'report_issue'.tr(),
                icon: Icons.bug_report_outlined,
                isPrimary: false,
                onTap: () => context.push('/report-problem'),
              ),
              const SizedBox(height: 32),

              Divider(color: colorScheme.outline.withValues(alpha: 0.1)),
              const SizedBox(height: 16),

              // Message field
              Text(
                'leave_quick_message'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'write_message_hint'.tr(),
                  hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)
                    : Text(
                        'send_message'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumSupportContactCard extends StatelessWidget {
  final String name;
  final String role;
  final String actionText;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _PremiumSupportContactCard({
    required this.name,
    required this.role,
    required this.actionText,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = isPrimary ? const Color(0xFF25D366) : colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _buildAvatar(primaryColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          role,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(icon, color: colorScheme.onSurface.withValues(alpha: 0.2), size: 22),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(isPrimary ? Icons.chat_bubble_rounded : Icons.arrow_forward_rounded, size: 20),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isPrimary ? Colors.white : colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1) : '?',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }
}
