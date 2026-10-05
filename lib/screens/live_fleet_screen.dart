import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../mock_data/mock_data.dart';
import '../widgets/shared_widgets.dart';

import '../services/transit_data_service.dart';

class LiveFleetScreen extends StatefulWidget {
  const LiveFleetScreen({super.key});

  @override
  State<LiveFleetScreen> createState() => _LiveFleetScreenState();
}

class _LiveFleetScreenState extends State<LiveFleetScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _selectedCorridor = 'All';
  int? _selectedBusIndex;
  int _viewMode = 0; // 0: Live Radar, 1: Real Chalo Routes Catalog
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  List<BusInfo> get _filteredBuses {
    var buses = MockData.busFleet.toList();
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      buses = buses.where((b) =>
        b.routeNumber.toLowerCase().contains(query) ||
        b.routeName.toLowerCase().contains(query) ||
        b.currentStop.toLowerCase().contains(query)
      ).toList();
    }
    if (_selectedCorridor != 'All') {
      buses = buses.where((b) => b.corridor == _selectedCorridor).toList();
    }
    return buses;
  }

  List<ChaloBusRoute> get _filteredChaloRoutes {
    final allRoutes = TransitDataService().chaloBusRoutes;
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return allRoutes.take(25).toList();

    return allRoutes.where((r) {
      if (r.busNumber.toLowerCase().contains(query)) return true;
      if (r.from.toLowerCase().contains(query)) return true;
      if (r.to.toLowerCase().contains(query)) return true;
      return r.stops.any((s) => s.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final buses = _filteredBuses;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.metroAqua.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    color: AppTheme.metroAqua,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Live Fleet'),
              ],
            ),
            actions: [
              AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) => Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.success.withValues(
                            alpha: 0.5 + _radarController.value * 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Mode Toggle Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.inputFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _viewMode = 0);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _viewMode == 0 ? AppTheme.background : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _viewMode == 0 ? AppTheme.subtleShadows : null,
                              ),
                              child: Center(
                                child: Text(
                                  '🛰️ Live Fleet Radar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _viewMode == 0 ? FontWeight.w700 : FontWeight.w500,
                                    color: _viewMode == 0 ? AppTheme.textPrimary : AppTheme.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _viewMode = 1);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _viewMode == 1 ? AppTheme.background : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _viewMode == 1 ? AppTheme.subtleShadows : null,
                              ),
                              child: Center(
                                child: Text(
                                  '📋 Aapli Bus Routes (${TransitDataService().chaloBusRoutes.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _viewMode == 1 ? FontWeight.w700 : FontWeight.w500,
                                    color: _viewMode == 1 ? AppTheme.textPrimary : AppTheme.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 48,
                    decoration: AppTheme.inputDecoration,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: _viewMode == 0
                            ? 'Search by active bus, stop name...'
                            : 'Search 100+ Nagpur routes (e.g. 400, 4B, Sitabuldi)...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppTheme.textTertiary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_viewMode == 0) ...[
                  // Corridor pills
                  _buildCorridorPills(),
                  const SizedBox(height: 16),
                  // Radar view
                  _buildRadarView(buses),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '${buses.length} bus${buses.length != 1 ? 'es' : ''} active',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Official Nagpur Aapli Bus Network (${_filteredChaloRoutes.length} shown)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),

          // Bus cards or Chalo Routes cards
          if (_viewMode == 0)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildBusCard(buses[index], index),
                  ),
                  childCount: buses.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildChaloRouteCard(_filteredChaloRoutes[index]),
                  ),
                  childCount: _filteredChaloRoutes.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildChaloRouteCard(ChaloBusRoute route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.subtleShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bus ${route.busNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${route.from} ➔ ${route.to}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${route.stopsCount} Stops',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          if (route.stops.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Key Stops: ${route.stops.take(5).join(" • ")}${route.stops.length > 5 ? "..." : ""}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCorridorPills() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: MockData.corridors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final corridor = MockData.corridors[index];
          final selected = corridor == _selectedCorridor;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCorridor = corridor);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.metroAqua : AppTheme.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppTheme.metroAqua : AppTheme.cardBorder,
                ),
              ),
              child: Text(
                corridor,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadarView(List<BusInfo> buses) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Radar rings
            Center(
              child: AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: List.generate(3, (i) {
                      final size = 80.0 + i * 60;
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.metroAqua.withValues(
                              alpha: 0.15 - i * 0.04,
                            ),
                            width: 1,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            // Sweep line
            Center(
              child: AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _radarController.value * 2 * 3.14159,
                    child: Container(
                      width: 2,
                      height: 90,
                      alignment: Alignment.topCenter,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.metroAqua.withValues(alpha: 0.6),
                            AppTheme.metroAqua.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bus blips
            ...List.generate(buses.length, (i) {
              final offsets = [
                const Offset(0.35, 0.3),
                const Offset(0.65, 0.55),
                const Offset(0.25, 0.65),
                const Offset(0.72, 0.35),
              ];
              final offset = i < offsets.length ? offsets[i] : Offset(0.5 + i * 0.1, 0.5);
              return Positioned(
                left: offset.dx * 300,
                top: offset.dy * 170,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedBusIndex = i);
                  },
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      final pulse = ((_radarController.value * 3 + i) % 1.0);
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: buses[i].occupancy.color.withValues(alpha: 0.15 + pulse * 0.1),
                        ),
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: buses[i].occupancy.color,
                              boxShadow: [
                                BoxShadow(
                                  color: buses[i].occupancy.color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                buses[i].routeNumber,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
            // Center icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.metroAqua.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppTheme.metroAqua,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusCard(BusInfo bus, int index) {
    final isSelected = _selectedBusIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedBusIndex = isSelected ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen.withValues(alpha: 0.4)
                : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? AppTheme.elevatedShadows
              : AppTheme.subtleShadows,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bus.routeNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bus.routeName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              bus.corridor,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (bus.isOnSchedule ? AppTheme.success : AppTheme.warning)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bus.isOnSchedule ? 'On Schedule' : 'Delayed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: bus.isOnSchedule ? AppTheme.success : AppTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick stats
                  Row(
                    children: [
                      OccupancyBadge(level: bus.occupancy),
                      const SizedBox(width: 10),
                      InfoChip(
                        icon: Icons.speed_rounded,
                        value: '${bus.speedKmh.toStringAsFixed(0)} km/h',
                        iconColor: AppTheme.metroAqua,
                      ),
                      const Spacer(),
                      InfoChip(
                        icon: Icons.navigate_next_rounded,
                        value: '${bus.nextStop} (${bus.nextStopEtaMins} min)',
                        iconColor: AppTheme.primaryGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Expanded: stop timeline
            if (isSelected) ...[
              const Divider(height: 1),
              _buildStopTimeline(bus),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: const Text('View Full Daily Timetable'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStopTimeline(BusInfo bus) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stop Progress',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(bus.stops.length, (i) {
            final isPast = i < bus.currentStopIndex;
            final isCurrent = i == bus.currentStopIndex;
            final isFuture = i > bus.currentStopIndex;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dot + line
                SizedBox(
                  width: 20,
                  child: Column(
                    children: [
                      Container(
                        width: isCurrent ? 14 : 10,
                        height: isCurrent ? 14 : 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? AppTheme.primaryGreen
                              : isPast
                                  ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                                  : AppTheme.cardBorder,
                          border: isCurrent
                              ? Border.all(color: AppTheme.primaryGreenLight, width: 3)
                              : null,
                          boxShadow: isCurrent
                              ? [BoxShadow(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                )]
                              : null,
                        ),
                      ),
                      if (i < bus.stops.length - 1)
                        Container(
                          width: 2,
                          height: 20,
                          color: isPast
                              ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                              : AppTheme.cardBorder,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          bus.stops[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                            color: isFuture
                                ? AppTheme.textTertiary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NOW',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
