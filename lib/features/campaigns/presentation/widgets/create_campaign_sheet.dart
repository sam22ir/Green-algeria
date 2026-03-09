import 'package:flutter/material.dart';
import '../../../../models/campaign_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreateCampaignSheet extends StatefulWidget {
  final UserModel currentUser;

  const CreateCampaignSheet({super.key, required this.currentUser});

  @override
  State<CreateCampaignSheet> createState() => _CreateCampaignSheetState();
}

class _CreateCampaignSheetState extends State<CreateCampaignSheet> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  
  String _title = '';
  String _description = '';
  int _treeGoal = 1000;
  String _type = 'local';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setDefaultType();
  }

  void _setDefaultType() {
    if (widget.currentUser.role == 'developer' || widget.currentUser.role == 'initiative_owner') {
      _type = 'national';
    } else if (widget.currentUser.role == 'provincial_organizer') {
      _type = 'provincial';
    } else {
      _type = 'local';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final newCampaign = CampaignModel(
        id: 0, // Ignored by Supabase on insert
        title: _title,
        description: _description,
        type: _type,
        provinceId: widget.currentUser.provinceId,
        organizerId: widget.currentUser.id, // Using user ID as organizer ID for now
        status: 'active',
        treeGoal: _treeGoal,
        treePlanted: 0,
        startDate: DateTime.now(),
        // Default 30 days duration
        endDate: DateTime.now().add(const Duration(days: 30)), 
      );

      await _supabaseService.createCampaign(newCampaign);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating campaign: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Only admins can change the type freely, otherwise it's restricted by role
    final isAdmin = widget.currentUser.isAdmin;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.linenWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Campaign', // Translation placeholder
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slateCharcoal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Campaign Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please enter a title' : null,
                onSaved: (v) => _title = v ?? '',
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Please enter a description' : null,
                onSaved: (v) => _description = v ?? '',
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.target,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: '1000',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a goal';
                  if (int.tryParse(v) == null) return 'Must be a number';
                  return null;
                },
                onSaved: (v) => _treeGoal = int.tryParse(v ?? '') ?? 1000,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Campaign Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  if (isAdmin) const DropdownMenuItem(value: 'national', child: Text('National')),
                  if (isAdmin || widget.currentUser.role == 'provincial_organizer') 
                    const DropdownMenuItem(value: 'provincial', child: Text('Provincial')),
                  const DropdownMenuItem(value: 'local', child: Text('Local')),
                ],
                onChanged: isAdmin ? (v) => setState(() => _type = v!) : null,
              ),
              const SizedBox(height: 32),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.mossForest))
                  : PrimaryButton(
                      text: 'Create',
                      onPressed: _submit,
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
