import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ledgerly_app/models/transaction.dart' as models;
import 'package:ledgerly_app/constants/enums.dart';

class TransactionService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Streams all transactions for the current user, ordered by creation date (newest first).
  Stream<List<models.Transaction>> watchAllTransactions() {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => models.Transaction.fromJson(json)).toList());
  }

  /// Streams transactions for a specific party, ordered by creation date (newest first).
  Stream<List<models.Transaction>> watchTransactionsForParty(String partyId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('party_id', partyId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => models.Transaction.fromJson(json)).toList());
  }

  /// Adds a new transaction for a party.
  Future<void> addTransaction({
    required String partyId,
    required double amount,
    required TransactionType transactionType,
    String description = '',
    PaymentMode paymentMode = PaymentMode.none,
  }) {
    return _client.from('transactions').insert({
      'user_id': _userId,
      'party_id': partyId,
      'amount': amount,
      'description': description,
      'transaction_type': transactionType.value,
      'payment_mode': paymentMode.value,
    });
  }
}
