import 'package:flutter/material.dart';
import 'package:ledgerly_app/theme/app_theme.dart';
import 'package:ledgerly_app/services/party_service.dart';
import 'package:ledgerly_app/services/transaction_service.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _partyService = PartyService();
  final _transactionService = TransactionService();
  late Stream<List<Map<String, dynamic>>> _transactionsStream;
  Map<String, Map<String, dynamic>> _partiesMap = {};

  @override
  void initState() {
    super.initState();
    _fetchParties();
    _transactionsStream = _transactionService.watchAllTransactions();
  }

  Future<void> _fetchParties() async {
    try {
      final map = await _partyService.getPartiesMap();
      if (mounted) {
        setState(() {
          _partiesMap = map;
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
              final type = tx['transaction_type'] as String;
              final partyId = tx['party_id'] as String;
              final partyData = _partiesMap[partyId] ?? {};

              final partyName = partyData['name'] ?? 'Unknown Party';
              final avatarText = partyData['avatar_text'] ?? '?';

              String defaultDesc = type;
              String amountPrefix = '';
              Color txColor = AppColors.slate500;

              if (type == 'Got') {
                defaultDesc = 'Received Amount';
                amountPrefix = '+';
                txColor = AppColors.success;
              } else if (type == 'Gave') {
                defaultDesc = 'Given Amount';
                amountPrefix = '-';
                txColor = AppColors.danger;
              } else if (type == 'To Receive') {
                defaultDesc = 'Amount to be Received';
                amountPrefix = '+';
                txColor = Colors.orange;
              } else if (type == 'To Give') {
                defaultDesc = 'Amount to be Given';
                amountPrefix = '-';
                txColor = Colors.orange;
              }

              final description = tx['description']?.isEmpty ?? true
                  ? defaultDesc
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
                                Text('$amountPrefix\$${NumberFormat("#,##0").format(tx['amount'])}', style: TextStyle(color: txColor, fontWeight: FontWeight.bold, fontSize: 16)),
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
