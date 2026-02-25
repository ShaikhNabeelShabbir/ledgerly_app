import 'package:flutter/material.dart';
import 'package:ledgerly_app/theme/app_theme.dart';
import 'package:ledgerly_app/models/party.dart';
import 'package:ledgerly_app/models/transaction.dart' as models;
import 'package:ledgerly_app/constants/enums.dart';
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
  late Stream<List<models.Transaction>> _transactionsStream;
  Map<String, Party> _partiesMap = {};

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

  Color _txColor(TransactionType type) {
    switch (type) {
      case TransactionType.got:
        return AppColors.success;
      case TransactionType.gave:
        return AppColors.danger;
      case TransactionType.toReceive:
      case TransactionType.toGive:
        return Colors.orange;
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
      body: StreamBuilder<List<models.Transaction>>(
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
              final party = _partiesMap[tx.partyId];
              final partyName = party?.name ?? 'Unknown Party';
              final avatarText = party?.avatarText ?? '?';
              final txColor = _txColor(tx.transactionType);

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
                                Text('${tx.amountPrefix}\$${NumberFormat("#,##0").format(tx.amount)}', style: TextStyle(color: txColor, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(tx.displayTitle, style: const TextStyle(color: AppColors.slate500, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                Text(DateFormat('MMM dd, hh:mm a').format(tx.createdAt), style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                              ],
                            ),
                            if (tx.paymentMode != PaymentMode.none) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Via ${tx.paymentMode.value}', style: const TextStyle(color: AppColors.success, fontSize: 8, fontWeight: FontWeight.bold)),
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
