import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../mock_data/mock_data.dart';
import '../widgets/shared_widgets.dart';

class MapPlanScreen extends StatefulWidget {
  final String? initialDestination;
  final String? initialOrigin;

  const MapPlanScreen({
    super.key,
    this.initialDestination,
    this.initialOrigin,
  });

  @override
  State<MapPlanScreen> createState() => _MapPlanScreenState();
}

class _MapPlanScreenState extends State<MapPlanScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  int _selectedFilter = 0;
  int? _expandedRouteIndex;
  late AnimationController _pulseController;

  final _filters = ['⭐ Fastest', '💰 Cheapest', '🌿 Max CO₂ Saved'];

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.initialOrigin ?? 'Sitabuldi');
    _toController = TextEditingController(text: widget.initialDestination ?? 'Nagpur Airport');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    HapticFeedback.lightImpact();
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Plan Journey'),
              ],
            ),
          ),

          // ── Content ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // ── Search Inputs ─────────────────────────────────
                _buildSearchSection(),
                const SizedBox(height: 16),
                // ── Filter Chips ──────────────────────────────────
                _buildFilterChips(),
                const SizedBox(height: 16),
                // ── Map Canvas ────────────────────────────────────
                _buildMapCanvas(),
                const SizedBox(height: 20),
                // ── Route Cards ───────────────────────────────────
                const SectionHeader(title: 'Recommended Routes'),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Route Option Cards ─────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildRouteCard(MockData.routeOptions[index], index),
                );
              }, childCount: MockData.routeOptions.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Search Section
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            // Route dots / line
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 2,
                  height: 32,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.primaryGreen, AppTheme.metroOrange],
                    ),
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.metroOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.metroOrange.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Input Fields
            Expanded(
              child: Column(
                children: [
                  _buildInputField(
                    controller: _fromController,
                    hint: 'From',
                    icon: Icons.my_location_rounded,
                    iconColor: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: _toController,
                    hint: 'To',
                    icon: Icons.place_rounded,
                    iconColor: AppTheme.metroOrange,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Swap Button
            GestureDetector(
              onTap: _swapLocations,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      height: 44,
      decoration: AppTheme.inputDecoration,
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Filter Chips
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _selectedFilter;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryGreen : AppTheme.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.primaryGreen : AppTheme.cardBorder,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  fontSize: 13,
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Map Canvas Placeholder
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildMapCanvas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDF4), Color(0xFFF0F9FF)],
          ),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Stack(
          children: [
            // Grid lines to simulate map
            ...List.generate(
              8,
              (i) => Positioned(
                top: 0,
                bottom: 0,
                left: (i + 1) * 200.0 / 4,
                child: Container(
                  width: 0.5,
                  color: AppTheme.cardBorder.withValues(alpha: 0.5),
                ),
              ),
            ),
            ...List.generate(
              5,
              (i) => Positioned(
                left: 0,
                right: 0,
                top: (i + 1) * 200.0 / 5,
                child: Container(
                  height: 0.5,
                  color: AppTheme.cardBorder.withValues(alpha: 0.5),
                ),
              ),
            ),
            // Orange metro line
            Positioned(
              top: 20,
              bottom: 20,
              left: 80,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: AppTheme.metroOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Aqua metro line
            Positioned(
              top: 90,
              left: 30,
              right: 30,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.metroAqua,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Interchange dot
            Positioned(
              top: 84,
              left: 74,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, child) => Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppTheme.textPrimary, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(
                          alpha: 0.15 + _pulseController.value * 0.15,
                        ),
                        blurRadius: 8 + _pulseController.value * 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Station dots on orange line
            ..._buildStationDots(
              axis: Axis.vertical,
              lineStart: 20,
              lineEnd: 180,
              fixedCross: 78,
              count: 6,
              color: AppTheme.metroOrange,
            ),
            // Station dots on aqua line
            ..._buildStationDots(
              axis: Axis.horizontal,
              lineStart: 30,
              lineEnd: 320,
              fixedCross: 88,
              count: 5,
              color: AppTheme.metroAqua,
            ),
            // Origin marker
            Positioned(
              top: 40,
              right: 60,
              child: _buildMapMarker('A', AppTheme.primaryGreen),
            ),
            // Destination marker
            Positioned(
              bottom: 25,
              left: 65,
              child: _buildMapMarker('B', AppTheme.metroOrange),
            ),
            // Legend
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendItem(AppTheme.metroOrange, 'Orange Line'),
                    const SizedBox(height: 4),
                    _legendItem(AppTheme.metroAqua, 'Aqua Line'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStationDots({
    required Axis axis,
    required double lineStart,
    required double lineEnd,
    required double fixedCross,
    required int count,
    required Color color,
  }) {
    return List.generate(count, (i) {
      final pos = lineStart + (lineEnd - lineStart) * i / (count - 1);
      return Positioned(
        top: axis == Axis.vertical ? pos : fixedCross,
        left: axis == Axis.horizontal ? pos : fixedCross,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: color, width: 2),
          ),
        ),
      );
    });
  }

  Widget _buildMapMarker(String letter, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Route Card
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildRouteCard(RouteOption route, int index) {
    final isExpanded = _expandedRouteIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _expandedRouteIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? AppTheme.primaryGreen.withValues(alpha: 0.4)
                : AppTheme.cardBorder,
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded
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
                  // Tag + Summary
                  Row(
                    children: [
                      if (route.tag.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            route.tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          route.summary,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textTertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Transit mode badges flow
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _buildLegBadges(route.legs),
                  ),
                  const SizedBox(height: 14),
                  // Stats row
                  Row(
                    children: [
                      InfoChip(
                        icon: Icons.schedule_rounded,
                        value: '${route.totalDurationMins} min',
                      ),
                      const SizedBox(width: 16),
                      InfoChip(
                        icon: Icons.currency_rupee_rounded,
                        value: '₹${route.ecoPassFare.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 16),
                      InfoChip(
                        icon: Icons.sync_alt_rounded,
                        value: '${route.transfers}',
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.eco_rounded,
                              size: 13,
                              color: AppTheme.success,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${route.carbonSavedGrams}g CO₂',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Expanded: Step-by-step + Action buttons
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _buildExpandedContent(route),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLegBadges(List<RouteLeg> legs) {
    final widgets = <Widget>[];
    for (int i = 0; i < legs.length; i++) {
      final leg = legs[i];
      widgets.add(
        TransitModeBadge(
          mode: leg.mode,
          label: leg.lineOrRoute != null
              ? '${leg.mode.label} ${leg.lineOrRoute}'
              : leg.mode.label,
          compact: true,
        ),
      );
      if (i < legs.length - 1) {
        widgets.add(
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: AppTheme.textTertiary.withValues(alpha: 0.5),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildExpandedContent(RouteOption route) {
    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step-by-Step',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...route.legs.map((leg) => _buildStepItem(leg)),
              const SizedBox(height: 14),
              // Fare breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Fare',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹${route.fareRupees.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '₹${route.ecoPassFare.toStringAsFixed(0)} Eco-Pass',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('View on Map'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.confirmation_num_rounded,
                        size: 18,
                      ),
                      label: Text(
                        'Book ₹${route.ecoPassFare.toStringAsFixed(0)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(RouteLeg leg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: leg.mode.color.withValues(alpha: 0.2),
                  border: Border.all(color: leg.mode.color, width: 2),
                ),
              ),
              Container(
                width: 2,
                height: 30,
                color: leg.mode.color.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(leg.mode.icon, size: 14, color: leg.mode.color),
                    const SizedBox(width: 6),
                    Text(
                      '${leg.durationMins} min',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: leg.mode.color,
                      ),
                    ),
                    if (leg.lineOrRoute != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: leg.mode.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          leg.lineOrRoute!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: leg.mode.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  leg.instruction,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
