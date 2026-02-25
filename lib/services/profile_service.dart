import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ledgerly_app/models/profile.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Checks if a profile exists for the current user, creates one if not.
  Future<void> ensureProfileExists() async {
    if (_userId == null) return;

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', _userId!)
        .maybeSingle();

    if (profile == null) {
      await _client.from('profiles').insert({
        'id': _userId,
        'business_name': 'My Business',
        'cash_in_hand': 0,
        'bank_balance': 0,
      });
    }
  }

  /// Streams the current user's profile data in real-time.
  Stream<Profile> watchProfile() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', _userId!)
        .map((data) => data.isNotEmpty
            ? Profile.fromJson(data.first)
            : Profile.empty());
  }

  /// Updates the current user's profile with the given fields.
  Future<void> updateProfile({
    required String businessName,
    required double cashInHand,
    required double bankBalance,
  }) {
    return _client.from('profiles').update({
      'business_name': businessName,
      'cash_in_hand': cashInHand,
      'bank_balance': bankBalance,
    }).eq('id', _userId!);
  }
}
