import 'package:supabase_flutter/supabase_flutter.dart';

class PartyService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Streams all parties for the current user, ordered by creation date (newest first).
  Stream<List<Map<String, dynamic>>> watchParties() {
    return _client
        .from('parties')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Streams a single party by its ID for real-time updates.
  Stream<List<Map<String, dynamic>>> watchParty(String partyId) {
    return _client
        .from('parties')
        .stream(primaryKey: ['id'])
        .eq('id', partyId);
  }

  /// Fetches all parties as a map of {partyId: partyData} for quick lookups.
  Future<Map<String, Map<String, dynamic>>> getPartiesMap() async {
    final data = await _client.from('parties').select('id, name, avatar_text');
    final map = <String, Map<String, dynamic>>{};
    for (var party in data) {
      map[party['id']] = party;
    }
    return map;
  }

  /// Adds a new party for the current user.
  Future<void> addParty({
    required String name,
    required String partyType,
    DateTime? dueDate,
  }) {
    return _client.from('parties').insert({
      'user_id': _userId,
      'name': name,
      'amount': 0.0,
      'avatar_text': name.substring(0, 2).toUpperCase(),
      'party_type': partyType,
      'due_date': dueDate?.toIso8601String(),
    });
  }

  /// Updates an existing party's details.
  Future<void> updateParty({
    required String partyId,
    required String name,
    required String partyType,
    DateTime? dueDate,
  }) {
    return _client.from('parties').update({
      'name': name,
      'avatar_text': name.substring(0, 2).toUpperCase(),
      'party_type': partyType,
      'due_date': dueDate?.toIso8601String(),
    }).eq('id', partyId);
  }

  /// Deletes a party by its ID.
  Future<void> deleteParty(String partyId) {
    return _client.from('parties').delete().eq('id', partyId);
  }
}
