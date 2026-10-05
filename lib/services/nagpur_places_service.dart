import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'backend_config.dart';
import 'transit_data_service.dart';

/// Point of Interest model for Nagpur unified places & transit search
class NagpurPOI {
  final String id;
  final String name;
  final String category;
  final String subtitle;
  final double lat;
  final double lon;
  final String kind; // 'metro' | 'bus' | 'poi' | 'online' | 'coord'
  final List<String> keywords;
  final String? lineName;

  const NagpurPOI({
    required this.id,
    required this.name,
    required this.category,
    required this.subtitle,
    required this.lat,
    required this.lon,
    this.kind = 'poi',
    this.keywords = const [],
    this.lineName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'subtitle': subtitle,
        'lat': lat,
        'lon': lon,
        'kind': kind,
        'lineName': lineName,
      };
}

class NagpurPlacesService {
  static final NagpurPlacesService _instance = NagpurPlacesService._internal();
  factory NagpurPlacesService() => _instance;
  NagpurPlacesService._internal();

  // In-memory cache for live geocoded search queries
  final Map<String, List<NagpurPOI>> _onlineCache = {};

  // ── Curated Nagpur POIs ──────────────────────────────────────────
  static const List<NagpurPOI> curatedPlaces = [
    // ── Transit Hubs ──
    NagpurPOI(
      id: 'poi_sitabuldi_interchange',
      name: 'Sitabuldi Interchange Metro Station',
      category: 'Transit',
      subtitle: 'Central Nagpur Metro Hub (Aqua & Orange Line)',
      lat: 21.1466,
      lon: 79.0882,
      kind: 'metro',
      lineName: 'Orange & Aqua Interchange',
      keywords: ['sitabuldi', 'metro', 'interchange', 'central', 'station', 'orange', 'aqua'],
    ),
    NagpurPOI(
      id: 'poi_nagpur_railway_station',
      name: 'Nagpur Central Railway Station',
      category: 'Transit',
      subtitle: 'Station Road, Sitabuldi, Nagpur',
      lat: 21.1524,
      lon: 79.0888,
      kind: 'metro',
      lineName: 'Central Railway Hub',
      keywords: ['railway', 'station', 'train', 'irctc', 'sitabuldi', 'central'],
    ),
    NagpurPOI(
      id: 'poi_nagpur_airport',
      name: 'Dr. Babasaheb Ambedkar Airport (NAG)',
      category: 'Transit',
      subtitle: 'Sonegaon, Wardha Road, Nagpur',
      lat: 21.0922,
      lon: 79.0472,
      kind: 'poi',
      keywords: ['airport', 'flight', 'sonegaon', 'wardha', 'nag', 'terminal'],
    ),
    NagpurPOI(
      id: 'poi_mor_bhavan',
      name: 'Mor Bhavan City Bus Terminus',
      category: 'Transit',
      subtitle: 'Sitabuldi, Aapli Bus Main Terminal',
      lat: 21.1441,
      lon: 79.0817,
      kind: 'bus',
      keywords: ['mor bhavan', 'bus stand', 'aapli bus', 'city bus', 'terminus'],
    ),
    NagpurPOI(
      id: 'poi_ganeshpeth_bus_stand',
      name: 'Ganeshpeth MSRTC Central Bus Stand (ST Stand)',
      category: 'Transit',
      subtitle: 'Ganeshpeth Colony, Nagpur',
      lat: 21.1438,
      lon: 79.0995,
      kind: 'bus',
      keywords: ['ganeshpeth', 'st stand', 'msrtc', 'shivshahi', 'intercity'],
    ),
    NagpurPOI(
      id: 'poi_zero_mile',
      name: 'Zero Mile Freedom Park & Monument',
      category: 'Monument',
      subtitle: 'Geographical Center of India, Civil Lines',
      lat: 21.1498,
      lon: 79.0806,
      kind: 'metro',
      lineName: 'Orange Line',
      keywords: ['zero mile', 'center', 'india', 'freedom park', 'monument', 'metro'],
    ),

    // ── Malls & Shopping ──
    NagpurPOI(
      id: 'poi_vr_mall',
      name: 'VR Mall (Trillium Mall)',
      category: 'Mall',
      subtitle: 'Medical Square, Rambagh, Nagpur',
      lat: 21.1325,
      lon: 79.0965,
      kind: 'poi',
      keywords: ['vr mall', 'trillium', 'shopping', 'inox', 'medical square', 'zara', 'h&m'],
    ),
    NagpurPOI(
      id: 'poi_eternity_mall',
      name: 'Eternity Mall',
      category: 'Mall',
      subtitle: 'Variety Square, Sitabuldi, Nagpur',
      lat: 21.1447,
      lon: 79.0833,
      kind: 'poi',
      keywords: ['eternity mall', 'cinemax', 'variety square', 'sitabuldi', 'shopping'],
    ),
    NagpurPOI(
      id: 'poi_empresse_mall',
      name: 'Empress Mall',
      category: 'Mall',
      subtitle: 'Near Raman Science Centre, Empress City',
      lat: 21.1478,
      lon: 79.0972,
      kind: 'poi',
      keywords: ['empress mall', 'shopping', 'raman science', 'cotton market'],
    ),

    // ── Attractions & Lakes ──
    NagpurPOI(
      id: 'poi_futala_lake',
      name: 'Futala Lake Promenade & Musical Fountain',
      category: 'Park',
      subtitle: 'Telangkhedi, West Nagpur',
      lat: 21.1539,
      lon: 79.0435,
      kind: 'poi',
      keywords: ['futala', 'lake', 'fountain', 'chowpatty', 'telangkhedi', 'sunset'],
    ),
    NagpurPOI(
      id: 'poi_ambazari_lake',
      name: 'Ambazari Lake & Biodiversity Garden',
      category: 'Park',
      subtitle: 'Ambazari, South-West Nagpur',
      lat: 21.1275,
      lon: 79.0412,
      kind: 'poi',
      keywords: ['ambazari', 'lake', 'garden', 'boating', 'swami vivekanand'],
    ),
    NagpurPOI(
      id: 'poi_deekshabhoomi',
      name: 'Deekshabhoomi Sacred Stupa',
      category: 'Monument',
      subtitle: 'Laxmi Nagar, South Nagpur',
      lat: 21.1278,
      lon: 79.0669,
      kind: 'poi',
      keywords: ['deekshabhoomi', 'stupa', 'buddhist', 'ambedkar', 'monument'],
    ),
    NagpurPOI(
      id: 'poi_tekdi_ganesh',
      name: 'Shree Tekdi Ganesh Mandir',
      category: 'Temple',
      subtitle: 'Near Railway Station, Sitabuldi',
      lat: 21.1502,
      lon: 79.0874,
      kind: 'poi',
      keywords: ['tekdi ganesh', 'temple', 'mandir', 'ganpati', 'sitabuldi'],
    ),
    NagpurPOI(
      id: 'poi_koradi_temple',
      name: 'Shri Mahalaxmi Jagdamba Temple Koradi',
      category: 'Temple',
      subtitle: 'Koradi, North Nagpur',
      lat: 21.2483,
      lon: 79.0964,
      kind: 'poi',
      keywords: ['koradi', 'temple', 'mahalaxmi', 'devi', 'mandir'],
    ),
    NagpurPOI(
      id: 'poi_dragon_palace',
      name: 'Dragon Palace Buddhist Temple',
      category: 'Temple',
      subtitle: 'Kamptee, Nagpur',
      lat: 21.2223,
      lon: 79.1989,
      kind: 'poi',
      keywords: ['dragon palace', 'kamptee', 'lotus temple', 'buddhist'],
    ),

    // ── Food & Restaurants ──
    NagpurPOI(
      id: 'poi_haldirams_sadar',
      name: "Haldiram's Planet Food",
      category: 'Restaurant',
      subtitle: 'Mount Road, Sadar, Nagpur',
      lat: 21.1612,
      lon: 79.0831,
      kind: 'poi',
      keywords: ['haldiram', 'food', 'sweets', 'sadar', 'restaurant', 'orange barfi'],
    ),
    NagpurPOI(
      id: 'poi_haldirams_sitabuldi',
      name: "Haldiram's Sweets & Restaurant",
      category: 'Restaurant',
      subtitle: 'Main Road, Sitabuldi, Nagpur',
      lat: 21.1450,
      lon: 79.0865,
      kind: 'poi',
      keywords: ['haldiram', 'sitabuldi', 'restaurant', 'sweets', 'thali'],
    ),

    // ── Hospitals & Healthcare ──
    NagpurPOI(
      id: 'poi_aiims_nagpur',
      name: 'AIIMS Nagpur',
      category: 'Hospital',
      subtitle: 'MIHAN SEZ, South Nagpur',
      lat: 21.0425,
      lon: 79.0278,
      kind: 'poi',
      keywords: ['aiims', 'hospital', 'mihan', 'medical', 'emergency'],
    ),
    NagpurPOI(
      id: 'poi_gmc_nagpur',
      name: 'Government Medical College (GMC)',
      category: 'Hospital',
      subtitle: 'Medical Square, Hanuman Nagar, Nagpur',
      lat: 21.1345,
      lon: 79.0982,
      kind: 'poi',
      keywords: ['gmc', 'medical college', 'medical square', 'hospital', 'emergency'],
    ),
    NagpurPOI(
      id: 'poi_care_hospital',
      name: 'CARE Hospitals',
      category: 'Hospital',
      subtitle: 'Panchsheel Square, Wardha Road',
      lat: 21.1382,
      lon: 79.0805,
      kind: 'poi',
      keywords: ['care hospital', 'panchsheel', 'wardha road', 'hospital'],
    ),
    NagpurPOI(
      id: 'poi_kingsway_hospital',
      name: 'Kingsway Hospital',
      category: 'Hospital',
      subtitle: 'Near Nagpur Railway Station, Mohan Nagar',
      lat: 21.1565,
      lon: 79.0872,
      kind: 'poi',
      keywords: ['kingsway', 'hospital', 'railway station', 'emergency', 'mohan nagar'],
    ),

    // ── Tech & Education Hubs ──
    NagpurPOI(
      id: 'poi_vnit',
      name: 'VNIT Nagpur (Visvesvaraya National NIT)',
      category: 'College',
      subtitle: 'South Ambazari Road, Bajaj Nagar',
      lat: 21.1255,
      lon: 79.0515,
      kind: 'poi',
      keywords: ['vnit', 'engineering', 'nit', 'bajaj nagar', 'campus'],
    ),
    NagpurPOI(
      id: 'poi_iim_nagpur',
      name: 'IIM Nagpur & Infosys MIHAN',
      category: 'College',
      subtitle: 'MIHAN SEZ, Nagpur',
      lat: 21.0489,
      lon: 79.0344,
      kind: 'poi',
      keywords: ['iim', 'mihan', 'infosys', 'tcs', 'tech park', 'sez'],
    ),
    NagpurPOI(
      id: 'poi_it_park',
      name: 'Nagpur IT Park (Gayatri Tech Park)',
      category: 'Office',
      subtitle: 'Parsodi, Subhash Nagar, South Ambazari',
      lat: 21.1218,
      lon: 79.0492,
      kind: 'poi',
      keywords: ['it park', 'parsodi', 'subhash nagar', 'tech', 'software'],
    ),
  ];

  // ── Coordinate Input Parser ──────────────────────────────────────
  NagpurPOI? parseCoordinateInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final coordRegex = RegExp(
      r'^\s*(?:lat(?:itude)?[:\s]*)?([+-]?\d+(?:\.\d+)?)\s*(?:°?\s*[NSns])?[,\s]+(?:lon(?:gitude)?[:\s]*)?([+-]?\d+(?:\.\d+)?)\s*(?:°?\s*[EWew])?\s*$',
      caseSensitive: false,
    );
    final match = coordRegex.firstMatch(trimmed);
    if (match == null) return null;

    final lat = double.tryParse(match.group(1) ?? '');
    final lon = double.tryParse(match.group(2) ?? '');
    if (lat == null || lon == null) return null;

    if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
      return NagpurPOI(
        id: 'coord_${lat.toStringAsFixed(5)}_${lon.toStringAsFixed(5)}',
        name: 'Coordinates (${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)})',
        category: 'GPS Coords',
        subtitle: 'Exact Location [Lat: ${lat.toStringAsFixed(5)}, Lon: ${lon.toStringAsFixed(5)}]',
        lat: lat,
        lon: lon,
        kind: 'coord',
        keywords: [trimmed.toLowerCase()],
      );
    }
    return null;
  }

  // ── Nagpur Phonetic Normalization ────────────────────────────────
  String normalizeNagpurPlaceName(String str) {
    if (str.isEmpty) return '';
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'\bsqaure\b|\bsquar\b|\bsq\b|\bsqr\b', caseSensitive: false), 'square')
        .replaceAll(RegExp(r'\bchhatrapti\b|\bchhatrpati\b|\bchatrapati\b|\bchatrapti\b|\bchhatrapati chowk\b', caseSensitive: false), 'chhatrapati')
        .replaceAll(RegExp(r'\bsitaburdi\b|\bsitabardi\b|\bsitaburdee\b', caseSensitive: false), 'sitabuldi')
        .replaceAll(RegExp(r'\bdharmpeth\b|\bdharampet\b', caseSensitive: false), 'dharampeth')
        .replaceAll(RegExp(r'\bprajapti\b', caseSensitive: false), 'prajapati')
        .replaceAll(RegExp(r'\bwardha rd\b', caseSensitive: false), 'wardha road')
        .replaceAll(RegExp(r'\bkhamla sq\b|\bkhamla sqaure\b', caseSensitive: false), 'khamla square')
        .replaceAll(RegExp(r'\bmanish ngr\b', caseSensitive: false), 'manish nagar')
        .replaceAll(RegExp(r'\bshankar ngr\b', caseSensitive: false), 'shankar nagar')
        .replaceAll(RegExp(r'\bmedical sq\b|\bmedical sqaure\b', caseSensitive: false), 'medical square')
        .replaceAll(RegExp(r'\blaw clg\b|\blaw college sq\b', caseSensitive: false), 'law college square')
        .replaceAll(RegExp(r'\bdr\.?\s*babasaheb\s*ambedkar\s*(?:international)?\s*airport\b|\bnagpur\s*airport\b', caseSensitive: false), 'airport')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ── Category Mapping for Google Types ────────────────────────────
  String _getCategoryFromGoogleTypes(List<String> types) {
    final t = types.map((x) => x.toLowerCase()).toList();
    if (t.any((x) => [
          'restaurant', 'cafe', 'food', 'bakery', 'bar', 'meal_takeaway',
          'meal_delivery', 'fast_food_restaurant', 'family_restaurant', 'indian_restaurant'
        ].contains(x))) {
      return 'Restaurant';
    }
    if (t.any((x) => [
          'hospital', 'doctor', 'health', 'pharmacy', 'clinic', 'dentist', 'medical_lab'
        ].contains(x))) {
      return 'Hospital';
    }
    if (t.any((x) => [
          'school', 'university', 'college', 'secondary_school', 'primary_school', 'library'
        ].contains(x))) {
      return 'College';
    }
    if (t.any((x) => ['shopping_mall', 'department_store'].contains(x))) {
      return 'Mall';
    }
    if (t.any((x) => [
          'store', 'supermarket', 'clothing_store', 'grocery_or_supermarket',
          'convenience_store', 'electronics_store', 'home_goods_store', 'shoe_store',
          'jewelry_store', 'hardware_store', 'book_store', 'candy_store', 'food_store'
        ].contains(x))) {
      return 'Shop';
    }
    if (t.any((x) => ['bank', 'atm', 'finance', 'accounting'].contains(x))) {
      return 'Bank';
    }
    if (t.any((x) => [
          'park', 'tourist_attraction', 'campground', 'natural_feature', 'amusement_park', 'zoo', 'garden'
        ].contains(x))) {
      return 'Park';
    }
    if (t.any((x) => [
          'hindu_temple', 'church', 'mosque', 'synagogue', 'place_of_worship', 'shrine'
        ].contains(x))) {
      return 'Temple';
    }
    if (t.any((x) => [
          'lodging', 'hotel', 'resort', 'motel', 'guest_house', 'bed_and_breakfast'
        ].contains(x))) {
      return 'Hotel';
    }
    if (t.any((x) => [
          'sublocality', 'sublocality_level_1', 'sublocality_level_2', 'neighborhood',
          'administrative_area_level_2', 'locality', 'political', 'intersection'
        ].contains(x))) {
      return 'Locality';
    }
    if (t.any((x) => [
          'transit_station', 'subway_station', 'bus_station', 'train_station', 'light_rail_station'
        ].contains(x))) {
      return 'Transit';
    }
    return 'Place';
  }

  // ── Local Places Search (Transit Stops & Curated POIs) ───────────
  List<NagpurPOI> searchLocalPlaces(String q, {int limit = 20}) {
    final query = q.toLowerCase().trim();
    if (query.isEmpty) return [];
    final normalizedQuery = normalizeNagpurPlaceName(query);

    final results = <NagpurPOI>[];
    final seenNames = <String>{};

    // 1. Exact GPS Coordinates check
    final parsedCoord = parseCoordinateInput(q);
    if (parsedCoord != null) {
      results.add(parsedCoord);
    }

    // 2. Curated Nagpur POIs
    for (final poi in curatedPlaces) {
      final poiLower = poi.name.toLowerCase();
      final poiNormalized = normalizeNagpurPlaceName(poiLower);
      final nameMatch = poiLower.contains(query) ||
          poiLower.contains(normalizedQuery) ||
          poiNormalized.contains(normalizedQuery);
      final kwMatch = poi.keywords.any((k) =>
          k.toLowerCase().contains(query) ||
          normalizeNagpurPlaceName(k.toLowerCase()).contains(normalizedQuery));
      final subMatch = poi.subtitle.toLowerCase().contains(query) ||
          normalizeNagpurPlaceName(poi.subtitle.toLowerCase()).contains(normalizedQuery);

      if (nameMatch || kwMatch || subMatch) {
        results.add(poi);
        seenNames.add(poiLower);
      }
    }

    // 3. Metro Stations from TransitDataService
    final transitService = TransitDataService();
    for (final station in transitService.allMetroStations) {
      final nameLower = station.name.toLowerCase();
      if (seenNames.contains(nameLower)) continue;
      final nameNormalized = normalizeNagpurPlaceName(nameLower);

      if (nameLower.contains(query) ||
          nameLower.contains(normalizedQuery) ||
          nameNormalized.contains(normalizedQuery)) {
        results.add(NagpurPOI(
          id: 'metro_${station.id}',
          name: station.name,
          category: 'Metro Station',
          subtitle: 'Nagpur Metro Rail (${station.line})',
          lat: station.lat,
          lon: station.lon,
          kind: 'metro',
          lineName: station.line,
          keywords: [nameLower, 'metro'],
        ));
        seenNames.add(nameLower);
      }
    }

    // 4. Aapli Bus Stops from TransitDataService (3,487 stops)
    for (final stop in transitService.busStops) {
      final nameLower = stop.name.toLowerCase();
      if (seenNames.contains(nameLower)) continue;
      final nameNormalized = normalizeNagpurPlaceName(nameLower);

      if (nameLower.contains(query) ||
          nameLower.contains(normalizedQuery) ||
          nameNormalized.contains(normalizedQuery)) {
        results.add(NagpurPOI(
          id: 'bus_stop_${stop.name.hashCode}',
          name: stop.name,
          category: 'Bus Stop',
          subtitle: 'Aapli City Bus Stop · Nagpur',
          lat: stop.lat,
          lon: stop.lon,
          kind: 'bus',
          keywords: [nameLower, 'bus'],
        ));
        seenNames.add(nameLower);
        if (results.length >= limit * 2) break;
      }
    }

    // Sort: coords first, then exact start matches, then length
    results.sort((a, b) {
      if (a.kind == 'coord') return -1;
      if (b.kind == 'coord') return 1;
      final aStarts = a.name.toLowerCase().startsWith(query) ? 0 : 1;
      final bStarts = b.name.toLowerCase().startsWith(query) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return a.name.length - b.name.length;
    });

    return results.take(limit).toList();
  }

  // ── Google Places API (New) Autocomplete ─────────────────────────
  Future<List<NagpurPOI>> _fetchGooglePlaces(String query) async {
    final apiKey = BackendConfig.googleMapsApiKey.trim();
    if (apiKey.isEmpty) return [];

    const autoUrl = 'https://places.googleapis.com/v1/places:autocomplete';
    try {
      final res = await http
          .post(
            Uri.parse(autoUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': apiKey,
            },
            body: jsonEncode({
              'input': query,
              'includedRegionCodes': ['IN'],
              'locationRestriction': {
                'circle': {
                  'center': {'latitude': 21.1458, 'longitude': 79.0882},
                  'radius': 35000.0, // Strictly 35 km boundary around Nagpur
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List<dynamic>? ?? [];
      if (suggestions.isEmpty) return [];

      // Filter predictions for Nagpur region
      final validPredictions = <Map<String, dynamic>>[];
      for (final s in suggestions) {
        final pred = s['placePrediction'] as Map<String, dynamic>?;
        if (pred == null) continue;
        final placeId = pred['placeId'] as String?;
        if (placeId == null || placeId.isEmpty) continue;

        final fullText = (pred['text']?['text'] as String? ?? '').toLowerCase();
        final secondary = (pred['structuredFormat']?['secondaryText']?['text'] as String? ?? '').toLowerCase();
        if (fullText.contains('nagpur') ||
            secondary.contains('nagpur') ||
            secondary.contains('maharashtra') ||
            secondary.isEmpty) {
          validPredictions.add(pred);
        }
        if (validPredictions.length >= 8) break;
      }

      if (validPredictions.isEmpty) return [];

      // Resolve coordinates & details in parallel
      final futures = validPredictions.map((p) async {
        try {
          final placeId = p['placeId'] as String;
          final fullAddress = p['text']?['text'] as String? ?? '';

          // Method 1: Google Places Details API (New)
          if (!placeId.startsWith('E')) {
            final detRes = await http
                .get(
                  Uri.parse('https://places.googleapis.com/v1/places/$placeId?fields=id,displayName,formattedAddress,location,types'),
                  headers: {
                    'X-Goog-Api-Key': apiKey,
                    'X-Goog-FieldMask': 'id,displayName,formattedAddress,location,types',
                  },
                )
                .timeout(const Duration(seconds: 3));

            if (detRes.statusCode == 200) {
              final detData = jsonDecode(detRes.body) as Map<String, dynamic>;
              final loc = detData['location'] as Map<String, dynamic>?;
              final lat = (loc?['latitude'] as num?)?.toDouble();
              final lon = (loc?['longitude'] as num?)?.toDouble();

              if (lat != null && lon != null) {
                // Strictly inside Greater Nagpur metropolitan bounds
                if (lat >= 20.65 && lat <= 21.65 && lon >= 78.40 && lon <= 79.70) {
                  final name = p['structuredFormat']?['mainText']?['text'] as String? ??
                      detData['displayName']?['text'] as String? ??
                      fullAddress.split(',').first.trim();
                  final subtitle = p['structuredFormat']?['secondaryText']?['text'] as String? ??
                      detData['formattedAddress'] as String? ??
                      'Nagpur, Maharashtra';
                  final rawTypes = (detData['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
                      (p['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
                      [];
                  final category = _getCategoryFromGoogleTypes(rawTypes);

                  return NagpurPOI(
                    id: 'google_$placeId',
                    name: name,
                    subtitle: subtitle,
                    category: category,
                    lat: lat,
                    lon: lon,
                    kind: 'online',
                    keywords: [name.toLowerCase()],
                  );
                }
              }
            }
          }

          // Method 2: Google Geocoding fallback
          final geoUrl = !placeId.startsWith('E')
              ? 'https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=$apiKey'
              : 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(fullAddress)}&bounds=20.70,78.60|21.45,79.45&components=country:IN&key=$apiKey';

          final geoRes = await http.get(Uri.parse(geoUrl)).timeout(const Duration(seconds: 3));
          if (geoRes.statusCode == 200) {
            final geoData = jsonDecode(geoRes.body) as Map<String, dynamic>;
            final results = geoData['results'] as List<dynamic>?;
            if (results != null && results.isNotEmpty) {
              final first = results.first as Map<String, dynamic>;
              final geom = first['geometry'] as Map<String, dynamic>?;
              final loc = geom?['location'] as Map<String, dynamic>?;
              final lat = (loc?['lat'] as num?)?.toDouble();
              final lon = (loc?['lng'] as num?)?.toDouble();

              if (lat != null && lon != null) {
                if (lat >= 20.65 && lat <= 21.65 && lon >= 78.40 && lon <= 79.70) {
                  final name = p['structuredFormat']?['mainText']?['text'] as String? ??
                      fullAddress.split(',').first.trim();
                  final subtitle = p['structuredFormat']?['secondaryText']?['text'] as String? ??
                      first['formatted_address'] as String? ??
                      'Nagpur, Maharashtra';
                  final rawTypes = (first['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                  final category = _getCategoryFromGoogleTypes(rawTypes);

                  return NagpurPOI(
                    id: 'google_${placeId.isNotEmpty ? placeId : fullAddress}',
                    name: name,
                    subtitle: subtitle,
                    category: category,
                    lat: lat,
                    lon: lon,
                    kind: 'online',
                    keywords: [name.toLowerCase()],
                  );
                }
              }
            }
          }
          return null;
        } catch (_) {
          return null;
        }
      });

      final results = await Future.wait(futures);
      return results.whereType<NagpurPOI>().toList();
    } catch (e) {
      debugPrint('Google Places API error: $e');
      return [];
    }
  }

  // ── OpenStreetMap Nominatim Fallback ─────────────────────────────
  Future<List<NagpurPOI>> _fetchNominatimPlaces(String query) async {
    final queryStr = query.toLowerCase().contains('nagpur') ? query : '$query, Nagpur';
    final searchUrl =
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(queryStr)}&viewbox=78.60,21.45,79.45,20.75&bounded=0&addressdetails=1&countrycodes=in&limit=8';

    try {
      final res = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'EcoMoveNagpurApp/1.0',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as List<dynamic>?;
      if (data == null) return [];

      final results = <NagpurPOI>[];
      for (final item in data) {
        final lat = double.tryParse(item['lat']?.toString() ?? '');
        final lon = double.tryParse(item['lon']?.toString() ?? '');
        if (lat == null || lon == null) continue;
        if (lat < 20.65 || lat > 21.65 || lon < 78.4 || lon > 79.7) continue;

        final addr = (item['address'] as Map<String, dynamic>?) ?? {};
        final placeName = item['name'] as String? ??
            addr['shop'] as String? ??
            addr['amenity'] as String? ??
            addr['office'] as String? ??
            addr['building'] as String? ??
            (item['display_name'] as String? ?? query).split(',').first.trim();

        final subParts = [
          addr['road'] as String?,
          (addr['suburb'] ?? addr['neighbourhood'] ?? addr['residential']) as String?,
          (addr['city'] ?? 'Nagpur') as String?,
        ].where((x) => x != null && x.isNotEmpty && x != placeName).toSet().toList();

        final subtitle = subParts.isNotEmpty ? subParts.join(', ') : 'Nagpur, Maharashtra';

        results.add(NagpurPOI(
          id: 'nominatim_${item['place_id']}',
          name: placeName,
          subtitle: subtitle,
          category: 'Place',
          lat: lat,
          lon: lon,
          kind: 'online',
          keywords: [placeName.toLowerCase()],
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // ── Photon Geocoder Fallback ────────────────────────────────────
  Future<List<NagpurPOI>> _fetchPhotonPlaces(String query) async {
    final queryStr = query.toLowerCase().contains('nagpur') ? query : '$query Nagpur';
    final searchUrl =
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(queryStr)}&lat=21.1458&lon=79.0882&limit=8';

    try {
      final res = await http.get(Uri.parse(searchUrl)).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];

      final results = <NagpurPOI>[];
      for (final f in features) {
        final geom = f['geometry'] as Map<String, dynamic>? ?? {};
        final coords = geom['coordinates'] as List<dynamic>? ?? [0, 0];
        if (coords.length < 2) continue;
        final lon = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        if (lat < 20.65 || lat > 21.65 || lon < 78.4 || lon > 79.7) continue;

        final props = f['properties'] as Map<String, dynamic>? ?? {};
        final name = props['name'] as String? ?? props['street'] as String? ?? query;
        final parts = [
          props['street'] as String?,
          props['locality'] as String?,
          (props['city'] ?? 'Nagpur') as String?,
        ].where((x) => x != null && x.isNotEmpty && x != name).toSet().toList();

        final subtitle = parts.isNotEmpty ? parts.join(', ') : 'Nagpur, Maharashtra';

        results.add(NagpurPOI(
          id: 'photon_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}',
          name: name,
          subtitle: subtitle,
          category: 'Locality',
          lat: lat,
          lon: lon,
          kind: 'online',
          keywords: [name.toLowerCase()],
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // ── Unified Search Pipeline (Matching placesSearch.ts) ───────────
  Future<List<NagpurPOI>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return curatedPlaces.take(8).toList();

    // 1. Fast Local Transit & Curated POIs Search
    final localResults = searchLocalPlaces(cleanQuery);

    // If query is coordinates, return immediately
    if (parseCoordinateInput(cleanQuery) != null) {
      return localResults;
    }

    // 2. Check In-Memory Cache
    final cacheKey = cleanQuery.toLowerCase();
    if (_onlineCache.containsKey(cacheKey)) {
      final cached = _onlineCache[cacheKey]!;
      return _deduplicatePlaces([...localResults, ...cached]);
    }

    // 3. Online Search with Google Places API + Geocoders
    List<NagpurPOI> onlineResults = [];
    try {
      final googleResults = await _fetchGooglePlaces(cleanQuery);
      if (googleResults.isNotEmpty) {
        onlineResults = googleResults;
      } else {
        // Fallback: Parallel OSM Nominatim + Photon
        final fallbackResponses = await Future.wait([
          _fetchNominatimPlaces(cleanQuery),
          _fetchPhotonPlaces(cleanQuery),
        ]);
        onlineResults = [...fallbackResponses[0], ...fallbackResponses[1]];
      }
    } catch (e) {
      debugPrint('Places search online error: $e');
    }

    // Update Cache (max 120 items)
    if (_onlineCache.length >= 120) {
      _onlineCache.remove(_onlineCache.keys.first);
    }
    _onlineCache[cacheKey] = onlineResults;

    // Combine local + online with deduplication
    return _deduplicatePlaces([...localResults, ...onlineResults]);
  }

  List<NagpurPOI> _deduplicatePlaces(List<NagpurPOI> list) {
    final seen = <String>{};
    final result = <NagpurPOI>[];
    for (final p in list) {
      final key = '${p.name.toLowerCase()}_${p.lat.toStringAsFixed(3)}_${p.lon.toStringAsFixed(3)}';
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(p);
      }
    }
    return result;
  }

  /// Filter curated places by category
  List<NagpurPOI> getPlacesByCategory(String category) {
    if (category.toLowerCase() == 'all') return curatedPlaces;
    return curatedPlaces
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}
