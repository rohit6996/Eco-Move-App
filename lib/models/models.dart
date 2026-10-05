/// Data models for Eco-Move Nagpur transit system.
/// Clean PODOs decoupled from any backend so wiring is seamless later.
library;

import 'package:flutter/material.dart';

// ─── Transit Mode ──────────────────────────────────────────────────
enum TransitMode { bus, metroOrange, metroAqua, walk, rickshaw, evShuttle }

extension TransitModeExt on TransitMode {
  String get label => switch (this) {
    TransitMode.bus => 'Aapli Bus',
    TransitMode.metroOrange => 'Metro Orange',
    TransitMode.metroAqua => 'Metro Aqua',
    TransitMode.walk => 'Walk',
    TransitMode.rickshaw => 'E-Rickshaw',
    TransitMode.evShuttle => 'EV Shuttle',
  };

  IconData get icon => switch (this) {
    TransitMode.bus => Icons.directions_bus_rounded,
    TransitMode.metroOrange => Icons.train_rounded,
    TransitMode.metroAqua => Icons.train_rounded,
    TransitMode.walk => Icons.directions_walk_rounded,
    TransitMode.rickshaw => Icons.electric_rickshaw_rounded,
    TransitMode.evShuttle => Icons.electric_car_rounded,
  };

  Color get color => switch (this) {
    TransitMode.bus => const Color(0xFF059669),
    TransitMode.metroOrange => const Color(0xFFEA580C),
    TransitMode.metroAqua => const Color(0xFF0284C7),
    TransitMode.walk => const Color(0xFF64748B),
    TransitMode.rickshaw => const Color(0xFF7C3AED),
    TransitMode.evShuttle => const Color(0xFF0891B2),
  };
}

// ─── Route Leg ─────────────────────────────────────────────────────
class RouteLeg {
  final TransitMode mode;
  final String from;
  final String to;
  final String? lineOrRoute;
  final int durationMins;
  final String instruction;

  const RouteLeg({
    required this.mode,
    required this.from,
    required this.to,
    this.lineOrRoute,
    required this.durationMins,
    required this.instruction,
  });
}

// ─── Route Option ──────────────────────────────────────────────────
class RouteOption {
  final String id;
  final String summary;
  final List<RouteLeg> legs;
  final int totalDurationMins;
  final double fareRupees;
  final double ecoPassFare;
  final int transfers;
  final int carbonSavedGrams;
  final String tag; // "Fastest", "Cheapest", "Greenest"

  const RouteOption({
    required this.id,
    required this.summary,
    required this.legs,
    required this.totalDurationMins,
    required this.fareRupees,
    required this.ecoPassFare,
    required this.transfers,
    required this.carbonSavedGrams,
    this.tag = '',
  });
}

// ─── Bus ────────────────────────────────────────────────────────────
enum OccupancyLevel { low, moderate, full }

extension OccupancyLevelExt on OccupancyLevel {
  String get label => switch (this) {
    OccupancyLevel.low => 'Low',
    OccupancyLevel.moderate => 'Moderate',
    OccupancyLevel.full => 'Full',
  };

  Color get color => switch (this) {
    OccupancyLevel.low => const Color(0xFF10B981),
    OccupancyLevel.moderate => const Color(0xFFF59E0B),
    OccupancyLevel.full => const Color(0xFFEF4444),
  };

  IconData get icon => switch (this) {
    OccupancyLevel.low => Icons.event_seat_rounded,
    OccupancyLevel.moderate => Icons.airline_seat_recline_normal_rounded,
    OccupancyLevel.full => Icons.no_transfer_rounded,
  };
}

class BusInfo {
  final String routeNumber;
  final String routeName;
  final String corridor;
  final String currentStop;
  final String nextStop;
  final int nextStopEtaMins;
  final double speedKmh;
  final bool isOnSchedule;
  final OccupancyLevel occupancy;
  final List<String> stops;
  final int currentStopIndex;

  const BusInfo({
    required this.routeNumber,
    required this.routeName,
    required this.corridor,
    required this.currentStop,
    required this.nextStop,
    required this.nextStopEtaMins,
    required this.speedKmh,
    required this.isOnSchedule,
    required this.occupancy,
    required this.stops,
    required this.currentStopIndex,
  });
}

// ─── Ticket / Pass ─────────────────────────────────────────────────
enum TicketType { ecoPass, metroQR, aapliBus }

extension TicketTypeExt on TicketType {
  String get label => switch (this) {
    TicketType.ecoPass => 'Eco-Pass',
    TicketType.metroQR => 'Metro QR',
    TicketType.aapliBus => 'Aapli Bus',
  };

  String get emoji => switch (this) {
    TicketType.ecoPass => '🟢',
    TicketType.metroQR => '🚇',
    TicketType.aapliBus => '🚌',
  };

  Color get color => switch (this) {
    TicketType.ecoPass => const Color(0xFF059669),
    TicketType.metroQR => const Color(0xFFEA580C),
    TicketType.aapliBus => const Color(0xFF0284C7),
  };
}

class TicketPass {
  final String id;
  final TicketType type;
  final String routeAllowed;
  final double farePaid;
  final DateTime validFrom;
  final Duration validity;
  final String passengerId;
  final bool isActive;

  const TicketPass({
    required this.id,
    required this.type,
    required this.routeAllowed,
    required this.farePaid,
    required this.validFrom,
    required this.validity,
    required this.passengerId,
    this.isActive = true,
  });

  Duration get remainingValidity {
    final expiry = validFrom.add(validity);
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

// ─── Journey History ───────────────────────────────────────────────
class JourneyHistory {
  final String id;
  final String from;
  final String to;
  final DateTime date;
  final double fare;
  final int carbonSavedGrams;
  final List<TransitMode> modes;

  const JourneyHistory({
    required this.id,
    required this.from,
    required this.to,
    required this.date,
    required this.fare,
    required this.carbonSavedGrams,
    required this.modes,
  });
}

// ─── Chat Message ──────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final RouteOption? routeCard;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.routeCard,
  });
}

// ─── Eco-Rewards ───────────────────────────────────────────────────
class EcoProfile {
  final double totalCo2SavedKg;
  final int greenPoints;
  final double treesEquivalent;
  final String level;
  final double levelProgress; // 0.0 to 1.0
  final int rank;

  const EcoProfile({
    required this.totalCo2SavedKg,
    required this.greenPoints,
    required this.treesEquivalent,
    required this.level,
    required this.levelProgress,
    required this.rank,
  });
}

class RewardPerk {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String iconEmoji;
  final Color accentColor;

  const RewardPerk({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.iconEmoji,
    required this.accentColor,
  });
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final double co2SavedKg;
  final String badge;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.co2SavedKg,
    required this.badge,
  });
}

// ─── User Profile ──────────────────────────────────────────────────
class UserProfile {
  final String name;
  final String phone;
  final String? avatarUrl;
  final bool hasMahaCard;
  final List<SavedCommute> savedCommutes;

  const UserProfile({
    required this.name,
    required this.phone,
    this.avatarUrl,
    required this.hasMahaCard,
    required this.savedCommutes,
  });
}

class SavedCommute {
  final String id;
  final String label;
  final String from;
  final String to;
  final IconData icon;

  const SavedCommute({
    required this.id,
    required this.label,
    required this.from,
    required this.to,
    required this.icon,
  });
}
