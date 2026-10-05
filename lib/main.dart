import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/landing_map_screen.dart';
import 'screens/live_fleet_screen.dart';
import 'screens/tickets_screen.dart';
import 'screens/cabs_screen.dart';
import 'screens/eco_rewards_screen.dart';
import 'screens/safarbot_screen.dart';

import '../services/supabase_service.dart';
import '../services/transit_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Load private environment variables from .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Note: .env file not loaded ($e), using fallbacks.');
  }

  // Initialize Supabase Backend & Load Local Transit Data
  await SupabaseService().initialize();
  await TransitDataService().loadDatasets();

  runApp(const EcoMoveApp());
}

class EcoMoveApp extends StatelessWidget {
  const EcoMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco-Move Nagpur',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
    }
  }

  void _openSafarBot() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SafarBotScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      LandingMapScreen(
        onOpenTickets: () => _onTabSelected(2),
        onOpenSafarBot: _openSafarBot,
      ),
      const LiveFleetScreen(),
      const TicketsScreen(),
      const CabsScreen(),
      const EcoRewardsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── White Navigation Bar Container with Curved Top ────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 62,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Know your Bus
                    _buildStandardNavItem(
                      index: 0,
                      icon: Icons.directions_bus_rounded,
                      label: 'Know your Bus',
                    ),

                    // 2. Nearby
                    _buildStandardNavItem(
                      index: 1,
                      icon: Icons.explore_outlined,
                      label: 'Nearby',
                    ),

                    // 3. Center Space for Tickets label
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabSelected(2),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(height: 38), // space for floating button
                            Text(
                              'Tickets',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _currentIndex == 2
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: _currentIndex == 2
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),

                    // 4. Cabs
                    _buildStandardNavItem(
                      index: 3,
                      icon: Icons.directions_car_rounded,
                      label: 'Cabs',
                    ),

                    // 5. Eco Points
                    _buildStandardNavItem(
                      index: 4,
                      icon: Icons.eco_outlined,
                      label: 'Eco Points',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Prominent Floating Elevated Emerald "Tickets" Button ──
          Positioned(
            top: -18,
            child: GestureDetector(
              onTap: () => _onTabSelected(2),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF059669), // Crisp Emerald Green
                      Color(0xFF047857),
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669)
                          .withValues(alpha: _currentIndex == 2 ? 0.5 : 0.35),
                      blurRadius: _currentIndex == 2 ? 16 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: -0.5,
                    child: const Icon(
                      Icons.confirmation_num_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Regular Tab Item ──────────────────────────────────────────
  Widget _buildStandardNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = index == _currentIndex;
    final activeColor = const Color(0xFF0284C7); // Nagpur Transit Sky Blue
    final inactiveColor = const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : inactiveColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
