import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MetroStation {
  final String id;
  final String name;
  final String line; // 'Orange Line' | 'Aqua Line' | 'Interchange'
  final double lat;
  final double lon;

  const MetroStation({
    required this.id,
    required this.name,
    required this.line,
    required this.lat,
    required this.lon,
  });
}

class ChaloBusRoute {
  final String id;
  final String busNumber;
  final String from;
  final String to;
  final int stopsCount;
  final List<String> stops;

  const ChaloBusRoute({
    required this.id,
    required this.busNumber,
    required this.from,
    required this.to,
    required this.stopsCount,
    required this.stops,
  });

  factory ChaloBusRoute.fromJson(Map<String, dynamic> json) {
    return ChaloBusRoute(
      id: json['id']?.toString() ?? '',
      busNumber: json['bus']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      stopsCount: (json['stopsCount'] as num?)?.toInt() ?? 0,
      stops: (json['stops'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class BusStop {
  final String name;
  final double lat;
  final double lon;

  const BusStop({
    required this.name,
    required this.lat,
    required this.lon,
  });

  LatLng get position => LatLng(lat, lon);
}

class TransitDataService {
  static final TransitDataService _instance = TransitDataService._internal();
  factory TransitDataService() => _instance;
  TransitDataService._internal();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // Datasets lookup tables
  final Map<String, double> _metroFaresMatrix = {};
  final List<ChaloBusRoute> _chaloBusRoutes = [];
  final List<LatLng> _orangeLinePolyline = [];
  final List<LatLng> _aquaLinePolyline = [];
  final List<MetroStation> _metroStationsList = [];
  final List<List<LatLng>> _busRoutePolylines = [];
  final List<BusStop> _busStops = [];

  // Cached map layer objects for high-performance FlutterMap rendering
  List<Polyline>? _cachedBusPolylines;
  List<CircleMarker>? _cachedBusStopCircles;
  List<CircleMarker>? _cachedMetroStationCircles;

  // Getters for live UI rendering
  List<LatLng> get orangeLinePolyline => _orangeLinePolyline;
  List<LatLng> get aquaLinePolyline => _aquaLinePolyline;
  List<ChaloBusRoute> get chaloBusRoutes => _chaloBusRoutes;
  List<MetroStation> get allMetroStations => _metroStationsList.isNotEmpty ? _metroStationsList : defaultMetroStations;
  List<List<LatLng>> get busRoutePolylines => _busRoutePolylines;
  List<BusStop> get busStops => _busStops;

  List<Polyline> get cachedBusPolylines {
    if (_cachedBusPolylines != null) return _cachedBusPolylines!;
    _cachedBusPolylines = _busRoutePolylines
        .map((pts) => Polyline(
              points: pts,
              color: const Color(0x990D9488), // Aapli Bus Teal with blend
              strokeWidth: 2.0,
            ))
        .toList(growable: false);
    return _cachedBusPolylines!;
  }

  List<CircleMarker> get cachedBusStopCircles {
    if (_cachedBusStopCircles != null) return _cachedBusStopCircles!;
    _cachedBusStopCircles = _busStops
        .map((s) => CircleMarker(
              point: LatLng(s.lat, s.lon),
              radius: 3.5,
              color: const Color(0xFF0D9488),
              borderColor: const Color(0xFF042F2E),
              borderStrokeWidth: 0.5,
              useRadiusInMeter: false,
            ))
        .toList(growable: false);
    return _cachedBusStopCircles!;
  }

  List<CircleMarker> get cachedMetroStationCircles {
    if (_cachedMetroStationCircles != null) return _cachedMetroStationCircles!;
    final stations = allMetroStations;
    _cachedMetroStationCircles = stations.map((s) {
      final isInterchange = s.line == 'Interchange' || s.name.toLowerCase().contains('sitabuldi');
      final isAqua = s.line.toLowerCase().contains('aqua') || s.line.toLowerCase().contains('blue');
      final color = isInterchange
          ? const Color(0xFF10B981)
          : isAqua
              ? const Color(0xFF00AAFF)
              : const Color(0xFFFF6A00);

      return CircleMarker(
        point: LatLng(s.lat, s.lon),
        radius: isInterchange ? 7.0 : 5.5,
        color: Colors.white,
        borderColor: color,
        borderStrokeWidth: isInterchange ? 3.0 : 2.5,
        useRadiusInMeter: false,
      );
    }).toList(growable: false);
    return _cachedMetroStationCircles!;
  }

  static String normalizeStationName(String name) {
    return name
        .toLowerCase()
        .replaceAll('metro station', '')
        .replaceAll('station', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  /// Default Fallback Metro Stations
  static const List<MetroStation> defaultMetroStations = [
    // Orange Line
    MetroStation(id: 'ST001', name: 'Khapri', line: 'Orange Line', lat: 21.0562, lon: 79.0583),
    MetroStation(id: 'ST002', name: 'New Airport', line: 'Orange Line', lat: 21.0745, lon: 79.0578),
    MetroStation(id: 'ST003', name: 'Airport South', line: 'Orange Line', lat: 21.0841, lon: 79.0580),
    MetroStation(id: 'ST004', name: 'Airport', line: 'Orange Line', lat: 21.0965, lon: 79.0632),
    MetroStation(id: 'ST005', name: 'Ujjwal Nagar', line: 'Orange Line', lat: 21.1062, lon: 79.0684),
    MetroStation(id: 'ST006', name: 'Jaiprakash Nagar', line: 'Orange Line', lat: 21.1145, lon: 79.0732),
    MetroStation(id: 'ST007', name: 'Chhatrapati Square', line: 'Orange Line', lat: 21.1215, lon: 79.0768),
    MetroStation(id: 'ST008', name: 'Ajni Square', line: 'Orange Line', lat: 21.1294, lon: 79.0805),
    MetroStation(id: 'ST009', name: 'Congress Nagar', line: 'Orange Line', lat: 21.1372, lon: 79.0842),
    MetroStation(id: 'ST010', name: 'Rahate Colony', line: 'Orange Line', lat: 21.1415, lon: 79.0861),
    MetroStation(id: 'ST011', name: 'Sitabuldi Interchange', line: 'Interchange', lat: 21.1466, lon: 79.0882),
    MetroStation(id: 'ST012', name: 'Zero Mile Freedom Park', line: 'Orange Line', lat: 21.1498, lon: 79.0806),
    MetroStation(id: 'ST013', name: 'Kasturchand Park', line: 'Orange Line', lat: 21.1552, lon: 79.0835),
    MetroStation(id: 'ST014', name: 'GaddiGodam Square', line: 'Orange Line', lat: 21.1632, lon: 79.0854),
    MetroStation(id: 'ST015', name: 'Kadbi Chowk', line: 'Orange Line', lat: 21.1715, lon: 79.0872),
    MetroStation(id: 'ST016', name: 'Indora Square', line: 'Orange Line', lat: 21.1798, lon: 79.0895),
    MetroStation(id: 'ST017', name: 'Nari Road', line: 'Orange Line', lat: 21.1895, lon: 79.0912),
    MetroStation(id: 'ST018', name: 'Automotive Square', line: 'Orange Line', lat: 21.1995, lon: 79.0935),

    // Aqua Line
    MetroStation(id: 'ST019', name: 'Prajapati Nagar', line: 'Aqua Line', lat: 21.1472, lon: 79.1550),
    MetroStation(id: 'ST020', name: 'Vaishno Devi Chowk', line: 'Aqua Line', lat: 21.1468, lon: 79.1432),
    MetroStation(id: 'ST021', name: 'Ambedkar Chowk', line: 'Aqua Line', lat: 21.1465, lon: 79.1325),
    MetroStation(id: 'ST022', name: 'Telephone Exchange', line: 'Aqua Line', lat: 21.1461, lon: 79.1220),
    MetroStation(id: 'ST023', name: 'Chitar Oli', line: 'Aqua Line', lat: 21.1458, lon: 79.1125),
    MetroStation(id: 'ST024', name: 'Agrasen Chowk', line: 'Aqua Line', lat: 21.1455, lon: 79.1040),
    MetroStation(id: 'ST025', name: 'Dosar Vaisya Square', line: 'Aqua Line', lat: 21.1460, lon: 79.0965),
    MetroStation(id: 'ST026', name: 'Nagpur Railway Station', line: 'Aqua Line', lat: 21.1524, lon: 79.0888),
    MetroStation(id: 'ST027', name: 'Cotton Market', line: 'Aqua Line', lat: 21.1430, lon: 79.0915),
    MetroStation(id: 'ST028', name: 'Jhansi Rani Square', line: 'Aqua Line', lat: 21.1420, lon: 79.0775),
    MetroStation(id: 'ST029', name: 'Institute of Engineers', line: 'Aqua Line', lat: 21.1395, lon: 79.0682),
    MetroStation(id: 'ST030', name: 'Shankar Nagar Square', line: 'Aqua Line', lat: 21.1375, lon: 79.0610),
    MetroStation(id: 'ST031', name: 'LAD Square', line: 'Aqua Line', lat: 21.1352, lon: 79.0535),
    MetroStation(id: 'ST032', name: 'Dharampeth College', line: 'Aqua Line', lat: 21.1310, lon: 79.0465),
    MetroStation(id: 'ST033', name: 'Subhash Nagar', line: 'Aqua Line', lat: 21.1265, lon: 79.0395),
    MetroStation(id: 'ST034', name: 'Rachna Ring Road', line: 'Aqua Line', lat: 21.1230, lon: 79.0320),
    MetroStation(id: 'ST035', name: 'Vasudev Nagar', line: 'Aqua Line', lat: 21.1190, lon: 79.0250),
    MetroStation(id: 'ST036', name: 'Bansi Nagar', line: 'Aqua Line', lat: 21.1145, lon: 79.0175),
    MetroStation(id: 'ST037', name: 'Lokmanya Nagar', line: 'Aqua Line', lat: 21.1095, lon: 79.0090),
  ];

  /// Load static datasets asynchronously from bundle
  Future<void> loadDatasets({bool forceReload = false}) async {
    if (_isLoaded && !forceReload && _busRoutePolylines.isNotEmpty) return;
    try {
      // 1. Load Metro Fares Matrix from metro_fares.json
      final metroStr = await rootBundle.loadString('assets/data/metro_fares.json');
      final dynamic decodedMetro = jsonDecode(metroStr);
      if (decodedMetro is List) {
        for (final row in decodedMetro) {
          if (row is Map) {
            final from = normalizeStationName(row['from_stop_name']?.toString() ?? '');
            final to = normalizeStationName(row['to_stop_name']?.toString() ?? '');
            final fare = (row['fare'] as num?)?.toDouble() ?? 10.0;
            if (from.isNotEmpty && to.isNotEmpty) {
              _metroFaresMatrix['$from:$to'] = fare;
            }
          }
        }
      }

      // 2. Load High Resolution Line Geometries from lineGeometries.json
      final geomStr = await rootBundle.loadString('assets/data/lineGeometries.json');
      final dynamic decodedGeom = jsonDecode(geomStr);
      if (decodedGeom is Map) {
        // Metro Geometries
        if (decodedGeom['metro'] is Map) {
          final metroMap = decodedGeom['metro'] as Map<String, dynamic>;

          // Orange Line
          if (metroMap['Orange Line'] is List) {
            _orangeLinePolyline.clear();
            for (final pt in metroMap['Orange Line']) {
              if (pt is Map && pt['lat'] != null && pt['lon'] != null) {
                _orangeLinePolyline.add(LatLng((pt['lat'] as num).toDouble(), (pt['lon'] as num).toDouble()));
              }
            }
          }

          // Aqua / Blue Line
          if (metroMap['Blue Line'] is List) {
            _aquaLinePolyline.clear();
            for (final pt in metroMap['Blue Line']) {
              if (pt is Map && pt['lat'] != null && pt['lon'] != null) {
                _aquaLinePolyline.add(LatLng((pt['lat'] as num).toDouble(), (pt['lon'] as num).toDouble()));
              }
            }
          }
        }

        // Bus Route Geometries (837 routes spanning Nagpur)
        if (decodedGeom['bus'] is Map) {
          _busRoutePolylines.clear();
          final busMap = decodedGeom['bus'] as Map<String, dynamic>;
          for (final routeList in busMap.values) {
            if (routeList is List && routeList.isNotEmpty) {
              final poly = <LatLng>[];
              for (final pt in routeList) {
                if (pt is Map && pt['lat'] != null && pt['lon'] != null) {
                  poly.add(LatLng((pt['lat'] as num).toDouble(), (pt['lon'] as num).toDouble()));
                }
              }
              if (poly.length >= 2) {
                _busRoutePolylines.add(poly);
              }
            }
          }
        }
      }

      // 3. Load Aapli Bus Routes Catalog from chalo_routes_index.json
      final chaloStr = await rootBundle.loadString('assets/data/chalo_routes_index.json');
      final dynamic decodedChalo = jsonDecode(chaloStr);
      if (decodedChalo is List) {
        _chaloBusRoutes.clear();
        for (final r in decodedChalo) {
          if (r is Map<String, dynamic>) {
            _chaloBusRoutes.add(ChaloBusRoute.fromJson(r));
          }
        }
      }

      // 4. Load Stations and Bus Stops from network.json
      final netStr = await rootBundle.loadString('assets/data/network.json');
      final dynamic decodedNet = jsonDecode(netStr);
      if (decodedNet is Map) {
        // Metro Stations
        if (decodedNet['metro'] is List) {
          _metroStationsList.clear();
          for (final lineObj in decodedNet['metro']) {
            final lineName = lineObj['line']?.toString() ?? 'Metro';
            final friendlyLine = lineName.contains('Blue') ? 'Aqua Line' : 'Orange Line';
            if (lineObj['stations'] is List) {
              for (final st in lineObj['stations']) {
                final name = st['name']?.toString() ?? '';
                final lat = (st['lat'] as num?)?.toDouble() ?? 21.1458;
                final lon = (st['lon'] as num?)?.toDouble() ?? 79.0882;
                _metroStationsList.add(MetroStation(
                  id: 'ST_${_metroStationsList.length + 1}',
                  name: name,
                  line: name.toLowerCase().contains('sitabuldi') ? 'Interchange' : friendlyLine,
                  lat: lat,
                  lon: lon,
                ));
              }
            }
          }
        }

        // Bus Stops (3487 unique transit stops)
        if (decodedNet['bus'] != null) {
          _busStops.clear();
          final seenKeys = <String>{};
          final busList = decodedNet['bus'] is List
              ? decodedNet['bus'] as List
              : (decodedNet['bus'] as Map).values.toList();
          for (final r in busList) {
            if (r is Map && r['stops'] is List) {
              for (final s in r['stops']) {
                if (s is Map && s['lat'] != null && s['lon'] != null) {
                  final lat = (s['lat'] as num).toDouble();
                  final lon = (s['lon'] as num).toDouble();
                  final key = '${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
                  if (seenKeys.add(key)) {
                    _busStops.add(BusStop(
                      name: s['name']?.toString() ?? 'Bus Stop',
                      lat: lat,
                      lon: lon,
                    ));
                  }
                }
              }
            }
          }
        }
      }

      // Invalidate caches to recreate with updated points
      _cachedBusPolylines = null;
      _cachedBusStopCircles = null;
      _cachedMetroStationCircles = null;

      _isLoaded = true;
      debugPrint('🟢 [TransitDataService] Loaded ${_metroFaresMatrix.length} fare rules, ${_orangeLinePolyline.length} Orange track points, ${_aquaLinePolyline.length} Aqua track points, ${_busRoutePolylines.length} bus polylines, ${_busStops.length} bus stops, ${_chaloBusRoutes.length} Aapli bus routes.');
    } catch (e) {
      debugPrint('⚠️ [TransitDataService] Dataset load note: $e');
      _isLoaded = true;
    }
  }

  /// Calculate exact Metro Fare from the live FYP Nagpur dataset
  double calculateMetroFare({
    required String fromStation,
    required String toStation,
    bool hasMahaCard = false,
  }) {
    final normFrom = normalizeStationName(fromStation);
    final normTo = normalizeStationName(toStation);

    if (normFrom == normTo || normFrom.isEmpty || normTo.isEmpty) return 0.0;

    // Check direct matrix lookup
    if (_metroFaresMatrix.containsKey('$normFrom:$normTo')) {
      final base = _metroFaresMatrix['$normFrom:$normTo']!;
      return hasMahaCard ? (base * 0.9).roundToDouble() : base;
    }
    if (_metroFaresMatrix.containsKey('$normTo:$normFrom')) {
      final base = _metroFaresMatrix['$normTo:$normFrom']!;
      return hasMahaCard ? (base * 0.9).roundToDouble() : base;
    }

    // Fuzzy matching against stations in matrix
    for (final entry in _metroFaresMatrix.entries) {
      final parts = entry.key.split(':');
      if (parts.length == 2) {
        if ((parts[0].contains(normFrom) || normFrom.contains(parts[0])) &&
            (parts[1].contains(normTo) || normTo.contains(parts[1]))) {
          final base = entry.value;
          return hasMahaCard ? (base * 0.9).roundToDouble() : base;
        }
      }
    }

    // Official MahaMetro Tariff Fallback:
    final all = allMetroStations;
    final idx1 = all.indexWhere((s) => normalizeStationName(s.name).contains(normFrom) || normFrom.contains(normalizeStationName(s.name)));
    final idx2 = all.indexWhere((s) => normalizeStationName(s.name).contains(normTo) || normTo.contains(normalizeStationName(s.name)));

    double base = 20.0;
    if (idx1 != -1 && idx2 != -1) {
      final count = (idx1 - idx2).abs();
      if (count <= 3) {
        base = 10.0;
      } else if (count <= 6) {
        base = 20.0;
      } else if (count <= 12) {
        base = 30.0;
      } else {
        base = 35.0;
      }
    }

    return hasMahaCard ? (base * 0.9).roundToDouble() : base;
  }
}
