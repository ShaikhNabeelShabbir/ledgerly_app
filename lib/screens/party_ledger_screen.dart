import 'package:flutter/material.dart';
import 'package:ledgerly_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly_app/models/party.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartyLedgerScreen extends StatefulWidget {
  const PartyLedgerScreen({super.key});

  @override
  State<PartyLedgerScreen> createState() => _PartyLedgerScreenState();
}

class _PartyLedgerScreenState extends State<PartyLedgerScreen> {
  Party? _initialParty;
  Stream<List<Map<String, dynamic>>>? _transactionsStream;
  Stream<List<Map<String, dynamic>>>? _partyStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialParty == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Party) {
        _initialParty = args;
        
        // Also stream the party itself to update real-time 'Total Outstanding' cash seamlessly
        _partyStream = Supabase.instance.client
            .from('parties')
            .stream(primaryKey: ['id'])
            .eq('id', _initialParty!.id);

        _transactionsStream = Supabase.instance.client
            .from('transactions')
            .stream(primaryKey: ['id'])
            .eq('party_id', _initialParty!.id)
            .order('created_at', ascending: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialParty == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Party data not found. Please navigate from the dashboard.')),
      );
    }
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _partyStream,
      builder: (context, partySnapshot) {
        // Fallback to initial party if stream hasn't yielded yet
        Party party = _initialParty!;
        if (partySnapshot.hasData && partySnapshot.data!.isNotEmpty) {
          party = Party.fromJson(partySnapshot.data!.first);
        }
    
    final isCustomer = party.partyType != 'Supplier';
    final amountFormatted = NumberFormat("#,##0").format(party.amount);
    
    // Determine status color
    Color statusColor;
    switch (party.status) {
      case 'Paid':
        statusColor = AppColors.success;
        break;
      case 'Overdue':
        statusColor = AppColors.danger;
        break;
      case 'Unpaid':
      default:
        statusColor = AppColors.warning;
        break;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor,
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(party.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text(isCustomer ? 'Customer' : 'Supplier', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert, color: AppColors.slate500, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                   // To ensure the balance auto-updates with Supabase trigger we should really use a StreamBuilder for the party itself,
                   // but for now, we'll show what was passed in, trusting the user returns to Dashboard to see refreshed Party overall balance
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL OUTSTANDING', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('\$$amountFormatted', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Text('USD', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(height: 1, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_repeat, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(party.dueDate != null ? 'Due: ${DateFormat('MMM dd, yyyy').format(party.dueDate!)}' : 'No Due Date', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(party.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter Tabs
                  Row(
                    children: [
                      _buildTabItem('Transactions', isActive: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<List<Map<String, dynamic>>>(
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
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No transactions yet.', style: TextStyle(color: AppColors.slate500)),
                        ));
                      }

                      return Column(
                        children: transactions.map((tx) {
                          final date = DateTime.parse(tx['created_at']);
                          final isGot = tx['transaction_type'] == 'Got';
                          
                          // Simplified: Not showing running balance in UI currently, just the tx amount.
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildTransactionItem(
                              context,
                              icon: isGot ? Icons.arrow_downward : Icons.arrow_upward,
                              iconColor: isGot ? AppColors.success : AppColors.danger,
                              title: tx['description']?.isEmpty ?? true 
                                  ? (isGot ? 'Received Amount' : 'Given Amount') 
                                  : tx['description'],
                              subtitle: '${DateFormat('MMM dd, h:mm a').format(date)} ${tx['payment_mode'] != 'None' ? '• Via ${tx['payment_mode']}' : ''}',
                              amount: '${isGot ? '+' : '-'}\$${NumberFormat("#,##0").format(tx['amount'])}',
                              balance: '', // Running balance omitted for simplicity
                              isPositive: isGot,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),


                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
          // Fixed Bottom Action Bar
          Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: Colors.white,
               border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
             ),
             child: Row(
               children: [
                 Expanded(
                   child: OutlinedButton.icon(
                     onPressed: () => _showAddTransactionDialog(context, party, 'Gave'),
                     icon: const Icon(Icons.add_circle_outline),
                     label: const Text('Gave Amount'),
                     style: OutlinedButton.styleFrom(
                       foregroundColor: AppColors.primary,
                       side: const BorderSide(color: AppColors.primary, width: 2),
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       textStyle: const TextStyle(fontWeight: FontWeight.bold),
                     ),
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: ElevatedButton.icon(
                     onPressed: () => _showAddTransactionDialog(context, party, 'Got'),
                     icon: const Icon(Icons.account_balance_wallet),
                     label: const Text('Got Amount'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       textStyle: const TextStyle(fontWeight: FontWeight.bold),
                       elevation: 0,
                     ),
                   ),
                 ),
               ],
             ),
          ),
        ],
      ),
    );
      }, // StreamBuilder for Party
    ); // StreamBuilder
  }

  Future<void> _showAddTransactionDialog(BuildContext context, Party party, String transactionType) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String paymentMode = 'None';
    final List<String> paymentModes = ['None', 'Cash', 'Bank'];

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('$transactionType Amount'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description (Optional)'),
                  ),
                  const SizedBox(height: 16),
                  if (transactionType == 'Got' || transactionType == 'Gave') // For both, we might want to track where cash went
                    Row(
                      children: [
                        const Text('Via: '),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: paymentMode,
                          items: paymentModes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              paymentMode = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (amount > 0) {
                      try {
                        final SupabaseClient supabase = Supabase.instance.client;
                        final userId = supabase.auth.currentUser!.id;
                        
                        await supabase.from('transactions').insert({
                          'user_id': userId,
                          'party_id': party.id,
                          'amount': amount,
                          'description': descriptionController.text,
                          'transaction_type': transactionType,
                          'payment_mode': paymentMode,
                        });
                        
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildTabItem(String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: isActive ? const Border(bottom: BorderSide(color: AppColors.primary, width: 2)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? AppColors.primary : AppColors.slate500,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDateGroup(String date) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        date.toUpperCase(),
        style: const TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, {required IconData icon, required Color iconColor, required String title, required String subtitle, required String amount, required String balance, required bool isPositive, String? badge}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ]
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis))),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badge, style: const TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold)),
                      )
                    ]
                  ],
                ),
                Text(subtitle, style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? AppColors.slate900 : AppColors.success)),
              Text(balance, style: const TextStyle(color: AppColors.slate500, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
