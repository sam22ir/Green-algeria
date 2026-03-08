import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/tree_species.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  List<TreeSpecies> _speciesList = [];
  TreeSpecies? _selectedSpecies;
  bool _isLoading = true;
  bool _isPlanting = false;

  @override
  void initState() {
    super.initState();
    _fetchSpecies();
  }

  Future<void> _fetchSpecies() async {
    try {
      final data = await Supabase.instance.client.from('tree_species').select();
      setState(() {
        _speciesList = (data as List).map((e) => TreeSpecies.fromJson(e)).toList();
        if (_speciesList.isNotEmpty) {
          _selectedSpecies = _speciesList.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الأنواع: $e')),
        );
      }
    }
  }

  Future<void> _plantTree() async {
    if (_selectedSpecies == null) return;
    
    setState(() => _isPlanting = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('المستخدم غير مسجل الدخول');

      await Supabase.instance.client.from('planted_trees').insert({
        'planter_id': userId,
        'species_id': _selectedSpecies!.id,
        'latitude': widget.currentLocation.latitude,
        'longitude': widget.currentLocation.longitude,
      });

      // Also increment user's total trees planted
      await Supabase.instance.client.rpc('increment_trees_planted', params: {'user_id': userId});

      if (mounted) {
        Navigator.pop(context);
        widget.onPlanted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل غرس الشجرة بنجاح! شكراً لمساهمتك.'),
            backgroundColor: AppColors.mossForest,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التسجيل: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlanting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.linenWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                color: AppColors.ivorySand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'غرس شجرة جديدة',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.slateCharcoal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'اختر نوع الشجرة التي قمت بغرسها في هذا الموقع.',
            style: TextStyle(color: AppColors.oliveGrey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.mossForest))
          else if (_speciesList.isEmpty)
            const Center(child: Text('لا توجد أنواع متاحة حالياً.'))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.ivorySand),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TreeSpecies>(
                  value: _selectedSpecies,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.mossForest),
                  items: _speciesList.map((species) {
                    return DropdownMenuItem<TreeSpecies>(
                      value: species,
                      child: Row(
                        children: [
                          const Icon(Icons.park, color: AppColors.mossForest, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            species.nameAr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.slateCharcoal,
                            ),
                          ),
                          if (species.idealRegion != null) ...[
                            const Spacer(),
                            Text(
                              species.idealRegion!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.oliveGrey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedSpecies = val);
                  },
                ),
              ),
            ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: 'تأكيد الغرس',
            isLoading: _isPlanting,
            onPressed: _plantTree,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
