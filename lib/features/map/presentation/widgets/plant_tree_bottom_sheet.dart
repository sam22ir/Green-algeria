import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';
import '../../../../widgets/custom_buttons.dart';
import '../../../../models/tree_species.dart';
import '../../../../models/campaign_model.dart';
import '../../../../models/tree_planting_model.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/local_db_service.dart';
import '../../../../services/connectivity_service.dart';

class PlantTreeBottomSheet extends StatefulWidget {
  final LatLng currentLocation;
  final VoidCallback onPlanted;

  const PlantTreeBottomSheet({
    super.key,
    required this.currentLocation,
    required this.onPlanted,
  });

  @override
  State<PlantTreeBottomSheet> createState() => _PlantTreeBottomSheetState();
}

class _PlantTreeBottomSheetState extends State<PlantTreeBottomSheet> {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<TreeSpecies> _speciesList = [];
  TreeSpecies? _selectedSpecies;
  
  List<CampaignModel> _activeCampaigns = [];
  CampaignModel? _selectedCampaign;

  bool _isLoadingData = true;
  bool _isPlanting = false;

  @override
  void initState() {
    super.initState();
    _fetchFormData();
  }

  Future<void> _fetchFormData() async {
    try {
      final speciesData = await Supabase.instance.client.from('tree_species').select();
      _speciesList = (speciesData as List).map((e) => TreeSpecies.fromJson(e)).toList();
      if (_speciesList.isNotEmpty) {
        _selectedSpecies = _speciesList.first;
      }

      _activeCampaigns = await _supabaseService.getActiveCampaigns();

      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error_loading'.tr()}: $e')),
        );
      }
    }
  }


  // RADICAL FIX: Three-phase approach:
  // Phase 0: Fresh connectivity check.
  // Phase 1 (critical): insert into Supabase. On success → green snackbar + map refresh.
  // Phase 2 (non-critical): RPC increment counter.
  // If Phase 1 FAILS: show ACTUAL error code, then save locally ONLY if it's a network error.
  Future<void> _plantTree() async {
    if (_selectedSpecies == null) return;
    setState(() => _isPlanting = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('user_not_logged_in'.tr())),
        );
        setState(() => _isPlanting = false);
      }
      return;
    }

    // Phase 0: Fresh connectivity check
    final isOnline = await ConnectivityService().checkConnection();
    debugPrint('PlantTree: isOnline=$isOnline, userId=$userId');

    if (!isOnline) {
      // Definitely offline — save locally immediately
      await _saveLocally(userId);
      if (mounted) setState(() => _isPlanting = false);
      return;
    }

    try {
      // ✅ Phase 1: Insert tree into Supabase (CRITICAL)
      final planting = TreePlantingModel(
        userId: userId,
        campaignId: _selectedCampaign?.id,
        treeSpeciesId: _selectedSpecies!.id,
        latitude: widget.currentLocation.latitude,
        longitude: widget.currentLocation.longitude,
      );
      debugPrint('PlantTree: Attempting Supabase insert...');
      await _supabaseService.logTreePlanting(planting);
      debugPrint('PlantTree: Insert SUCCESS');

      // ✅ Insert succeeded — close sheet and show success
      if (mounted) {
        Navigator.pop(context);
        widget.onPlanted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('planting_success_msg'.tr()),
            backgroundColor: const Color(0xFF606C38),
          ),
        );
      }

      // ⚡ Phase 2: Increment counter (NON-CRITICAL)
      try {
        await Supabase.instance.client.rpc(
          'increment_trees_planted',
          params: {'user_id': userId},
        );
      } catch (rpcErr) {
        debugPrint('RPC increment_trees_planted failed (non-critical): $rpcErr');
      }

    } catch (e) {
      // ❌ Phase 1 FAILED while online
      final errMsg = e.toString();
      debugPrint('PlantTree: Supabase insert FAILED: $errMsg');

      // Detect if it's a permission/RLS error vs a real network error.
      // PostgrestException codes: 42501 = insufficient_privilege, PGRST xxx = RLS
      final bool isPermissionError = errMsg.contains('42501') ||
          errMsg.contains('permission denied') ||
          errMsg.contains('PGRST') ||
          errMsg.contains('403') ||
          errMsg.contains('row-level security');

      if (isPermissionError) {
        // RLS is blocking — DO NOT save locally (tree will duplicate on next online session)
        // Show the actual error so admin can diagnose
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('خطأ في الصلاحيات'),
              content: Text('تعذّر غرس الشجرة بسبب سياسة RLS في Supabase.\n\nرمز الخطأ:\n$errMsg'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
      } else {
        // Real network/timeout error — safe to save locally
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الاتصال: $errMsg'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        await _saveLocally(userId);
      }
    } finally {
      if (mounted) setState(() => _isPlanting = false);
    }
  }

  /// Save tree planting record to local SQLite queue (offline fallback)
  Future<void> _saveLocally(String userId) async {
    try {
      final record = {
        'id': const Uuid().v4(),
        'user_id': userId,
        'latitude': widget.currentLocation.latitude,
        'longitude': widget.currentLocation.longitude,
        'species_id': _selectedSpecies!.id,
        'campaign_id': _selectedCampaign?.id,
        'image_path': null,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
      await LocalDbService().enqueuePlanting(record);
      debugPrint('PlantTree: Saved locally for later sync.');

      if (mounted) {
        Navigator.pop(context);
        widget.onPlanted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('sync_later_msg'.tr()),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (localErr) {
      debugPrint('Local save failed: $localErr');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error'.tr()}: $localErr')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            'plant_tree_title'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'plant_tree_desc'.tr(),
            style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5), 
                fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_isLoadingData)
            Center(child: CircularProgressIndicator(color: colorScheme.primary))
          else ...[
            _buildSpeciesPreview(colorScheme, languageCode),
            const SizedBox(height: 20),
            
            Text(
                'tree_species'.tr(), 
                style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: colorScheme.onSurface,
                ),
            ),
            const SizedBox(height: 8),
            Autocomplete<TreeSpecies>(
              displayStringForOption: (TreeSpecies option) => option.getLocalizedName(languageCode),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _speciesList;
                }
                final query = textEditingValue.text.toLowerCase();
                return _speciesList.where((species) {
                  return species.nameAr.toLowerCase().contains(query) ||
                         species.nameEn.toLowerCase().contains(query) ||
                         (species.nameScientific?.toLowerCase().contains(query) ?? false);
                });
              },
              onSelected: (TreeSpecies selection) {
                setState(() => _selectedSpecies = selection);
              },
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                if (textEditingController.text.isEmpty && _selectedSpecies != null) {
                  textEditingController.text = _selectedSpecies!.getLocalizedName(languageCode);
                }
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'search_species_hint'.tr(),
                    hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                    suffixIcon: _selectedSpecies != null 
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                            onPressed: () {
                              textEditingController.clear();
                              setState(() => _selectedSpecies = null);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<TreeSpecies> onSelected, Iterable<TreeSpecies> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    color: colorScheme.surface,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 48,
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: options.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.05)),
                        itemBuilder: (BuildContext context, int index) {
                          final TreeSpecies option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.getLocalizedName(languageCode),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        color: colorScheme.onSurface, 
                                        fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${languageCode == 'ar' ? option.nameEn : option.nameAr} ${option.nameScientific != null ? "(${option.nameScientific})" : ""}',
                                    style: TextStyle(
                                        color: colorScheme.onSurface.withValues(alpha: 0.5), 
                                        fontSize: 13,
                                    ),
                                    textDirection: ui.TextDirection.ltr,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20), 
            
            Text(
                'link_campaign'.tr(), 
                style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: colorScheme.onSurface,
                ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CampaignModel?>(
                  value: _selectedCampaign,
                  isExpanded: true,
                  hint: Text('individual_planting'.tr()),
                  dropdownColor: colorScheme.surface,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary),
                  items: [
                    DropdownMenuItem<CampaignModel?>(
                      value: null,
                      child: Text(
                          'not_part_of_campaign'.tr(), 
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                    ..._activeCampaigns.map((campaign) {
                      return DropdownMenuItem<CampaignModel?>(
                        value: campaign,
                        child: Text(
                          campaign.title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: colorScheme.onSurface,
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedCampaign = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            PrimaryButton(
              text: 'confirm_planting'.tr(),
              isLoading: _isPlanting,
              onPressed: _plantTree,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeciesPreview(ColorScheme colorScheme, String languageCode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1), width: 1.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_selectedSpecies != null && _selectedSpecies?.imageAssetPath != null)
              Image.asset(
                _selectedSpecies!.imageAssetPath!,
                fit: BoxFit.cover,
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.park_outlined, size: 48, color: colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'select_species_preview'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
                  ),
                ],
              ),
            
            // Overlay with Title
            if (_selectedSpecies != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    _selectedSpecies!.getLocalizedName(languageCode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
