import 'package:flutter/material.dart';
import '../../../../models/campaign_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/supabase_service.dart';

import '../../../../widgets/custom_buttons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:latlong2/latlong.dart';

class CreateCampaignSheet extends StatefulWidget {
  final UserModel currentUser;
  final VoidCallback? onDrawZoneRequested;
  final List<LatLng>? initialPolygon;

  const CreateCampaignSheet({
    super.key,
    required this.currentUser,
    this.onDrawZoneRequested,
    this.initialPolygon,
  });

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
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  // v3.5: Province selection for provincial campaigns
  int? _selectedProvinceId;
  List<Map<String, dynamic>> _provinces = [];

  // v2.8 Fields
  String? _selectedCoverAsset = 'assets/images/campaigns/national_1.jpg';
  bool _hasZone = false;
  List<LatLng> _zonePolygon = [];

  final List<String> _availableCoverAssets = [
    'assets/images/campaigns/national_1.jpg',
    'assets/images/campaigns/forest_1.jpg',
    'assets/images/campaigns/mountains_1.jpg',
    'assets/images/campaigns/desert_bloom_1.jpg',
    'assets/images/campaigns/coastal_reforestation_1.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _setDefaultType();
    // v3.5: Pre-set province from user
    _selectedProvinceId = widget.currentUser.provinceId;
    if (widget.initialPolygon != null && widget.initialPolygon!.isNotEmpty) {
      _zonePolygon = widget.initialPolygon!;
      _hasZone = true;
    }
    // Load provinces for provincial campaign type
    if (widget.currentUser.isAdmin) {
      _loadProvinces();
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final data = await _supabaseService.getProvinces();
      if (mounted) setState(() => _provinces = data);
    } catch (e) {
      debugPrint('Error loading provinces: $e');
    }
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
    
    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('select_dates_times'.tr())),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate!.year, _startDate!.month, _startDate!.day,
        _startTime!.hour, _startTime!.minute,
      );
      final endDateTime = DateTime(
        _endDate!.year, _endDate!.month, _endDate!.day,
        _endTime!.hour, _endTime!.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('end_date_error'.tr())),
        );
        setState(() => _isLoading = false);
        return;
      }

      final newCampaign = CampaignModel(
        id: 0, // FIX: DB uses INTEGER serial — 0 is excluded from INSERT by toJson() (which omits 'id')
        title: _title,
        description: _description,
        type: _type,
        provinceId: _type == 'provincial' ? (_selectedProvinceId ?? widget.currentUser.provinceId) : widget.currentUser.provinceId,
        organizerId: widget.currentUser.id,
        status: 'active',
        treeGoal: _treeGoal,
        treePlanted: 0,
        startDate: startDateTime,
        endDate: endDateTime,
        coverImageAsset: _selectedCoverAsset,
        hasZone: _hasZone,
        zonePolygon: _zonePolygon.isNotEmpty ? _zonePolygon : null,
      );

      await _supabaseService.createCampaign(newCampaign);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_creating_campaign'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Only admins can change the type freely, otherwise it's restricted by role
    final isAdmin = widget.currentUser.isAdmin;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'create_campaign'.tr(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'campaign_title'.tr(),
                  hintText: 'campaign_title_hint'.tr(),
                  prefixIcon: Icon(Icons.campaign_rounded, color: colorScheme.primary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'enter_title_error'.tr() : null,
                onSaved: (v) => _title = v ?? '',
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'description_label'.tr(),
                  hintText: 'description_hint'.tr(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'enter_description_error'.tr() : null,
                onSaved: (v) => _description = v ?? '',
              ),
              const SizedBox(height: 20),
              
              Text(
                'cover_image'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120, // Increased height for better visibility
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _availableCoverAssets.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final asset = _availableCoverAssets[index];
                    final isSelected = _selectedCoverAsset == asset;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCoverAsset = asset),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.1),
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.2),
                                blurRadius: 12,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              )
                          ],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: Image.asset(
                                asset,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: colorScheme.surfaceContainerHigh,
                                  child: Icon(Icons.image_rounded, color: colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'target'.tr(),
                  prefixIcon: Icon(Icons.park_rounded, color: colorScheme.primary),
                ),
                keyboardType: TextInputType.number,
                initialValue: '1000',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'enter_goal_error'.tr();
                  if (int.tryParse(v) == null) return 'number_error'.tr();
                  return null;
                },
                onSaved: (v) => _treeGoal = int.tryParse(v ?? '') ?? 1000,
              ),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: colorScheme.surface,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'campaign_type'.tr(),
                  prefixIcon: Icon(Icons.category_rounded, color: colorScheme.primary),
                ),
                items: [
                  if (isAdmin) 
                    DropdownMenuItem(value: 'national', child: Text('national_type'.tr())),
                  if (isAdmin || widget.currentUser.role == 'provincial_organizer') 
                    DropdownMenuItem(value: 'provincial', child: Text('provincial_type'.tr())),
                  DropdownMenuItem(value: 'local', child: Text('local_type'.tr())),
                ],
                onChanged: isAdmin ? (v) {
                  setState(() {
                    _type = v!;
                    if (_type == 'provincial' && _provinces.isEmpty) _loadProvinces();
                  });
                } : null,
              ),
              const SizedBox(height: 20),

              // v3.5: Province dropdown for provincial campaigns (admin only)
              if (_type == 'provincial' && isAdmin && _provinces.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  value: _selectedProvinceId,
                  dropdownColor: colorScheme.surface,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'province'.tr(),
                    prefixIcon: Icon(Icons.location_on_rounded, color: colorScheme.primary),
                  ),
                  items: _provinces.map((p) {
                    return DropdownMenuItem<int>(
                      value: p['id'] as int,
                      child: Text(p['name_ar'] as String? ?? p['name'] as String? ?? ''),
                    );
                  }).toList(),
                  validator: (v) => v == null ? 'field_required'.tr() : null,
                  onChanged: (v) => setState(() => _selectedProvinceId = v),
                ),
                const SizedBox(height: 20),
              ],

              Text(
                'start_date_time'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(_startDate == null ? 'select_date'.tr() : DateFormat('yyyy-MM-dd').format(_startDate!)),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(_startTime == null ? 'select_time'.tr() : _startTime!.format(context)),
                      onPressed: () async {
                         final time = await showTimePicker(
                           context: context,
                           initialTime: TimeOfDay.now(),
                         );
                         if (time != null) setState(() => _startTime = time);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'end_date_time'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(_endDate == null ? 'select_date'.tr() : DateFormat('yyyy-MM-dd').format(_endDate!)),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(_endTime == null ? 'select_time'.tr() : _endTime!.format(context)),
                      onPressed: () async {
                         final time = await showTimePicker(
                           context: context,
                           initialTime: TimeOfDay.now(),
                         );
                         if (time != null) setState(() => _endTime = time);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Divider(color: colorScheme.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'geographic_zone'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'define_zone_hint'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _hasZone,
                    activeTrackColor: colorScheme.primary,
                    onChanged: (v) => setState(() => _hasZone = v),
                  ),
                ],
              ),
              
              if (_hasZone) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    if (widget.onDrawZoneRequested != null) {
                      Navigator.pop(context); // Close sheet to show map
                      widget.onDrawZoneRequested!();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('polygon_drawing_mode_hint'.tr())),
                      );
                    }
                  },
                  icon: const Icon(Icons.format_shapes_rounded),
                  label: Text(_zonePolygon.isEmpty ? 'draw_zone'.tr() : 'edit_zone'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_zonePolygon.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'points_count'.tr(args: [_zonePolygon.length.toString()]),
                      style: TextStyle(fontSize: 12, color: colorScheme.primary),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],

              const SizedBox(height: 40),
              
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                  : PrimaryButton(
                      text: 'create_button'.tr(),
                      onPressed: _submit,
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
