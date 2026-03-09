import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/plant_tree_bottom_sheet.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/tree_planting_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = LatLng(34.0, 3.0); // Focus on Algeria
  LatLng? _currentLocation;
  List<TreePlantingModel> _plantings = [];
  bool _isLoading = true;
  StreamSubscription? _plantingsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchPlantings();
    _determinePosition();
  }

  Future<void> _fetchPlantings() async {
    setState(() => _isLoading = true);
    
    _plantingsSubscription = Supabase.instance.client
        .from('tree_plantings')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      if (mounted) {
        setState(() {
          _plantings = data.map((json) => TreePlantingModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint('Error listening to plantings stream: $error');
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _plantingsSubscription?.cancel();
    super.dispose();
  }


  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _moveToCurrentLocation();
    }
  }

  void _moveToCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 13.0);
    }
  }

  void _showPlantingSheet(LatLng position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlantTreeBottomSheet(
        currentLocation: position,
        onPlanted: () {}, // No need to manually refresh, stream handles it
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 5.5,
              minZoom: 4,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  LatLng(18.9, -8.6), // SW corner of Algeria roughly
                  LatLng(37.5, 12.0), // NE corner of Algeria roughly
                ),
              ),
              onLongPress: (tapPosition, point) => _showPlantingSheet(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.green_algeria',
              ),
              MarkerLayer(
                markers: _plantings.where((p) => p.latitude != null && p.longitude != null).map((p) {
                  return Marker(
                    point: LatLng(p.latitude!, p.longitude!),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        // Show pin details popup
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تفاصيل الشجرة قريباً...')),
                        );
                      },
                      child: const Icon(
                        Icons.park,
                        color: AppColors.mossForest,
                        size: 32,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const LinearProgressIndicator(color: AppColors.mossForest),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'btn_location',
            onPressed: _determinePosition,
            backgroundColor: AppColors.linenWhite,
            child: const Icon(Icons.my_location, color: AppColors.slateCharcoal),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'btn_add_tree',
            onPressed: () {
              if (_currentLocation != null) {
                _showPlantingSheet(_currentLocation!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جارٍ تحديد موقعك الحالي...')),
                );
              }
            },
            backgroundColor: AppColors.mossForest,
            child: const Icon(Icons.park, color: Colors.white, size: 28),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.ivorySand, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.mossForest),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ابحث عن منطقة...',
                  style: TextStyle(
                    color: AppColors.oliveGrey,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip('الكل', true),
          const SizedBox(width: 8),
          _buildChip('حملات نشطة', false),
          const SizedBox(width: 8),
          _buildChip('أشجار مغروسة', false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.mossForest : AppColors.linenWhite.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? AppColors.mossForest : AppColors.ivorySand,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : AppColors.slateCharcoal,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
