import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ledgerly_app/models/party.dart';
import 'package:ledgerly_app/constants/enums.dart';

class PartyService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Streams all parties for the current user, ordered by creation date (newest first).
  Stream<List<Party>> watchParties() {
    return _client
        .from('parties')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Party.fromJson(json)).toList());
  }

  /// Streams a single party by its ID for real-time updates.
  Stream<List<Party>> watchParty(String partyId) {
    return _client
        .from('parties')
        .stream(primaryKey: ['id'])
        .eq('id', partyId)
        .map((data) => data.map((json) => Party.fromJson(json)).toList());
  }

  /// Fetches all parties as a map of {partyId: Party} for quick lookups.
  Future<Map<String, Party>> getPartiesMap() async {
    final data = await _client.from('parties').select();
    final map = <String, Party>{};
    for (var json in data) {
      final party = Party.fromJson(json);
      map[party.id] = party;
    }
    return map;
  }

  /// Adds a new party for the current user.
  Future<void> addParty({
    required String name,
    required PartyType partyType,
    DateTime? dueDate,
  }) {
    return _client.from('parties').insert({
      'user_id': _userId,
      'name': name,
      'amount': 0.0,
      'avatar_text': name.substring(0, 2).toUpperCase(),
      'party_type': partyType.value,
      'due_date': dueDate?.toIso8601String(),
    });
  }

  /// Updates an existing party's details.
  Future<void> updateParty({
    required String partyId,
    required String name,
    required PartyType partyType,
    DateTime? dueDate,
  }) {
    return _client.from('parties').update({
      'name': name,
      'avatar_text': name.substring(0, 2).toUpperCase(),
      'party_type': partyType.value,
      'due_date': dueDate?.toIso8601String(),
    }).eq('id', partyId);
  }

  /// Deletes a party by its ID.
  Future<void> deleteParty(String partyId) {
    return _client.from('parties').delete().eq('id', partyId);
  }
}
