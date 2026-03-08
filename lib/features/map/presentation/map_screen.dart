import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/plant_tree_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final LatLng _center = const LatLng(36.7538, 3.0588); // Algiers

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Set map style here (Silver/Forest) in the future
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 6.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PlantTreeBottomSheet(
              currentLocation: _center, // Defaults to _center for now, ideally device location
              onPlanted: () {
                // Refresh map markers later
              },
            ),
          );
        },
        backgroundColor: AppColors.mossForest,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, // Bottom-left for RTL
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
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.ivorySand, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                  'ابحث عن ولاية أو منطقة',
                  style: TextStyle(
                    color: AppColors.oliveGrey,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: AppColors.ivorySand,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const Icon(Icons.tune, color: AppColors.slateCharcoal),
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
        color: isActive ? AppColors.mossForest : AppColors.linenWhite.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? AppColors.mossForest : AppColors.ivorySand,
        ),
        boxShadow: [
          if (!isActive)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
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
