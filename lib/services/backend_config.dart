import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Eco-Move Nagpur Backend & API Configuration
/// Loads all private API keys and endpoints dynamically from the root .env file.
/// Safe to commit to Git as no secret keys are hardcoded in source code.
class BackendConfig {
  BackendConfig._();

  static String _get(String key, {String fallback = ''}) {
    try {
      if (dotenv.isInitialized && dotenv.env.containsKey(key) && dotenv.env[key]!.isNotEmpty) {
        return dotenv.env[key]!;
      }
    } catch (_) {}
    return String.fromEnvironment(key, defaultValue: fallback);
  }

  // 1. SUPABASE (Database, Auth, Realtime Sync & Tickets)
  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');

  // 2. N8N AI WORKFLOWS (SafarBot / AI Transit Mitra Webhook)
  static String get n8nWebhookUrl => _get('N8N_WEBHOOK_URL');
  static String get n8nTestWebhookUrl => _get('N8N_TEST_WEBHOOK_URL');

  // 3. OPENROUTESERVICE & OPENSTREETMAP ROUTING
  static String get orsApiKey => _get('ORS_API_KEY');
  static String get orsFootRoutingUrl => _get(
        'ORS_FOOT_ROUTING_URL',
        fallback: 'https://api.openrouteservice.org/v2/directions/foot-walking/geojson',
      );
  static String get osrmFootRoutingUrl => _get(
        'OSRM_FOOT_ROUTING_URL',
        fallback: 'https://router.project-osrm.org/route/v1/foot',
      );
  static String get osrmDrivingRoutingUrl => _get(
        'OSRM_DRIVING_ROUTING_URL',
        fallback: 'https://router.project-osrm.org/route/v1/driving',
      );

  // 4. GEOCODING & PLACES SEARCH (Photon & Nominatim)
  static String get photonGeocodingUrl => _get(
        'PHOTON_GEOCODING_URL',
        fallback: 'https://photon.komoot.io/api',
      );
  static String get nominatimGeocodingUrl => _get(
        'NOMINATIM_GEOCODING_URL',
        fallback: 'https://nominatim.openstreetmap.org/search',
      );

  // 5. CHALO MOBILITY LIVE TRANSIT (Nagpur Live Bus Schedules & GPS)
  static String get chaloRouteDetailsLiveApi => _get(
        'CHALO_ROUTE_DETAILS_LIVE_API',
        fallback: 'https://chalo.com/app/api/scheduler_v4/v4/nagpur/routedetailslive',
      );
  static String get chaloLiveTelemetryApi => _get(
        'CHALO_LIVE_TELEMETRY_API',
        fallback: 'https://chalo.com/app/api/vasudha/track/route-live-info/nagpur',
      );

  // 6. GOOGLE MAPS & PLACES API KEY
  static String get googleMapsApiKey => _get('GOOGLE_MAPS_API_KEY');

  // 7. CARTO MAPS API KEY
  static String get cartoApiKey => _get('CARTO_API_KEY');
}