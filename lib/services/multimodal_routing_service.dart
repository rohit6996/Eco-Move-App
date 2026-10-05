import 'dart:math' as math;
import 'nagpur_places_service.dart';
import 'transit_data_service.dart';

class RouteLeg {
  final String mode; // 'walk' | 'metro' | 'bus' | 'cab' | 'erickshaw'
  final String title;
  final String instruction;
  final int durationMinutes;
  final double distanceKm;
  final double fare;
  final String? lineName;
  final String? colorHex;

  const RouteLeg({
    required this.mode,
    required this.title,
    required this.instruction,
    required this.durationMinutes,
    required this.distanceKm,
    required this.fare,
    this.lineName,
    this.colorHex,
  });
}

class MultimodalRoutePlan {
  final String id;
  final String title;
  final String subtitle;
  final int totalDurationMinutes;
  final double totalDistanceKm;
  final double totalFareRs;
  final double co2SavedKg;
  final int greenPoints;
  final String badge; // 'Fastest' | 'Greenest' | 'Cheapest' | 'Smart Feeder'
  final List<RouteLeg> legs;

  const MultimodalRoutePlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.totalDurationMinutes,
    required this.totalDistanceKm,
    required this.totalFareRs,
    required this.co2SavedKg,
    required this.greenPoints,
    required this.badge,
    required this.legs,
  });
}

class MultimodalRoutingService {
  static final MultimodalRoutingService _instance = MultimodalRoutingService._internal();
  factory MultimodalRoutingService() => _instance;
  MultimodalRoutingService._internal();

  final TransitDataService _transitService = TransitDataService();

  /// Calculate distance in km between two geo coordinates (Haversine formula)
  double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final c = math.cos;
    final a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Generate smart multimodal transit options for any pair of Nagpur origin and destination
  List<MultimodalRoutePlan> planJourney({
    required NagpurPOI origin,
    required NagpurPOI destination,
    bool hasMahaCard = false,
  }) {
    final directDistKm = calculateDistanceKm(origin.lat, origin.lon, destination.lat, destination.lon);

    // Find nearest Metro station to Origin and Destination
    final allStations = _transitService.allMetroStations;
    MetroStation? nearestOriginMetro;
    double minOriginDist = double.infinity;
    for (final s in allStations) {
      final d = calculateDistanceKm(origin.lat, origin.lon, s.lat, s.lon);
      if (d < minOriginDist) {
        minOriginDist = d;
        nearestOriginMetro = s;
      }
    }

    MetroStation? nearestDestMetro;
    double minDestDist = double.infinity;
    for (final s in allStations) {
      final d = calculateDistanceKm(destination.lat, destination.lon, s.lat, s.lon);
      if (d < minDestDist) {
        minDestDist = d;
        nearestDestMetro = s;
      }
    }

    final plans = <MultimodalRoutePlan>[];

    // 1. OPTION 1: METRO EXPRESS + FIRST/LAST MILE (Greenest & Fastest)
    if (nearestOriginMetro != null && nearestDestMetro != null) {
      final metroFare = _transitService.calculateMetroFare(
        fromStation: nearestOriginMetro.name,
        toStation: nearestDestMetro.name,
        hasMahaCard: hasMahaCard,
      );

      final walk1Time = (minOriginDist * 12).round().clamp(2, 15);
      final metroRideTime = ((directDistKm * 2.2) + 6).round().clamp(8, 35);
      final walk2Time = (minDestDist * 12).round().clamp(2, 15);
      final totalTime1 = walk1Time + metroRideTime + walk2Time;
      final totalFare1 = metroFare;
      final co2Kg1 = (directDistKm * 0.14).clamp(0.4, 4.8);

      plans.add(MultimodalRoutePlan(
        id: 'plan_metro_express',
        title: 'MahaMetro Express (Nagpur Metro)',
        subtitle: 'Via ${nearestOriginMetro.name} ➔ ${nearestDestMetro.name}',
        totalDurationMinutes: totalTime1,
        totalDistanceKm: double.parse(directDistKm.toStringAsFixed(1)),
        totalFareRs: totalFare1,
        co2SavedKg: double.parse(co2Kg1.toStringAsFixed(2)),
        greenPoints: (co2Kg1 * 100).round(),
        badge: 'Greenest & Fast',
        legs: [
          RouteLeg(
            mode: 'walk',
            title: 'Walk to ${nearestOriginMetro.name}',
            instruction: 'Walk ${minOriginDist.toStringAsFixed(1)} km to Metro Entry Gate 1',
            durationMinutes: walk1Time,
            distanceKm: minOriginDist,
            fare: 0.0,
            colorHex: '0xFF64748B',
          ),
          RouteLeg(
            mode: 'metro',
            title: '${nearestOriginMetro.line}: ${nearestOriginMetro.name}',
            instruction: 'Board Metro towards ${nearestDestMetro.name} (Frequency every 6 mins)',
            durationMinutes: metroRideTime,
            distanceKm: directDistKm * 0.9,
            fare: metroFare,
            lineName: nearestOriginMetro.line,
            colorHex: nearestOriginMetro.line.contains('Aqua') ? '0xFF06B6D4' : '0xFFF97316',
          ),
          RouteLeg(
            mode: 'walk',
            title: 'Walk to ${destination.name}',
            instruction: 'Exit via concourse to ${destination.subtitle}',
            durationMinutes: walk2Time,
            distanceKm: minDestDist,
            fare: 0.0,
            colorHex: '0xFF64748B',
          ),
        ],
      ));
    }

    // 2. OPTION 2: AAPLI BUS DIRECT / FEEDER (Cheapest Eco-Commute)
    final busFare = 15.0;
    final busTime = ((directDistKm * 3.5) + 10).round().clamp(15, 55);
    final co2Kg2 = (directDistKm * 0.11).clamp(0.3, 3.8);

    plans.add(MultimodalRoutePlan(
      id: 'plan_aapli_bus',
      title: 'Aapli Bus Direct Feeder',
      subtitle: 'Electric City Bus Line (Chalo Telemetry Active)',
      totalDurationMinutes: busTime,
      totalDistanceKm: double.parse((directDistKm * 1.15).toStringAsFixed(1)),
      totalFareRs: busFare,
      co2SavedKg: double.parse(co2Kg2.toStringAsFixed(2)),
      greenPoints: (co2Kg2 * 85).round(),
      badge: 'Cheapest',
      legs: [
        RouteLeg(
          mode: 'walk',
          title: 'Walk to nearest Bus Shelter',
          instruction: 'Walk 250m to Aapli Bus stop',
          durationMinutes: 4,
          distanceKm: 0.25,
          fare: 0.0,
          colorHex: '0xFF64748B',
        ),
        RouteLeg(
          mode: 'bus',
          title: 'Aapli EV Bus Route',
          instruction: 'Board E-Bus towards ${destination.name} (Live GPS tracking)',
          durationMinutes: busTime - 8,
          distanceKm: directDistKm * 1.1,
          fare: busFare,
          lineName: 'Aapli Bus Nagpur',
          colorHex: '0xFF10B981',
        ),
        RouteLeg(
          mode: 'walk',
          title: 'Arrive at destination',
          instruction: 'Walk 3 mins to final spot',
          durationMinutes: 4,
          distanceKm: 0.2,
          fare: 0.0,
          colorHex: '0xFF64748B',
        ),
      ],
    ));

    // 3. OPTION 3: SMART MULTIMODAL FEEDER (E-Rickshaw + Metro)
    if (nearestOriginMetro != null) {
      final erickshawFare = 30.0;
      final metroFare = 20.0;
      final totalFare3 = erickshawFare + (hasMahaCard ? 18.0 : metroFare);
      final totalTime3 = (10 + 15 + 5);
      final co2Kg3 = (directDistKm * 0.12).clamp(0.35, 4.0);

      plans.add(MultimodalRoutePlan(
        id: 'plan_smart_multimodal',
        title: 'Smart E-Rickshaw + Metro Link',
        subtitle: 'Feeder Auto to ${nearestOriginMetro.name} + Express Train',
        totalDurationMinutes: totalTime3,
        totalDistanceKm: double.parse((directDistKm * 1.05).toStringAsFixed(1)),
        totalFareRs: totalFare3,
        co2SavedKg: double.parse(co2Kg3.toStringAsFixed(2)),
        greenPoints: (co2Kg3 * 90).round(),
        badge: 'Smart Feeder',
        legs: [
          RouteLeg(
            mode: 'erickshaw',
            title: 'Feeder E-Rickshaw',
            instruction: 'Fast green feeder from ${origin.name} to ${nearestOriginMetro.name}',
            durationMinutes: 8,
            distanceKm: minOriginDist,
            fare: erickshawFare,
            colorHex: '0xFFEAB308',
          ),
          RouteLeg(
            mode: 'metro',
            title: 'MahaMetro Rapid Transit',
            instruction: 'Express train to destination corridor',
            durationMinutes: 16,
            distanceKm: directDistKm * 0.85,
            fare: hasMahaCard ? 18.0 : metroFare,
            lineName: nearestOriginMetro.line,
            colorHex: '0xFF10B981',
          ),
        ],
      ));
    }

    return plans;
  }
}
