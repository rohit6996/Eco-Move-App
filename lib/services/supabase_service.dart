import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => _initialized ? client.auth.currentUser : null;
  bool get isAuthenticated => currentUser != null;

  /// Initialize Supabase Flutter SDK with live FYP project credentials
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(
        url: BackendConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: BackendConfig.supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('🟢 [SupabaseService] Initialized successfully with ${BackendConfig.supabaseUrl}');
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] Initialization error/warning: $e');
    }
  }

  // ── Authentication ───────────────────────────────────────────
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName ?? 'Nagpur Commuter'},
    );
    if (res.user != null) {
      await _upsertUserProfile(
        userId: res.user!.id,
        fullName: fullName ?? 'Nagpur Commuter',
        email: email,
      );
    }
    return res;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ── User Profile ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> _upsertUserProfile({
    required String userId,
    required String fullName,
    String? email,
    String? phone,
  }) async {
    try {
      await client.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'preferred_mode': 'fastest',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error upserting profile: $e');
    }
  }

  // ── Eco Stats & Carbon Wallet (user_eco_rewards) ──────────────
  Future<Map<String, dynamic>?> fetchEcoStats(String userId) async {
    try {
      final res = await client
          .from('user_eco_rewards')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Error fetching eco stats: $e');
      return null;
    }
  }

  Future<void> recordGreenTrip({
    required String userId,
    required double co2SavedKg,
  }) async {
    try {
      final existing = await fetchEcoStats(userId);
      final currentCo2 = (existing?['total_co2_saved_kg'] as num?)?.toDouble() ?? 0.0;
      final currentTrips = (existing?['green_trips_count'] as num?)?.toInt() ?? 0;

      await client.from('user_eco_rewards').upsert({
        'user_id': userId,
        'total_co2_saved_kg': currentCo2 + co2SavedKg,
        'green_trips_count': currentTrips + 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error recording green trip: $e');
    }
  }

  // ── Digital Tickets & Passes (user_tickets) ───────────────────
  Future<List<Map<String, dynamic>>> fetchUserTickets(String userId) async {
    try {
      final res = await client
          .from('user_tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
      return [];
    }
  }

  Future<void> saveIssuedTicket(Map<String, dynamic> ticketData) async {
    try {
      await client.from('user_tickets').insert(ticketData);
    } catch (e) {
      debugPrint('Error saving ticket to Supabase: $e');
    }
  }

  // ── Saved & Recent Journeys ──────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchSavedJourneys(String userId) async {
    try {
      final res = await client
          .from('saved_journeys')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching saved journeys: $e');
      return [];
    }
  }

  Future<void> saveJourney(Map<String, dynamic> journeyData) async {
    try {
      await client.from('saved_journeys').insert(journeyData);
    } catch (e) {
      debugPrint('Error saving journey: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecentJourneys(String userId) async {
    try {
      final res = await client
          .from('recent_journeys')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching recent journeys: $e');
      return [];
    }
  }
}
