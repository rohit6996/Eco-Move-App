import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';
import 'map_plan_screen.dart';
import 'profile_screen.dart';
import '../services/transit_data_service.dart';
import '../services/nagpur_places_service.dart';
import '../services/backend_config.dart';

class LandingMapScreen extends StatefulWidget {
  final VoidCallback? onOpenTickets;
  final VoidCallback? onOpenSafarBot;

  const LandingMapScreen({super.key, this.onOpenTickets, this.onOpenSafarBot});

  @override
  State<LandingMapScreen> createState() => _LandingMapScreenState();
}

class _LandingMapScreenState extends State<LandingMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late AnimationController _pulseController;

  // ── SEARCH STATE ────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearchOpen = false;
  bool _isLoadingSearch = false;
  List<NagpurPOI> _searchResults = [];
  NagpurPOI? _selectedPlace; // Currently selected and pinned location on map

  // ── MAP LAYERS STATE (Matching GoogleMapsLayersFAB.tsx) ─────────
  String _selectedBasemap = 'carto'; // 'carto' (default from FYP MapView.tsx) or 'google'
  bool _showMetroLayer = false;      // By default, do not show metro layer
  bool _showBusLayer = false;        // By default, do not show bus layer
  bool _isLayersDockOpen = false;    // Floating dock toggle

  static const LatLng _nagpurCenter = LatLng(21.1458, 79.0882); // Sitabuldi Central Nagpur

  // Metro Orange Line Stations GPS coords fallback
  final List<LatLng> _orangeLinePoints = [
    const LatLng(21.0562, 79.0583), // Khapri
    const LatLng(21.0745, 79.0578), // New Airport
    const LatLng(21.0841, 79.0580), // Airport South
    const LatLng(21.0965, 79.0632), // Airport
    const LatLng(21.1062, 79.0684), // Ujjwal Nagar
    const LatLng(21.1145, 79.0732), // Jaiprakash Nagar
    const LatLng(21.1215, 79.0768), // Chhatrapati Square
    const LatLng(21.1294, 79.0805), // Ajni Square
    const LatLng(21.1372, 79.0842), // Congress Nagar
    const LatLng(21.1415, 79.0861), // Rahate Colony
    const LatLng(21.1466, 79.0882), // Sitabuldi Interchange
    const LatLng(21.1498, 79.0806), // Zero Mile Freedom Park
    const LatLng(21.1552, 79.0835), // Kasturchand Park
    const LatLng(21.1632, 79.0854), // GaddiGodam Square
    const LatLng(21.1715, 79.0872), // Kadbi Chowk
    const LatLng(21.1798, 79.0895), // Indora Square
    const LatLng(21.1895, 79.0912), // Nari Road
    const LatLng(21.1995, 79.0935), // Automotive Square
  ];

  // Metro Aqua Line Stations GPS coords fallback
  final List<LatLng> _aquaLinePoints = [
    const LatLng(21.1472, 79.1550), // Prajapati Nagar
    const LatLng(21.1468, 79.1432), // Vaishno Devi Chowk
    const LatLng(21.1465, 79.1325), // Ambedkar Chowk
    const LatLng(21.1461, 79.1220), // Telephone Exchange
    const LatLng(21.1458, 79.1125), // Chitar Oli
    const LatLng(21.1455, 79.1040), // Agrasen Chowk
    const LatLng(21.1460, 79.0965), // Dosar Vaisya Square
    const LatLng(21.1524, 79.0888), // Nagpur Railway Station Metro
    const LatLng(21.1430, 79.0915), // Cotton Market
    const LatLng(21.1466, 79.0882), // Sitabuldi Interchange
    const LatLng(21.1420, 79.0775), // Jhansi Rani Square
    const LatLng(21.1395, 79.0682), // Institute of Engineers
    const LatLng(21.1375, 79.0610), // Shankar Nagar Square
    const LatLng(21.1352, 79.0535), // LAD Square
    const LatLng(21.1310, 79.0465), // Dharampeth College
    const LatLng(21.1265, 79.0395), // Subhash Nagar
    const LatLng(21.1230, 79.0320), // Rachna Ring Road
    const LatLng(21.1190, 79.0250), // Vasudev Nagar
    const LatLng(21.1145, 79.0175), // Bansi Nagar
    const LatLng(21.1095, 79.0090), // Lokmanya Nagar
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {
          _isSearchOpen = true;
          if (_searchResults.isEmpty) {
            _searchResults = NagpurPlacesService.curatedPlaces.take(6).toList();
          }
        });
      }
    });

    // Ensure real transit datasets (837 bus routes, 3,487 stops, Metro tracks) are loaded
    if (!TransitDataService().isLoaded || TransitDataService().busRoutePolylines.isEmpty) {
      TransitDataService().loadDatasets(forceReload: true).then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    final query = text.trim();
    if (query.isEmpty) {
      setState(() {
        _isLoadingSearch = false;
        _searchResults = NagpurPlacesService.curatedPlaces.take(6).toList();
      });
      return;
    }

    setState(() {
      _isLoadingSearch = true;
      _isSearchOpen = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await NagpurPlacesService().searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoadingSearch = false;
        });
      }
    });
  }

  void _onPlaceSelected(NagpurPOI place) {
    HapticFeedback.mediumImpact();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchOpen = false;
      _selectedPlace = place;
      _searchController.text = place.name;
    });

    // Animate map camera directly to the searched place location
    _mapController.move(LatLng(place.lat, place.lon), 16.0);
  }

  void _clearSelectedPlace() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedPlace = null;
      _searchController.clear();
      _isSearchOpen = false;
    });
  }

  void _recenterMap() {
    HapticFeedback.mediumImpact();
    _mapController.move(_nagpurCenter, 14.5);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Centered at Sitabuldi, Central Nagpur'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleLayersDock() {
    HapticFeedback.selectionClick();
    setState(() {
      _isLayersDockOpen = !_isLayersDockOpen;
    });
  }

  String _getTileUrl() {
    if (_selectedBasemap == 'google') {
      return 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    }
    final key = BackendConfig.cartoApiKey;
    return key.isNotEmpty
        ? 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png?key=$key'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  }

  List<String> _getTileSubdomains() {
    if (_selectedBasemap == 'google') {
      return const ['0', '1', '2', '3'];
    }
    return const ['a', 'b', 'c', 'd'];
  }

  IconData _getCategoryIcon(String category, String kind) {
    final cat = category.toLowerCase();
    if (kind == 'metro' || cat.contains('metro')) return Icons.subway_rounded;
    if (kind == 'bus' || cat.contains('bus')) return Icons.directions_bus_rounded;
    if (cat.contains('hospital') || cat.contains('health')) return Icons.local_hospital_rounded;
    if (cat.contains('restaurant') || cat.contains('food') || cat.contains('cafe')) return Icons.restaurant_rounded;
    if (cat.contains('mall') || cat.contains('shop')) return Icons.shopping_bag_rounded;
    if (cat.contains('park') || cat.contains('lake') || cat.contains('garden')) return Icons.park_rounded;
    if (cat.contains('temple')) return Icons.temple_hindu_rounded;
    if (cat.contains('monument')) return Icons.account_balance_rounded;
    if (cat.contains('college') || cat.contains('school')) return Icons.school_rounded;
    if (cat.contains('hotel')) return Icons.hotel_rounded;
    if (cat.contains('bank')) return Icons.account_balance_wallet_rounded;
    if (cat.contains('coord') || kind == 'coord') return Icons.gps_fixed_rounded;
    return Icons.place_rounded;
  }

  Color _getCategoryColor(String category, String kind) {
    final cat = category.toLowerCase();
    if (kind == 'metro' || cat.contains('metro')) return const Color(0xFFFF6A00);
    if (kind == 'bus' || cat.contains('bus')) return const Color(0xFF0284C7);
    if (cat.contains('hospital')) return const Color(0xFFEF4444);
    if (cat.contains('restaurant')) return const Color(0xFFF97316);
    if (cat.contains('mall')) return const Color(0xFF8B5CF6);
    if (cat.contains('park') || cat.contains('lake')) return const Color(0xFF10B981);
    if (cat.contains('temple') || cat.contains('monument')) return const Color(0xFFD97706);
    if (cat.contains('college')) return const Color(0xFF3B82F6);
    if (cat.contains('coord') || kind == 'coord') return const Color(0xFF2563EB);
    return const Color(0xFF059669);
  }

  @override
  Widget build(BuildContext context) {
    final int activeOverlayCount = (_showMetroLayer ? 1 : 0) + (_showBusLayer ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // 1. FULLSCREEN REAL INTERACTIVE NAGPUR MAP (From FYP)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _nagpurCenter,
                initialZoom: 14.5,
                minZoom: 10.0,
                maxZoom: 18.5,
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                    const LatLng(20.80, 78.75), // SW (MIHAN, Butibori)
                    const LatLng(21.42, 79.40), // NE (Koradi, Kamptee)
                  ),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (tapPosition, point) {
                  if (_isSearchOpen) {
                    _searchFocusNode.unfocus();
                    setState(() {
                      _isSearchOpen = false;
                    });
                  }
                },
              ),
              children: [
                // ── Real Map Tile Layer ────────────────────────────
                TileLayer(
                  key: ValueKey('map_tile_$_selectedBasemap'),
                  urlTemplate: _getTileUrl(),
                  subdomains: _getTileSubdomains(),
                  tileProvider: NetworkTileProvider(
                    headers: <String, String>{
                      'User-Agent':
                          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    },
                  ),
                  maxZoom: 20,
                ),

                // ── Aapli Bus Route Network Polylines (837 routes across Nagpur) ──
                if (_showBusLayer)
                  PolylineLayer(
                    polylines: TransitDataService().cachedBusPolylines,
                  ),

                // ── Aapli Bus Stop Dots (3,487 unique transit stops) ──
                if (_showBusLayer)
                  CircleLayer(
                    circles: TransitDataService().cachedBusStopCircles,
                  ),

                // ── Nagpur Metro Lines (Orange & Aqua from lineGeometries.json) ──
                if (_showMetroLayer)
                  PolylineLayer(
                    polylines: [
                      // Orange Line Casing & Track
                      Polyline(
                        points: TransitDataService().orangeLinePolyline.isNotEmpty
                            ? TransitDataService().orangeLinePolyline
                            : _orangeLinePoints,
                        color: const Color(0x66FF6A00),
                        strokeWidth: 8.0,
                      ),
                      Polyline(
                        points: TransitDataService().orangeLinePolyline.isNotEmpty
                            ? TransitDataService().orangeLinePolyline
                            : _orangeLinePoints,
                        color: const Color(0xFFFF6A00), // Nagpur Metro Orange
                        strokeWidth: 4.5,
                      ),

                      // Aqua Line Casing & Track
                      Polyline(
                        points: TransitDataService().aquaLinePolyline.isNotEmpty
                            ? TransitDataService().aquaLinePolyline
                            : _aquaLinePoints,
                        color: const Color(0x6600AAFF),
                        strokeWidth: 8.0,
                      ),
                      Polyline(
                        points: TransitDataService().aquaLinePolyline.isNotEmpty
                            ? TransitDataService().aquaLinePolyline
                            : _aquaLinePoints,
                        color: const Color(0xFF00AAFF), // Nagpur Metro Aqua/Cyan
                        strokeWidth: 4.5,
                      ),
                    ],
                  ),

                // ── Nagpur Metro Station Dots Overlay ──────────────
                if (_showMetroLayer)
                  CircleLayer(
                    circles: TransitDataService().cachedMetroStationCircles,
                  ),

                // ── Markers Layer: Live User Location & Searched Destination Pin ──
                MarkerLayer(
                  markers: [
                    // 1. Live User Pulsing Location at Sitabuldi
                    Marker(
                      point: _nagpurCenter,
                      width: 56,
                      height: 56,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulse = _pulseController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 32 + pulse * 24,
                                height: 32 + pulse * 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF2563EB).withValues(
                                    alpha: 0.25 * (1 - pulse * 0.7),
                                  ),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // 2. Searched Destination Location Pin Pointer
                    if (_selectedPlace != null)
                      Marker(
                        point: LatLng(_selectedPlace!.lat, _selectedPlace!.lon),
                        width: 160,
                        height: 90,
                        alignment: Alignment.topCenter,
                        child: _buildDestinationPinWidget(_selectedPlace!),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // 2. TOP FLOATING SEARCH BAR & CATEGORIES & SUGGESTIONS
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Floating Search Bar Card
                    _buildFloatingSearchBar(),

                    // Auto-complete Search Suggestions Dropdown
                    if (_isSearchOpen) ...[
                      const SizedBox(height: 8),
                      _buildSearchResultsDropdown(),
                    ],

                    if (!_isSearchOpen) ...[
                      const SizedBox(height: 10),
                      // Floating Category Filter Chips
                      _buildCategoryFilterRow(),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // 3. HORIZONTAL EXPANDABLE LAYERS DOCK (GoogleMapsLayersFAB Design)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (_isLayersDockOpen)
            Positioned(
              right: 70,
              top: MediaQuery.of(context).size.height * 0.22,
              child: _buildLayersDock(),
            ),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // 4. FLOATING ACTION CONTROLS (Right side)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.25,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Map Layers Button with Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildFloatingButton(
                      icon: Icons.layers_rounded,
                      tooltip: 'Map Layers',
                      isActive: _isLayersDockOpen,
                      onTap: _toggleLayersDock,
                    ),
                    if (activeOverlayCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669), // Emerald Badge
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$activeOverlayCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Zoom In
                _buildFloatingButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In',
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
                  },
                ),
                const SizedBox(height: 6),
                // Zoom Out
                _buildFloatingButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out',
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom - 1.0);
                  },
                ),
                const SizedBox(height: 10),
                // Recenter / Locate Me Button
                _buildFloatingButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Locate Me',
                  onTap: _recenterMap,
                ),
              ],
            ),
          ),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // 5. FLOATING WEATHER & AQI WIDGET (Bottom Left)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (_selectedPlace == null)
            Positioned(left: 16, bottom: 24, child: _buildWeatherAQICard()),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // 6. FLOATING DIRECTIONS BUTTON (Bottom Right)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (_selectedPlace == null)
            Positioned(
              right: 16,
              bottom: 24,
              child: _buildDirectionsFloatingButton(),
            ),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // 7. SELECTED PLACE PREVIEW BOTTOM CARD (When Place is Found)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (_selectedPlace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildPlacePreviewBottomCard(_selectedPlace!),
            ),
        ],
      ),
    );
  }

  // ── Custom Destination Marker Pin Widget ────────────────────────
  Widget _buildDestinationPinWidget(NagpurPOI place) {
    final color = _getCategoryColor(place.category, place.kind);
    final icon = _getCategoryIcon(place.category, place.kind);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name Label Bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  place.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Google Maps Teardrop Pin Marker
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ── Selected Place Preview Card at Bottom ───────────────────────
  Widget _buildPlacePreviewBottomCard(NagpurPOI place) {
    final color = _getCategoryColor(place.category, place.kind);
    final icon = _getCategoryIcon(place.category, place.kind);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              // Place Name & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      place.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Dismiss Button
              GestureDetector(
                onTap: _clearSelectedPlace,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.onOpenSafarBot?.call();
                  },
                  icon: const Icon(Icons.smart_toy_outlined, size: 18),
                  label: const Text('Ask SafarBot'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MapPlanScreen(
                          initialDestination: place.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Directions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Auto-Complete Search Results Dropdown ────────────────────────
  Widget _buildSearchResultsDropdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: _isLoadingSearch
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                ),
              ),
            )
          : _searchResults.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No matching places in Nagpur found',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: Color(0xFFF1F5F9),
                    indent: 54,
                  ),
                  itemBuilder: (context, index) {
                    final place = _searchResults[index];
                    final color = _getCategoryColor(place.category, place.kind);
                    final icon = _getCategoryIcon(place.category, place.kind);

                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      title: Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        place.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          place.category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      onTap: () => _onPlaceSelected(place),
                    );
                  },
                ),
    );
  }

  // ── Horizontal Expandable Layers Dock (Matching FYP GoogleMapsLayersFAB.tsx) ──
  Widget _buildLayersDock() {
    final isCarto = _selectedBasemap == 'carto';
    final isGoogle = _selectedBasemap == 'google';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Carto Map Basemap Tile
          _buildLayerCard(
            title: 'Carto Map',
            icon: Icons.map_rounded,
            isSelected: isCarto,
            activeColor: const Color(0xFF2563EB), // Blue
            activeBgColor: const Color(0xFFDBEAFE),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedBasemap = 'carto';
              });
            },
          ),

          const SizedBox(width: 8),

          // 2. Google Map Basemap Tile
          _buildLayerCard(
            title: 'Google Map',
            icon: Icons.language_rounded,
            isSelected: isGoogle,
            activeColor: const Color(0xFF059669), // Emerald
            activeBgColor: const Color(0xFFD1FAE5),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedBasemap = 'google';
              });
            },
          ),

          // Vertical Separator
          Container(
            height: 36,
            width: 1,
            color: const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // 3. Metro Stations & Corridors Toggle
          _buildLayerCard(
            title: 'Metro',
            icon: Icons.directions_subway_rounded,
            isSelected: _showMetroLayer,
            activeColor: const Color(0xFFFF6A00), // Orange
            activeBgColor: const Color(0xFFFFEDD5),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showMetroLayer = !_showMetroLayer;
              });
              if (_showMetroLayer && TransitDataService().orangeLinePolyline.isEmpty) {
                TransitDataService().loadDatasets(forceReload: true).then((_) {
                  if (mounted) setState(() {});
                });
              }
            },
          ),

          const SizedBox(width: 8),

          // 4. Aapli Bus Layer Toggle
          _buildLayerCard(
            title: 'Bus Layer',
            icon: Icons.directions_bus_rounded,
            isSelected: _showBusLayer,
            activeColor: const Color(0xFF0D9488), // Teal
            activeBgColor: const Color(0xFFCCFBF1),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showBusLayer = !_showBusLayer;
              });
              if (_showBusLayer && TransitDataService().busRoutePolylines.isEmpty) {
                TransitDataService().loadDatasets(forceReload: true).then((_) {
                  if (mounted) setState(() {});
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLayerCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 66,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor.withValues(alpha: 0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : activeBgColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : activeColor,
                      size: 22,
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF475569),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Floating Search Bar ─────────────────────────────────────
  Widget _buildFloatingSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF1E293B),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search places, metro, stops in Nagpur...',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            IconButton(
              icon: const Icon(
                Icons.mic_none_rounded,
                color: Color(0xFF475569),
                size: 22,
              ),
              onPressed: () {
                widget.onOpenSafarBot?.call();
              },
              padding: const EdgeInsets.symmetric(horizontal: 6),
              constraints: const BoxConstraints(),
            ),
            Container(width: 1, height: 20, color: AppTheme.cardBorder),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Stack(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0F172A),
                    ),
                    child: const Center(
                      child: Text(
                        'RO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF059669),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Filter Pills Row ──────────────────────────────────
  Widget _buildCategoryFilterRow() {
    final categories = [
      {
        'title': 'Restaurants',
        'query': 'Restaurant',
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFFF97316),
      },
      {
        'title': 'Hospitals',
        'query': 'Hospital',
        'icon': Icons.local_hospital_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'title': 'Saved Places',
        'query': 'Mall',
        'icon': Icons.bookmark_rounded,
        'color': const Color(0xFFDC2626),
      },
      {
        'title': 'Layers',
        'query': '',
        'icon': Icons.layers_rounded,
        'color': const Color(0xFF1E293B),
      },
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final title = cat['title'] as String;
          final query = cat['query'] as String;
          final icon = cat['icon'] as IconData;
          final color = cat['color'] as Color;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              if (title == 'Layers') {
                _toggleLayersDock();
              } else {
                _searchController.text = query;
                _onSearchChanged(query);
                _searchFocusNode.requestFocus();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x100F172A),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Floating Circular Action Button ─────────────────────────────
  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0F172A) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Left Weather & AQI Card ──────────────────────────────
  Widget _buildWeatherAQICard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wb_sunny_rounded,
            color: Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: 6),
          const Text(
            '34°',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 14,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco_rounded, size: 12, color: Color(0xFFD97706)),
                SizedBox(width: 3),
                Text(
                  'AQI 68',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Right Floating Directions FAB ────────────────────────
  Widget _buildDirectionsFloatingButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0284C7), // Sky / Transit Blue
            Color(0xFF0369A1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MapPlanScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(
              Icons.directions_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
