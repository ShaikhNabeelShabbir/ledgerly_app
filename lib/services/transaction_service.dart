import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Streams all transactions for the current user, ordered by creation date (newest first).
  Stream<List<Map<String, dynamic>>> watchAllTransactions() {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);
  }

  /// Streams transactions for a specific party, ordered by creation date (newest first).
  Stream<List<Map<String, dynamic>>> watchTransactionsForParty(String partyId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('party_id', partyId)
        .order('created_at', ascending: false);
  }

  /// Adds a new transaction for a party.
  Future<void> addTransaction({
    required String partyId,
    required double amount,
    required String transactionType,
    String description = '',
    String paymentMode = 'None',
  }) {
    return _client.from('transactions').insert({
      'user_id': _userId,
      'party_id': partyId,
      'amount': amount,
      'description': description,
      'transaction_type': transactionType,
      'payment_mode': paymentMode,
    });
  }
}
