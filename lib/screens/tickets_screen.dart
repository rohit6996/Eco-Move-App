import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../mock_data/mock_data.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  late AnimationController _scanlineController;
  late AnimationController _glowController;
  Timer? _countdownTimer;

  final _tabs = [
    (emoji: '🟢', label: 'Eco-Pass'),
    (emoji: '🚇', label: 'Metro QR'),
    (emoji: '🚌', label: 'Aapli Bus'),
  ];

  @override
  void initState() {
    super.initState();
    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _scanlineController.dispose();
    _glowController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.confirmation_num_rounded,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Tickets & Passes'),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildCategoryTabs(),
                const SizedBox(height: 20),
                // Active pass
                if (MockData.activeTickets.isNotEmpty) ...[
                  _buildActivePass(MockData.activeTickets[0]),
                  const SizedBox(height: 16),
                ],
                // WhatsApp banner
                _buildWhatsAppBanner(),
                const SizedBox(height: 24),
                // Journey history
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Recent Journeys',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildHistoryCard(MockData.journeyHistory[index]),
                ),
                childCount: MockData.journeyHistory.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.inputFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            final selected = i == _selectedTab;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTab = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.background : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected ? AppTheme.subtleShadows : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tab.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppTheme.textPrimary
                              : AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActivePass(TicketPass ticket) {
    final remaining = ticket.remainingValidity;
    final mins = remaining.inMinutes;
    final secs = remaining.inSeconds % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ticket.type.color.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: ticket.type.color.withValues(
                  alpha: 0.08 + _glowController.value * 0.06,
                ),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ticket.type.color.withValues(alpha: 0.06),
                      ticket.type.color.withValues(alpha: 0.02),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Text(ticket.type.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ticket.type.label} – Active',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            ticket.routeAllowed,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Countdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (mins > 10 ? AppTheme.success : AppTheme.warning)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${mins}m ${secs.toString().padLeft(2, '0')}s',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: mins > 10 ? AppTheme.success : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // QR code area
              Padding(
                padding: const EdgeInsets.all(24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // QR placeholder (mock)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: CustomPaint(
                        painter: _QRMockPainter(color: AppTheme.textPrimary),
                      ),
                    ),
                    // Scanline animation
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: AnimatedBuilder(
                        animation: _scanlineController,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment(
                              0,
                              -1 + _scanlineController.value * 2,
                            ),
                            child: Container(
                              width: 200,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    ticket.type.color.withValues(alpha: 0.0),
                                    ticket.type.color.withValues(alpha: 0.6),
                                    ticket.type.color.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Ticket details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ticketDetail('Passenger', ticket.passengerId),
                    _ticketDetail('Fare Paid', '₹${ticket.farePaid.toStringAsFixed(0)}'),
                    _ticketDetail('Ticket ID', ticket.id.substring(4)),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => HapticFeedback.mediumImpact(),
                        icon: const Icon(Icons.brightness_high_rounded, size: 18),
                        label: const Text('Brightness'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.save_alt_rounded, size: 18),
                        label: const Text('Save PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ticketDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textTertiary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsAppBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF25D366).withValues(alpha: 0.08),
                const Color(0xFF25D366).withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF25D366).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: Color(0xFF25D366),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maha Metro WhatsApp Ticketing',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '+91 86248 88568 · Book via chat',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF25D366),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(JourneyHistory journey) {
    final dayDiff = DateTime.now().difference(journey.date).inDays;
    final dateLabel = dayDiff == 0
        ? 'Today'
        : dayDiff == 1
            ? 'Yesterday'
            : '$dayDiff days ago';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          // Mode icons
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: journey.modes.map((m) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(m.icon, size: 16, color: m.color),
              )).toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${journey.from} → ${journey.to}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateLabel · ₹${journey.fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco_rounded, size: 12, color: AppTheme.success),
                const SizedBox(width: 3),
                Text(
                  '${journey.carbonSavedGrams}g',
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
    );
  }
}

// Mock QR code painter
class _QRMockPainter extends CustomPainter {
  final Color color;
  _QRMockPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final cellSize = size.width / 25;
    final paint = Paint()..color = color;

    // Corner patterns (position detection)
    _drawFinderPattern(canvas, paint, 2 * cellSize, 2 * cellSize, cellSize);
    _drawFinderPattern(canvas, paint, (25 - 9) * cellSize, 2 * cellSize, cellSize);
    _drawFinderPattern(canvas, paint, 2 * cellSize, (25 - 9) * cellSize, cellSize);

    // Random data modules
    for (int y = 0; y < 25; y++) {
      for (int x = 0; x < 25; x++) {
        if (_isInFinderArea(x, y)) continue;
        if (rng.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize - 0.5, cellSize - 0.5),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(Canvas canvas, Paint paint, double x, double y, double cell) {
    // Outer border
    canvas.drawRect(Rect.fromLTWH(x, y, cell * 7, cell * 7), paint);
    // White inner
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(x + cell, y + cell, cell * 5, cell * 5), whitePaint);
    // Inner square
    canvas.drawRect(Rect.fromLTWH(x + cell * 2, y + cell * 2, cell * 3, cell * 3), paint);
  }

  bool _isInFinderArea(int x, int y) {
    if (x < 9 && y < 9) return true;
    if (x > 15 && y < 9) return true;
    if (x < 9 && y > 15) return true;
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
