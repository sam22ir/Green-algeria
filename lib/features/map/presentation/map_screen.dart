import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'widgets/plant_tree_bottom_sheet.dart';
import 'widgets/tree_details_bottom_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/tutorial_overlay.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../models/tree_planting_model.dart';
import '../../../models/campaign_model.dart';
import '../../../models/user_model.dart';
import '../../../models/tree_species.dart';
import '../../../services/supabase_service.dart';
import '../../campaigns/presentation/widgets/create_campaign_sheet.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:path_provider/path_provider.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final LatLng _initialCenter = const LatLng(28.0339, 1.6596); // Geographic center of Algeria
  LatLng? _currentLocation;
  List<TreePlantingModel> _plantings = [];
  List<CampaignModel> _campaigns = [];
  Map<int, TreeSpecies> _speciesMap = {}; // FIX: key is int (tree_species.id is INTEGER)
  UserModel? _currentUser;
  bool _isLoading = true;
  String _selectedFilter = 'all'; // filter: 'all', 'campaigns', 'trees', 'none'
  Timer? _debounce;
  Timer? _loadDebounce;
  StreamSubscription? _plantingsSubscription;
  StreamSubscription? _campaignsSubscription;
  late Future<CacheStore> _cacheStoreFuture;
  bool _isDrawingMode = false;
  List<LatLng> _tempPolygon = [];
  Map<String, String> _planterNames = {}; // userId → fullName cache

  @override
  void initState() {
    super.initState();
    _cacheStoreFuture = _initCacheStore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _determinePosition();
      // Navigate to a specific tree if navigated from Profile screen
      final extra = GoRouterState.of(context).extra;
      if (extra is Map<String, dynamic>) {
        final lat = extra['lat'] as double?;
        final lng = extra['lng'] as double?;
        if (lat != null && lng != null) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) _mapController.move(LatLng(lat, lng), 16.0);
          });
        }
      }
    });
  }



  Future<CacheStore> _initCacheStore() async {
    final cacheDir = await getTemporaryDirectory();
    return FileCacheStore('${cacheDir.path}/map_tiles');
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadUserRole();
    await _fetchSpecies();
    _listenToCampaigns();
    _fetchPlantings();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = await SupabaseService().getUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  Future<void> _fetchSpecies() async {
    try {
      final response = await Supabase.instance.client.from('tree_species').select();
      final speciesList = (response as List).map((s) => TreeSpecies.fromJson(s)).toList();
      if (mounted) {
        setState(() {
          _speciesMap = {for (var s in speciesList) s.id: s};
        });
      }
    } catch (e) {
      debugPrint('Error fetching species: $e');
    }
  }

  void _listenToCampaigns() {
    try {
      _campaignsSubscription = Supabase.instance.client
          .from('campaigns')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> data) {
        if (mounted) {
          setState(() {
            _campaigns = data
                .where((json) => json['has_zone'] == true && json['status'] == 'active')
                .map((json) => CampaignModel.fromJson(json))
                .toList();
          });
        }
      }, onError: (error) {
        debugPrint('Error listening to campaigns stream: $error');
      });
    } catch (e) {
      debugPrint('Error initiating campaigns stream: $e');
    }
  }

  Future<void> _fetchPlantings() async {
    // Cancel any existing subscription first to prevent stream accumulation
    await _plantingsSubscription?.cancel();
    _plantingsSubscription = null;
    try {
      _plantingsSubscription = Supabase.instance.client
          .from('tree_plantings')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> data) async {
        if (mounted) {
          final models = data.map((json) => TreePlantingModel.fromJson(json)).toList();
          setState(() {
            _plantings = models;
            _isLoading = false;
          });
          // Fetch planter names for all unique userIds
          await _fetchPlanterNames(models.map((t) => t.userId).toSet());
        }
      }, onError: (error) {
        debugPrint('Error listening to plantings stream: $error');
        if (mounted) setState(() => _isLoading = false);
      });
    } catch (e) {
      debugPrint('Error initiating plantings stream: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPlanterNames(Set<String> userIds) async {
    if (userIds.isEmpty) return;
    try {
      final missing = userIds.where((id) => !_planterNames.containsKey(id)).toList();
      if (missing.isEmpty) return;
      final response = await Supabase.instance.client
          .from('users')
          .select('id, full_name')
          .inFilter('id', missing);
      if (mounted) {
        setState(() {
          for (final row in response as List) {
            final id = row['id']?.toString() ?? '';
            final name = row['full_name']?.toString() ?? '';
            if (id.isNotEmpty) _planterNames[id] = name;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching planter names: $e');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _loadDebounce?.cancel();
    _plantingsSubscription?.cancel();
    _campaignsSubscription?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&countrycodes=dz&limit=1'
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'GreenAlgeriaApp/1.0'},
      );
      final results = jsonDecode(response.body) as List;
      if (results.isNotEmpty && mounted) {
        final lat = double.parse(results[0]['lat']);
        final lon = double.parse(results[0]['lon']);
        final target = LatLng(lat, lon);
        _mapController.move(target, 13.0);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('location_not_found'.tr())),
        );
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('location_search_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('location_service_disabled'.tr())),
          );
        }
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('location_permission_denied'.tr())),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('location_permission_denied'.tr())),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation!, 15.0);
      }
    } catch (e) {
      debugPrint('Error determining position: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('location_search_error'.tr())),
        );
      }
    }
  }

  /// يُستدعى عند ضغط زر الموقع: يتحرك فوراً إذا الموقع محفوظ، وإلا يطلبه
  void _centerOnUser() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    } else {
      _determinePosition();
    }
  }

  void _moveToCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 13.0);
    }
  }

  void _showPlantingSheet(LatLng position) {
    if (_isDrawingMode) return; // Don't open planting sheet while drawing zone
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlantTreeBottomSheet(
        currentLocation: position,
        onPlanted: () {},
      ),
    );
  }

  void _enterDrawingMode() {
    setState(() {
      _isDrawingMode = true;
      _tempPolygon = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('tap_to_draw_hint'.tr()),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _finishDrawing() {
    setState(() {
      _isDrawingMode = false;
    });
    // Re-open campaign sheet with the polygon
    _showCreateCampaignSheet(initialPolygon: _tempPolygon);
  }

  void _showCreateCampaignSheet({List<LatLng>? initialPolygon}) {
    if (_currentUser == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateCampaignSheet(
        currentUser: _currentUser!,
        initialPolygon: initialPolygon,
        onDrawZoneRequested: _enterDrawingMode,
      ),
    ).then((result) {
      if (result == true) {
        _loadInitialData(); // Refresh campaigns on return
      }
    });
  }

  void _showTreeDetailsSheet(TreePlantingModel tree) {
    final species = (tree.treeSpeciesId != null) ? _speciesMap[tree.treeSpeciesId] : null;
    final Map<String, dynamic> enrichedData = {
      ...tree.toJson(),
      // FIX: pass planted_at explicitly as ISO string
      'planted_at': tree.plantedAt?.toIso8601String(),
      // FIX: pass planter_name — will be resolved asynchronously after sheet opens
      'planter_name': _planterNames[tree.userId],
      'planter_id': tree.userId,
      if (species != null)
        'tree_species': {
          'name_ar': species.nameAr,
          'name_en': species.nameEn,
          'name_scientific': species.nameScientific,
          'image_asset_path': species.imageAssetPath,
        },
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TreeDetailsBottomSheet(
        treeData: enrichedData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TutorialOverlay(
      tutorial: AppTutorials.map,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 5.5,
              onPositionChanged: (position, hasGesture) {
                // No-op: stream already keeps data in sync automatically.
                // Calling _fetchPlantings() here would create duplicate subscriptions.
              },
              onLongPress: (tapPosition, point) => _showPlantingSheet(point),
              onTap: (tapPosition, point) {
                if (_isDrawingMode) {
                  setState(() {
                    _tempPolygon.add(point);
                  });
                } else {
                  _handleMapTap(point);
                }
              },
            ),
            children: [
              FutureBuilder<CacheStore>(
                future: _cacheStoreFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'dz.green_algeria.app',
                    );
                  }
                  return TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dz.green_algeria.app',
                    tileProvider: CachedTileProvider(
                      store: snapshot.data!,
                    ),
                    tileBuilder: (context, tileWidget, tile) {
                      return ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          theme.brightness == Brightness.dark 
                            ? Colors.grey.withValues(alpha: 0.1) 
                            : Colors.transparent,
                          BlendMode.saturation,
                        ),
                        child: tileWidget,
                      );
                    },
                  );
                },
              ),
              if (_tempPolygon.isNotEmpty)
                PolygonLayer<Object>(
                  polygons: [
                    Polygon(
                      points: _tempPolygon,
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      borderColor: colorScheme.primary,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
              if (_tempPolygon.length >= 3)
                MarkerLayer(
                  markers: _tempPolygon.map((point) {
                    return Marker(
                      point: point,
                      width: 12,
                      height: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              PolygonLayer<Object>(
                polygons: _campaigns
                    .where((c) => _selectedFilter != 'trees' && _selectedFilter != 'none')
                    .where((c) => c.hasZone && c.zonePolygon != null && c.zonePolygon!.isNotEmpty)
                    .map<Polygon<Object>>((c) => Polygon(
                          points: c.zonePolygon!,
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderColor: colorScheme.primary.withValues(alpha: 0.6),
                          borderStrokeWidth: 2,
                        ))
                    .toList(),
              ),
              MarkerLayer(
                markers: _plantings
                    .where((p) => p.latitude != null && p.longitude != null)
                    .where((p) {
                      // Hide trees when filter is 'campaigns' or 'none'
                      if (_selectedFilter == 'campaigns') return false;
                      if (_selectedFilter == 'none') return false;
                      return true;
                    })
                    .map((p) {
                  final species = p.treeSpeciesId != null ? _speciesMap[p.treeSpeciesId] : null;
                  final assetPath = species?.imageAssetPath;

                  return Marker(
                    point: LatLng(p.latitude!, p.longitude!),
                    width: 45,
                    height: 45,
                    child: GestureDetector(
                      onTap: () => _showTreeDetailsSheet(p),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: assetPath != null
                            ? Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.asset(assetPath, errorBuilder: (c, e, s) => Icon(Icons.park_rounded, color: colorScheme.primary)),
                              )
                            : Icon(
                                Icons.park_rounded,
                                color: colorScheme.primary,
                                size: 28,
                              ),
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
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_isDrawingMode)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() {
                        _isDrawingMode = false;
                        _tempPolygon = [];
                      }),
                      icon: const Icon(Icons.close_rounded),
                      label: Text('cancel'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _tempPolygon.length < 3 ? null : _finishDrawing,
                      icon: const Icon(Icons.check_rounded),
                      label: Text('done'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  _buildSearchBar(theme),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    LinearProgressIndicator(
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  const SizedBox(height: 12),
                  _buildFilterChips(theme),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentUser != null && _currentUser!.isOrganizer && !_isDrawingMode) ...[
            FloatingActionButton(
              heroTag: 'btn_add_campaign',
              onPressed: () => _showCreateCampaignSheet(),
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              elevation: 6,
              child: const Icon(Icons.add_business_rounded),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: 'btn_location',
            onPressed: _centerOnUser,
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.primary,
            elevation: 4,
            child: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 800), () {
                  if (value.length >= 3) {
                    _searchLocation(value);
                  }
                });
              },
              onSubmitted: _searchLocation,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'search_area'.tr(),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildChip(theme, 'all', 'all'),
          const SizedBox(width: 8),
          _buildChip(theme, 'active_campaigns', 'campaigns'),
          const SizedBox(width: 8),
          _buildChip(theme, 'planted_trees', 'trees'),
          const SizedBox(width: 8),
          _buildChip(theme, 'hide_all', 'none'),
        ],
      ),
    );
  }

  Widget _buildChip(ThemeData theme, String labelKey, String value) {
    final colorScheme = theme.colorScheme;
    final bool isActive = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.1),
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Text(
          labelKey.tr(),
          style: TextStyle(
            color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    var intersections = 0;
    for (var i = 0; i < polygon.length; i++) {
      var p1 = polygon[i];
      var p2 = polygon[(i + 1) % polygon.length];

      if (p1.longitude > p2.longitude) {
        var temp = p1;
        p1 = p2;
        p2 = temp;
      }

      if (point.longitude > p1.longitude && point.longitude <= p2.longitude) {
        var vt = (point.longitude - p1.longitude) / (p2.longitude - p1.longitude);
        if (point.latitude < p1.latitude + vt * (p2.latitude - p1.latitude)) {
          intersections++;
        }
      }
    }
    return intersections % 2 != 0;
  }

  void _handleMapTap(LatLng point) {
    if (_selectedFilter == 'trees') return;

    for (var campaign in _campaigns) {
      if (campaign.hasZone && campaign.zonePolygon != null) {
        if (_isPointInPolygon(point, campaign.zonePolygon!)) {
          _showCampaignDetails(campaign);
          return;
        }
      }
    }
  }

  void _showCampaignDetails(CampaignModel campaign) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.campaign_rounded, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        campaign.type.tr(),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              campaign.description ?? '',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Potential navigation to full campaign details
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('view_all'.tr()),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
