/// Mock data for the UI-first development phase.
/// All data here will be replaced with live Supabase/API calls in Phase 2.
library;

import 'package:flutter/material.dart';
import '../models/models.dart';

class MockData {
  MockData._();

  // ─── Route Options ───────────────────────────────────────────────
  static final List<RouteOption> routeOptions = [
    RouteOption(
      id: 'r1',
      summary: 'Bus 135 → Metro Orange',
      tag: '⭐ Fastest',
      legs: [
        const RouteLeg(
          mode: TransitMode.walk,
          from: 'Your Location',
          to: 'Dharampeth Bus Stop',
          durationMins: 4,
          instruction: 'Walk 350m south to Dharampeth Bus Stop',
        ),
        const RouteLeg(
          mode: TransitMode.bus,
          from: 'Dharampeth Bus Stop',
          to: 'Sitabuldi Bus Stand',
          lineOrRoute: '135',
          durationMins: 12,
          instruction: 'Board Bus 135 towards Sitabuldi (6 stops)',
        ),
        const RouteLeg(
          mode: TransitMode.walk,
          from: 'Sitabuldi Bus Stand',
          to: 'Sitabuldi Interchange Metro',
          durationMins: 3,
          instruction: 'Walk 200m to Sitabuldi Interchange Station',
        ),
        const RouteLeg(
          mode: TransitMode.metroOrange,
          from: 'Sitabuldi Interchange',
          to: 'Khapri Metro',
          lineOrRoute: 'Orange Line',
          durationMins: 18,
          instruction: 'Take Orange Line southbound to Khapri (8 stations)',
        ),
        const RouteLeg(
          mode: TransitMode.walk,
          from: 'Khapri Metro',
          to: 'Nagpur Airport',
          durationMins: 5,
          instruction: 'Walk 400m east to Airport Terminal',
        ),
      ],
      totalDurationMins: 42,
      fareRupees: 45,
      ecoPassFare: 39.6,
      transfers: 2,
      carbonSavedGrams: 480,
    ),
    RouteOption(
      id: 'r2',
      summary: 'Metro Aqua → Metro Orange',
      tag: '🌿 Greenest',
      legs: [
        const RouteLeg(
          mode: TransitMode.rickshaw,
          from: 'Your Location',
          to: 'Prajapati Nagar Metro',
          durationMins: 6,
          instruction: 'Take feeder e-rickshaw to Prajapati Nagar Station',
        ),
        const RouteLeg(
          mode: TransitMode.metroAqua,
          from: 'Prajapati Nagar',
          to: 'Sitabuldi Interchange',
          lineOrRoute: 'Aqua Line',
          durationMins: 15,
          instruction: 'Take Aqua Line eastbound to Sitabuldi Interchange',
        ),
        const RouteLeg(
          mode: TransitMode.metroOrange,
          from: 'Sitabuldi Interchange',
          to: 'Khapri Metro',
          lineOrRoute: 'Orange Line',
          durationMins: 18,
          instruction: 'Transfer to Orange Line southbound to Khapri',
        ),
        const RouteLeg(
          mode: TransitMode.walk,
          from: 'Khapri Metro',
          to: 'Nagpur Airport',
          durationMins: 5,
          instruction: 'Walk 400m to Airport Terminal',
        ),
      ],
      totalDurationMins: 48,
      fareRupees: 55,
      ecoPassFare: 48.4,
      transfers: 2,
      carbonSavedGrams: 620,
    ),
    RouteOption(
      id: 'r3',
      summary: 'Direct Bus 100',
      tag: '💰 Cheapest',
      legs: [
        const RouteLeg(
          mode: TransitMode.walk,
          from: 'Your Location',
          to: 'Medical Square Bus Stop',
          durationMins: 7,
          instruction: 'Walk 600m to Medical Square Bus Stop',
        ),
        const RouteLeg(
          mode: TransitMode.bus,
          from: 'Medical Square',
          to: 'Airport Bus Terminal',
          lineOrRoute: '100',
          durationMins: 55,
          instruction: 'Board Bus 100 direct to Airport (18 stops)',
        ),
        const RouteLeg(
          mode: TransitMode.walk,
          from: 'Airport Bus Terminal',
          to: 'Nagpur Airport',
          durationMins: 3,
          instruction: 'Walk 150m to Terminal entrance',
        ),
      ],
      totalDurationMins: 65,
      fareRupees: 25,
      ecoPassFare: 22.0,
      transfers: 0,
      carbonSavedGrams: 350,
    ),
  ];

  // ─── Bus Fleet ───────────────────────────────────────────────────
  static const List<BusInfo> busFleet = [
    BusInfo(
      routeNumber: '100',
      routeName: 'Mor Bhavan – Airport',
      corridor: 'Sitabuldi-Hingna',
      currentStop: 'Sitabuldi Bus Stand',
      nextStop: 'Cotton Market',
      nextStopEtaMins: 3,
      speedKmh: 28.5,
      isOnSchedule: true,
      occupancy: OccupancyLevel.low,
      stops: ['Mor Bhavan', 'Gandhibagh', 'Sitabuldi Bus Stand', 'Cotton Market', 'Medical Square', 'Dharampeth', 'LAD College', 'Law College Sq', 'Shankar Nagar', 'Hingna T-Point', 'MIDC Hingna', 'Airport'],
      currentStopIndex: 2,
    ),
    BusInfo(
      routeNumber: '112',
      routeName: 'Wadi – Sadar',
      corridor: 'Pardi Corridor',
      currentStop: 'Pardi Naka',
      nextStop: 'Kamptee Road',
      nextStopEtaMins: 5,
      speedKmh: 22.0,
      isOnSchedule: false,
      occupancy: OccupancyLevel.moderate,
      stops: ['Wadi Bus Stand', 'Wadi Main Road', 'Pardi Naka', 'Kamptee Road', 'Indora Square', 'Bhole Petrol Pump', 'Manas Square', 'Sitabuldi', 'Sadar'],
      currentStopIndex: 2,
    ),
    BusInfo(
      routeNumber: '135',
      routeName: 'Dharampeth – Kamptee',
      corridor: 'Koradi Road',
      currentStop: 'Dharampeth',
      nextStop: 'Telephone Exchange',
      nextStopEtaMins: 2,
      speedKmh: 32.0,
      isOnSchedule: true,
      occupancy: OccupancyLevel.low,
      stops: ['Dharampeth', 'Telephone Exchange', 'Sitabuldi', 'Gandhibagh', 'Cotton Market', 'Itwari', 'Kamptee'],
      currentStopIndex: 0,
    ),
    BusInfo(
      routeNumber: '147',
      routeName: 'Medical Sq – Manewada',
      corridor: 'Sitabuldi-Hingna',
      currentStop: 'IT Park',
      nextStop: 'Manewada Square',
      nextStopEtaMins: 4,
      speedKmh: 18.0,
      isOnSchedule: false,
      occupancy: OccupancyLevel.full,
      stops: ['Medical Square', 'Ramdaspeth', 'Sitabuldi', 'Cotton Market', 'IT Park', 'Manewada Square', 'Manewada'],
      currentStopIndex: 4,
    ),
  ];

  // ─── Active Tickets ──────────────────────────────────────────────
  static List<TicketPass> activeTickets = [
    TicketPass(
      id: 'TKT-2024-001',
      type: TicketType.ecoPass,
      routeAllowed: 'All Routes – Hybrid Pass',
      farePaid: 39.6,
      validFrom: DateTime.now().subtract(const Duration(minutes: 18)),
      validity: const Duration(minutes: 60),
      passengerId: 'ECO-NG-42857',
    ),
    TicketPass(
      id: 'TKT-2024-002',
      type: TicketType.metroQR,
      routeAllowed: 'Orange Line: Sitabuldi → Khapri',
      farePaid: 30.0,
      validFrom: DateTime.now().subtract(const Duration(minutes: 5)),
      validity: const Duration(minutes: 90),
      passengerId: 'MET-NG-12934',
    ),
  ];

  // ─── Journey History ─────────────────────────────────────────────
  static final List<JourneyHistory> journeyHistory = [
    JourneyHistory(
      id: 'j1',
      from: 'Dharampeth',
      to: 'Nagpur Airport',
      date: DateTime.now().subtract(const Duration(days: 1)),
      fare: 39.6,
      carbonSavedGrams: 480,
      modes: [TransitMode.bus, TransitMode.metroOrange],
    ),
    JourneyHistory(
      id: 'j2',
      from: 'VNIT Campus',
      to: 'Sitabuldi',
      date: DateTime.now().subtract(const Duration(days: 2)),
      fare: 15.0,
      carbonSavedGrams: 210,
      modes: [TransitMode.bus],
    ),
    JourneyHistory(
      id: 'j3',
      from: 'Medical Square',
      to: 'Automotive Square',
      date: DateTime.now().subtract(const Duration(days: 3)),
      fare: 25.0,
      carbonSavedGrams: 380,
      modes: [TransitMode.metroOrange],
    ),
    JourneyHistory(
      id: 'j4',
      from: 'Manewada',
      to: 'Lokmanya Nagar',
      date: DateTime.now().subtract(const Duration(days: 5)),
      fare: 48.4,
      carbonSavedGrams: 550,
      modes: [TransitMode.bus, TransitMode.metroAqua],
    ),
  ];

  // ─── SafarBot Chat ───────────────────────────────────────────────
  static List<ChatMessage> initialChat = [
    ChatMessage(
      id: 'c1',
      text: 'Namaste! 🙏 I\'m SafarBot, your Nagpur transit assistant. Ask me about routes, fares, schedules, or anything transit!',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  static const List<String> quickPrompts = [
    '🛫 Airport from Railway Station',
    '🚌 Bus 100 Schedule',
    '💰 Cheapest to Hingna',
    '📱 Metro WhatsApp',
  ];

  // ─── Eco Rewards ─────────────────────────────────────────────────
  static const EcoProfile ecoProfile = EcoProfile(
    totalCo2SavedKg: 42.8,
    greenPoints: 850,
    treesEquivalent: 2.1,
    level: 'Nagpur Green Champ',
    levelProgress: 0.72,
    rank: 14,
  );

  static const List<RewardPerk> rewardPerks = [
    RewardPerk(
      id: 'p1',
      title: 'Metro 20% Off',
      description: 'Flat 20% off on next 5 Metro rides',
      pointsCost: 200,
      iconEmoji: '🚇',
      accentColor: Color(0xFFEA580C),
    ),
    RewardPerk(
      id: 'p2',
      title: 'EV Charging ₹50',
      description: '₹50 credit at any Nagpur EV station',
      pointsCost: 300,
      iconEmoji: '⚡',
      accentColor: Color(0xFF0284C7),
    ),
    RewardPerk(
      id: 'p3',
      title: 'Bus Day Pass',
      description: 'Free Aapli Bus day pass (all routes)',
      pointsCost: 150,
      iconEmoji: '🚌',
      accentColor: Color(0xFF059669),
    ),
    RewardPerk(
      id: 'p4',
      title: 'Café Voucher ₹100',
      description: '₹100 at Nagpur partner cafés',
      pointsCost: 400,
      iconEmoji: '☕',
      accentColor: Color(0xFF7C3AED),
    ),
  ];

  static const List<LeaderboardEntry> leaderboard = [
    LeaderboardEntry(rank: 1, name: 'Priya M.', co2SavedKg: 128.5, badge: '🏆'),
    LeaderboardEntry(rank: 2, name: 'Aarav S.', co2SavedKg: 112.3, badge: '🥈'),
    LeaderboardEntry(rank: 3, name: 'Neha K.', co2SavedKg: 98.7, badge: '🥉'),
    LeaderboardEntry(rank: 4, name: 'Rohan D.', co2SavedKg: 87.2, badge: '🌿'),
    LeaderboardEntry(rank: 5, name: 'Ananya P.', co2SavedKg: 76.4, badge: '🌿'),
    LeaderboardEntry(rank: 6, name: 'Vikram T.', co2SavedKg: 65.1, badge: '🌱'),
  ];

  // ─── User Profile ────────────────────────────────────────────────
  static const UserProfile userProfile = UserProfile(
    name: 'Rohit Sharma',
    phone: '+91 98765 43210',
    hasMahaCard: true,
    savedCommutes: [
      SavedCommute(
        id: 'sc1',
        label: 'Home → Work',
        from: 'Dharampeth',
        to: 'IT Park, Parsodi',
        icon: Icons.work_rounded,
      ),
      SavedCommute(
        id: 'sc2',
        label: 'Home → VNIT Campus',
        from: 'Dharampeth',
        to: 'VNIT South Ambazari Rd',
        icon: Icons.school_rounded,
      ),
      SavedCommute(
        id: 'sc3',
        label: 'Home → Airport',
        from: 'Dharampeth',
        to: 'Nagpur Airport',
        icon: Icons.flight_rounded,
      ),
    ],
  );

  // ─── Corridors for Fleet Filter ──────────────────────────────────
  static const List<String> corridors = [
    'All',
    'Sitabuldi-Hingna',
    'Pardi Corridor',
    'Koradi Road',
    'Sadar-Kamptee',
    'Medical-Manewada',
  ];

  // ─── Transit Hub Suggestions for Autocomplete ────────────────────
  static const List<String> transitHubs = [
    'Sitabuldi Interchange',
    'Mor Bhavan Bus Terminal',
    'Medical Square',
    'Automotive Square Metro',
    'Khapri Metro / Airport',
    'Prajapati Nagar Metro',
    'Lokmanya Nagar Metro',
    'Gandhibagh',
    'VNIT Campus',
    'Dharampeth',
    'IT Park, Parsodi',
    'Cotton Market',
    'Nagpur Railway Station',
    'Hingna T-Point',
    'Kamptee',
    'Sadar',
    'Wadi',
  ];
}
