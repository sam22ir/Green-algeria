import 'package:flutter/material.dart';
import '../../../../widgets/custom_card.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/custom_buttons.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/supabase_service.dart';
import 'package:easy_localization/easy_localization.dart';

class RoleRequestScreen extends StatefulWidget {
  const RoleRequestScreen({super.key});

  @override
  State<RoleRequestScreen> createState() => _RoleRequestScreenState();
}

class _RoleRequestScreenState extends State<RoleRequestScreen> {
  int _selectedRoleIndex = 0; // 0 for Organizer, 1 for Wilaya Coordinator
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submitRequest() async {
    final colorScheme = Theme.of(context).colorScheme;
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('fill_required_fields'.tr()),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final user = AuthService().firebaseUser;
      if (user == null) throw Exception('User not logged in');

      final requestedRole = _selectedRoleIndex == 0 ? 'local_organizer' : 'provincial_organizer';

      await SupabaseService.client.from('upgrade_requests').insert({
        'user_id': user.id,
        'requested_role': requestedRole,
        'status': 'pending',
        'reason': _reasonController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('request_submitted_success'.tr()),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_submitting_request'.tr(args: [e.toString()])),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'role_request_title'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            context.locale.languageCode == 'ar' ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
            size: 20,
          ),
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
              _buildHeader(colorScheme),
              const SizedBox(height: 32),
              _buildRoleSelection(colorScheme),
              const SizedBox(height: 32),
              _buildForm(colorScheme),
              const SizedBox(height: 48),
              PrimaryButton(
                text: 'submit_request'.tr(),
                isLoading: _isSubmitting,
                onPressed: _submitRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.nature_people,
            size: 48,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'role_request_title'.tr(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'role_request_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_role'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          colorScheme: colorScheme,
          index: 0,
          title: 'campaign_organizer'.tr(),
          description: 'campaign_organizer_desc'.tr(),
        ),
        const SizedBox(height: 12),
        _buildRoleCard(
          colorScheme: colorScheme,
          index: 1,
          title: 'wilaya_coordinator'.tr(),
          description: 'wilaya_coordinator_desc'.tr(),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required ColorScheme colorScheme,
    required int index,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedRoleIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleIndex = index),
      child: CustomCard(
        padding: EdgeInsets.zero,
        color: isSelected ? colorScheme.primary.withValues(alpha: 0.05) : colorScheme.surfaceContainerLow,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
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
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'personal_info'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'full_name'.tr(),
          hint: 'full_name_hint'.tr(),
          controller: _nameController,
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'phone_number'.tr(),
          hint: 'phone_number_hint'.tr(),
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'request_reason'.tr(),
          hint: 'request_reason_hint'.tr(),
          controller: _reasonController,
        ),
      ],
    );
  }
}
