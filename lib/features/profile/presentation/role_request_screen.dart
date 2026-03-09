import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/supabase_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء الحقول الإلزامية (الاسم ورقم الهاتف)'),
          backgroundColor: Color(0xFFD9534F),
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
        'user_id': user.uid,
        'requested_role': requestedRole,
        'status': 'pending',
        'reason': _reasonController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.requestSubmittedSuccess),
            backgroundColor: AppColors.mossForest,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إرسال الطلب: $e'),
            backgroundColor: const Color(0xFFD9534F),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.linenWhite,
      appBar: AppBar(
        backgroundColor: AppColors.linenWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.roleRequestTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.slateCharcoal,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.slateCharcoal, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 32),
              _buildRoleSelection(l10n),
              const SizedBox(height: 32),
              _buildForm(l10n),
              const SizedBox(height: 48),
              PrimaryButton(
                text: l10n.submitRequest,
                isLoading: _isSubmitting,
                onPressed: _submitRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.mossForest.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.nature_people,
            size: 48,
            color: AppColors.mossForest,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.roleRequestTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.slateCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.roleRequestSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.oliveGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectRole,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.slateCharcoal,
          ),
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          index: 0,
          title: l10n.campaignOrganizer,
          description: l10n.campaignOrganizerDesc,
        ),
        const SizedBox(height: 12),
        _buildRoleCard(
          index: 1,
          title: l10n.wilayaCoordinator,
          description: l10n.wilayaCoordinatorDesc,
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required int index,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedRoleIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleIndex = index),
      child: CustomCard(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.mossForest : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.mossForest : AppColors.ivorySand,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slateCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.oliveGrey,
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

  Widget _buildForm(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.personalInfo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.slateCharcoal,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: l10n.fullName,
          hint: l10n.fullNameHint,
          controller: _nameController,
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: l10n.phoneNumber,
          hint: l10n.phoneNumberHint,
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: l10n.requestReason,
          hint: l10n.requestReasonHint,
          controller: _reasonController,
        ),
      ],
    );
  }
}
