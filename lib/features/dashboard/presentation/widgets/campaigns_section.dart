import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../models/campaign_model.dart';
import '../../../../core/utils/campaign_utils.dart';

class DashboardCampaignsSection extends StatefulWidget {
  const DashboardCampaignsSection({super.key});

  @override
  State<DashboardCampaignsSection> createState() => _DashboardCampaignsSectionState();
}

class _DashboardCampaignsSectionState extends State<DashboardCampaignsSection> {
  List<CampaignModel> _campaigns = [];
  bool _isLoading = true;
  String? _currentUserRole;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();
  String _selectedType = 'national';
  int? _selectedProvinceId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final profile = await SupabaseService().getUserProfile();
    _currentUserRole = profile?.role;
    final campaigns = await SupabaseService().getAllCampaigns();
    if (mounted) {
      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });
    }
  }

  Future<void> _createCampaign() async {
    if (_titleController.text.isEmpty || _goalController.text.isEmpty) return;
    if (_selectedType != 'national' && _selectedProvinceId == null) return;

    final colorScheme = Theme.of(context).colorScheme;

    final newCamp = CampaignModel(
      id: 0, // FIX: DB uses INTEGER serial — 0 is ignored on INSERT (DB auto-assigns)
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      provinceId: _selectedProvinceId,
      organizerId: AuthService().firebaseUser?.id,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      status: 'active',
      treeGoal: int.parse(_goalController.text),
      treePlanted: 0,
    );

    await SupabaseService().createCampaign(newCamp);

    final topic = _selectedType == 'national' ? 'national-campaigns' : 'province-$_selectedProvinceId-campaigns';
    await NotificationService.sendToTopic(
      topic: topic,
      title: 'campaign_created_success'.tr(),
      body: _titleController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('campaign_created_success'.tr()), 
          backgroundColor: colorScheme.primary,
        ),
      );
      _loadData();
    }
  }

  void _showCreateCampaignSheet() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'create_campaign'.tr(), 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface), 
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'campaign_title_ar'.tr(),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: colorScheme.surface,
                  decoration: InputDecoration(
                    labelText: 'campaign_type'.tr(),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: [
                    DropdownMenuItem(value: 'national', child: Text('national'.tr())),
                    DropdownMenuItem(value: 'provincial', child: Text('provincial'.tr())),
                    if (_currentUserRole == 'developer') DropdownMenuItem(value: 'local', child: Text('local'.tr())),
                  ],
                  onChanged: (val) => setModalState(() => _selectedType = val!),
                ),
                if (_selectedType != 'national') ...[
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: SupabaseService().getProvinces(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return LinearProgressIndicator(color: colorScheme.primary);
                      return DropdownButtonFormField<int>(
                        value: _selectedProvinceId,
                        dropdownColor: colorScheme.surface,
                        decoration: InputDecoration(
                          labelText: 'select_province'.tr(),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLow,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: snapshot.data!.map((p) => DropdownMenuItem(value: p['id'] as int, child: Text(context.locale.languageCode == 'ar' ? p['name_ar'] : p['name_en']))).toList(),
                        onChanged: (val) => setModalState(() => _selectedProvinceId = val),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _goalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'tree_goal'.tr(),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _createCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('create'.tr()),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      color: colorScheme.surface,
      child: ExpansionTile(
        leading: Icon(Icons.nature_people_outlined, color: colorScheme.primary),
        title: Text(
          'campaign_management'.tr(), 
          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        trailing: IconButton(
          icon: Icon(Icons.add_circle, color: colorScheme.primary),
          onPressed: _showCreateCampaignSheet,
        ),
        children: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(20), 
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          else if (_campaigns.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20), 
              child: Text(
                'no_campaigns_found'.tr(),
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _campaigns.length,
              itemBuilder: (context, index) {
                final camp = _campaigns[index];
                final progress = camp.treeGoal > 0 ? (camp.treePlanted / camp.treeGoal) : 0.0;
                return ListTile(
                  title: Text(camp.title, style: TextStyle(color: colorScheme.onSurface)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${camp.type.campaignTypeLabel} | ${camp.status.tr()}', 
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress, 
                        color: colorScheme.primary, 
                        backgroundColor: colorScheme.surfaceContainerLow,
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
