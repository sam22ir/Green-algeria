import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/models/tree_species.dart';
import '../../../../models/campaign_model.dart';
import '../../../../models/tree_planting_model.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/local_db_service.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  File? _selectedImage;
  bool _isLoadingData = true;
  bool _isPlanting = false;

  @override
  void initState() {
    super.initState();
    _fetchFormData();
  }

  Future<void> _fetchFormData() async {
    try {
      // 1. Fetch species
      final speciesData = await Supabase.instance.client.from('tree_species').select();
      _speciesList = (speciesData as List).map((e) => TreeSpecies.fromJson(e)).toList();
      if (_speciesList.isNotEmpty) {
        _selectedSpecies = _speciesList.first;
      }

      // 2. Fetch active campaigns to link
      _activeCampaigns = await _supabaseService.getActiveCampaigns();

      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return null;

    try {
      final fileExt = _selectedImage!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.$fileExt';
      final filePath = '$userId/$fileName';

      await Supabase.instance.client.storage
          .from('tree-photos')
          .upload(filePath, _selectedImage!);

      final publicUrl = Supabase.instance.client.storage
          .from('tree-photos')
          .getPublicUrl(filePath);
          
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('فشل رفع الصورة المرفقة.');
    }
  }

  Future<void> _plantTree() async {
    if (_selectedSpecies == null) return;
    
    setState(() => _isPlanting = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('المستخدم غير مسجل الدخول');

      bool isOnline = true;
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.none)) {
          isOnline = false;
        }
      } catch (_) {}

      if (isOnline) {
        try {
          // 1. Upload photo if exists
          String? photoUrl;
          if (_selectedImage != null) {
            photoUrl = await _uploadImage(userId);
          }

          // 2. Insert record
          final planting = TreePlantingModel(
            userId: userId,
            campaignId: _selectedCampaign?.id,
            treeSpeciesId: int.tryParse(_selectedSpecies!.id), 
            latitude: widget.currentLocation.latitude,
            longitude: widget.currentLocation.longitude,
            photoUrl: photoUrl,
          );

          await _supabaseService.logTreePlanting(planting);
          await Supabase.instance.client.rpc('increment_trees_planted', params: {'user_id': userId});

          if (mounted) {
            Navigator.pop(context);
            widget.onPlanted();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تسجيل غرس الشجرة بنجاح! شكراً لمساهمتك 🌿'),
                backgroundColor: AppColors.mossForest,
              ),
            );
          }
        } catch (e) {
          isOnline = false; // Fallback to offline on error
          debugPrint('Network error during planting, falling back to offline: $e');
        }
      }

      if (!isOnline) {
        if (_selectedImage == null) {
           throw Exception('الرجاء إرفاق صورة أولاً ليتم حفظ الشجرة في وضع عدم الاتصال');
        }
        
        // Offline Fallback Save
        final record = {
          'id': const Uuid().v4(),
          'user_id': userId,
          'latitude': widget.currentLocation.latitude,
          'longitude': widget.currentLocation.longitude,
          'species_id': int.tryParse(_selectedSpecies!.id),
          'campaign_id': _selectedCampaign?.id,
          'image_path': _selectedImage!.path,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        };
        await LocalDbService().enqueuePlanting(record);

        if (mounted) {
          Navigator.pop(context);
          widget.onPlanted();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم الحفظ محلياً لعدم توفر إنترنت. ستتم المزامنة لاحقاً 📶'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
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
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            'توثيق غرس شجرة',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.slateCharcoal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'أضف تفاصيل الشجرة التي قمت بغرسها في هذا الموقع.',
            style: TextStyle(color: AppColors.oliveGrey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_isLoadingData)
            const Center(child: CircularProgressIndicator(color: AppColors.mossForest))
          else ...[
            // Photo Upload
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.ivorySand, width: 2),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: AppColors.mossForest, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'التقط صورة للشجرة (اختياري)',
                            style: TextStyle(color: AppColors.oliveGrey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.white),
                          onPressed: () => setState(() => _selectedImage = null),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Species Searchable Autocomplete
            const Text('نوع الشجرة', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slateCharcoal)),
            const SizedBox(height: 8),
            Autocomplete<TreeSpecies>(
              displayStringForOption: (TreeSpecies option) => option.nameAr,
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
                // Initialize the text field with the default selected species if not already set
                if (textEditingController.text.isEmpty && _selectedSpecies != null) {
                  textEditingController.text = _selectedSpecies!.nameAr;
                }
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن نوع الشجرة...',
                    hintStyle: const TextStyle(color: AppColors.oliveGrey),
                    prefixIcon: const Icon(Icons.search, color: AppColors.mossForest),
                    suffixIcon: _selectedSpecies != null 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.oliveGrey),
                            onPressed: () {
                              textEditingController.clear();
                              setState(() => _selectedSpecies = null);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.ivorySand),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.ivorySand),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.mossForest, width: 2),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<TreeSpecies> onSelected, Iterable<TreeSpecies> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    color: Colors.white,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 48, // Match bottom sheet padding
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.ivorySand),
                        itemBuilder: (BuildContext context, int index) {
                          final TreeSpecies option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.nameAr,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slateCharcoal, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${option.nameEn} ${option.nameScientific != null ? "(${option.nameScientific})" : ""}',
                                    style: const TextStyle(color: AppColors.oliveGrey, fontSize: 13),
                                    textDirection: TextDirection.ltr,
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
            const SizedBox(height: 16),

            // Campaign Dropdown (Optional)
            const Text('ربط بحملة نشطة (اختياري)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slateCharcoal)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ivorySand),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CampaignModel?>(
                  value: _selectedCampaign,
                  isExpanded: true,
                  hint: const Text('أنا أغرس بشكل فردي'),
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.mossForest),
                  items: [
                    const DropdownMenuItem<CampaignModel?>(
                      value: null,
                      child: Text('عمل فردي (ليست ضمن حملة)', style: TextStyle(color: AppColors.oliveGrey)),
                    ),
                    ..._activeCampaigns.map((campaign) {
                      return DropdownMenuItem<CampaignModel?>(
                        value: campaign,
                        child: Text(
                          campaign.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slateCharcoal),
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
              text: 'تأكيد الغرس',
              isLoading: _isPlanting,
              onPressed: _plantTree,
            ),
          ],
        ],
      ),
    );
  }
}
