import 'package:flutter/material.dart';
import 'package:ledgerly_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _userId = Supabase.instance.client.auth.currentUser?.id;
  late Stream<List<Map<String, dynamic>>> _transactionsStream;
  Map<String, Map<String, dynamic>> _partiesMap = {};

  @override
  void initState() {
    super.initState();
    _fetchParties();
    _transactionsStream = Supabase.instance.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);
  }

  Future<void> _fetchParties() async {
    try {
      final data = await Supabase.instance.client.from('parties').select('id, name, avatar_text');
      if (mounted) {
        setState(() {
          for (var party in data) {
            _partiesMap[party['id']] = party;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching parties: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: _fetchParties,
           )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.danger)));
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions yet.', style: TextStyle(color: AppColors.slate500)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final date = DateTime.parse(tx['created_at']);
              final isGot = tx['transaction_type'] == 'Got';
              final partyId = tx['party_id'] as String;
              final partyData = _partiesMap[partyId];
              
              final partyName = partyData != null ? partyData['name'] : 'Unknown Party';
              final avatarText = partyData != null ? partyData['avatar_text'] : '?';
              
              final description = tx['description']?.isEmpty ?? true 
                  ? (isGot ? 'Received Amount' : 'Given Amount') 
                  : tx['description'];
                  
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(avatarText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate500)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(partyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                Text('${isGot ? '+' : '-'}\$${NumberFormat("#,##0").format(tx['amount'])}', style: TextStyle(color: isGot ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(description, style: const TextStyle(color: AppColors.slate500, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                Text(DateFormat('MMM dd, hh:mm a').format(date), style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                              ],
                            ),
                            if (tx['payment_mode'] != 'None') ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Via ${tx['payment_mode']}', style: const TextStyle(color: AppColors.success, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
