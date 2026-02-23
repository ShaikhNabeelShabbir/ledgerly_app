import 'package:flutter/material.dart';
import 'package:ledgerly_app/theme/app_theme.dart';
import 'package:ledgerly_app/screens/party_ledger_screen.dart';
import 'package:ledgerly_app/screens/settings_screen.dart';
import 'package:ledgerly_app/screens/transactions_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ledgerly_app/models/party.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _userId = Supabase.instance.client.auth.currentUser?.id;
  bool _isCustomerTab = true; // Toggle for Customer/Supplier list

  @override
  void initState() {
    super.initState();
    _ensureProfileExists();
  }

  Future<void> _ensureProfileExists() async {
    if (_userId == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', _userId!)
        .maybeSingle();
    
    if (profile == null) {
      await Supabase.instance.client.from('profiles').insert({
        'id': _userId,
        'business_name': 'My Business',
        'cash_in_hand': 0,
        'bank_balance': 0,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) return const Scaffold(body: Center(child: Text('Please login')));

    return StreamBuilder<Map<String, dynamic>>(
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', _userId!)
          .map((data) => data.isNotEmpty ? data.first : {}),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final profile = profileSnapshot.data ?? {};
        final businessName = profile['business_name'] ?? 'My Business';
        final cashInHand = (profile['cash_in_hand'] as num?)?.toDouble() ?? 0.0;
        final bankBalance = (profile['bank_balance'] as num?)?.toDouble() ?? 0.0;

        // Fetch Parties Stream for calculations
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('parties')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false),
          builder: (context, partiesSnapshot) {
            final partiesData = partiesSnapshot.data ?? [];
            
            // Calculate Totals
            double receivable = 0;
            double payable = 0; // Assuming 'Supplier' type logic eventually, or just status based?
                                // For now, let's assume 'Customer' with unpaid = Receivable.
                                // If user marks as 'Supplier' in future update -> Payable.
                                // Based on previous context, user asked for tabs 'Customer'/'Supplier'.
            
            // Let's deduce type from the 'party_type' column we added.
            for (var p in partiesData) {
              final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
              final type = p['party_type'] as String? ?? 'Customer';

              if (type == 'Customer') {
                receivable += amount;
              } else {
                payable += amount;
              }
            }

            final netPosition = (cashInHand + bankBalance + receivable) - payable;

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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(businessName, style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('Today, ${DateFormat('MMM dd').format(DateTime.now())}', style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.success.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('ONLINE', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.logout, color: AppColors.slate500),
                                onPressed: () async {
                                   await Supabase.instance.client.auth.signOut();
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Summary Cards
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildSummaryCard(context, Icons.payments, 'Cash in Hand', '\$${NumberFormat("#,##0").format(cashInHand)}', onTap: () {
                          }, isEditable: true),
                          const SizedBox(width: 16),
                          _buildSummaryCard(context, Icons.account_balance, 'Bank Balance', '\$${NumberFormat("#,##0").format(bankBalance)}', onTap: () {
                          }, isEditable: true),
                          const SizedBox(width: 16),
                          _buildSummaryCard(context, Icons.call_received, 'Receivable', '\$${NumberFormat("#,##0").format(receivable)}', onTap: () => setState(() => _isCustomerTab = true)),
                          const SizedBox(width: 16),
                          _buildSummaryCard(context, Icons.call_made, 'Payable', '\$${NumberFormat("#,##0").format(payable)}', onTap: () => setState(() => _isCustomerTab = false)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Outstanding Overview
                    const SizedBox(height: 8),
                    // Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: GestureDetector(
                              onTap: () => setState(() => _isCustomerTab = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isCustomerTab ? Theme.of(context).cardTheme.color : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _isCustomerTab ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))] : [],
                                ),
                                child: Center(child: Text('Customers', style: TextStyle(color: _isCustomerTab ? AppColors.primary : AppColors.slate500, fontWeight: FontWeight.bold, fontSize: 14))),
                              ),
                            )),
                            Expanded(child: GestureDetector(
                              onTap: () => setState(() => _isCustomerTab = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isCustomerTab ? Theme.of(context).cardTheme.color : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: !_isCustomerTab ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))] : [],
                                ),
                                child: Center(child: Text('Suppliers', style: TextStyle(color: !_isCustomerTab ? AppColors.primary : AppColors.slate500, fontWeight: FontWeight.bold, fontSize: 14))),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // List Items (Filtered)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: partiesData.where((p) {
                           final type = p['party_type'] as String? ?? 'Customer';
                           return _isCustomerTab ? type == 'Customer' : type == 'Supplier';
                        }).map((data) {
                          final party = Party.fromJson(data); // Party model handles parsing
                          // Note: Party model might need to parse 'party_type' if we update it.
                          // Assuming Party model is resilient or ignores unknown fields for now.
                          return Column(
                            children: [
                              _buildPartyItem(context, party),
                              const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              floatingActionButton: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: FloatingActionButton(
                  onPressed: () => _showAddPartyDialog(context),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add, size: 32, color: Colors.white),
                ),
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
                ),
                padding: const EdgeInsets.only(bottom: 24, top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home, 'Home', isActive: true),
                    _buildNavItem(Icons.group, 'Parties'),
                    _buildNavItem(Icons.receipt_long, 'Transactions', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsScreen()));
                    }),
                    _buildNavItem(Icons.assessment, 'Reports'),
                    _buildNavItem(Icons.settings, 'Settings', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(initialProfile: profile)));
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Discarding original _updateBusinessName and _updateBalance which were here

  Future<void> _showAddPartyDialog(BuildContext context) async {
    final nameController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 7));
    String selectedPartyType = 'Customer'; // New: Party Type

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Party'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Party Name'),
                  ),
                  const SizedBox(height: 16),
DropdownButtonFormField<String>(
  value: selectedPartyType,
  decoration: const InputDecoration(
    labelText: 'Type',
    border: OutlineInputBorder(),
  ),
  items: const [
    DropdownMenuItem(
      value: 'Customer',
      child: Text('Customer'),
    ),
    DropdownMenuItem(
      value: 'Supplier',
      child: Text('Supplier'),
    ),
  ],
  onChanged: (String? newValue) {
    setState(() {
      selectedPartyType = newValue!;
    });
  },
),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Text(selectedDate == null 
                            ? 'No Date Chosen!' 
                            : 'Due: ${DateFormat('MMM dd, yyyy').format(selectedDate!)}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null && pickedDate != selectedDate) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: const Text('Choose Date'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text;
                    if (name.isNotEmpty) {
                      try {
                        final userId = Supabase.instance.client.auth.currentUser!.id;
                        await Supabase.instance.client.from('parties').insert({
                          'user_id': userId,
                          'name': name,
                          'amount': 0.0, // Amount enforced to 0 on creation
                          'avatar_text': name.substring(0, 2).toUpperCase(),
                          'party_type': selectedPartyType,
                          'due_date': selectedDate?.toIso8601String(),
                        });
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, IconData icon, String title, String amount, {VoidCallback? onTap, bool isEditable = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.slate500),
                    const SizedBox(width: 8),
                    Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate500)),
                  ],
                ),
                if (isEditable)
                  const Icon(Icons.edit, size: 12, color: AppColors.slate500),
              ],
            ),
            const SizedBox(height: 8),
            Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyItem(BuildContext context, Party party) {
    bool isOverdue = party.dueDate != null && 
        party.dueDate!.isBefore(DateTime.now()) && 
        party.amount > 0;

    final dateText = party.dueDate != null 
        ? 'Due: ${DateFormat('MMM dd').format(party.dueDate!)}'
        : 'No Due Date';

    return GestureDetector(
      onTap: () {
         Navigator.pushNamed(context, '/party_ledger', arguments: party);
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit'),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditPartyDialog(context, party);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: AppColors.danger),
                    title: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                    onTap: () async {
                      Navigator.pop(context);
                      // Confirm delete
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Party'),
                          content: Text('Delete ${party.name}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        await Supabase.instance.client.from('parties').delete().eq('id', party.id);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(party.avatarText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate500)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(party.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(dateText, style: TextStyle(fontSize: 12, color: isOverdue ? AppColors.danger : AppColors.slate500, fontWeight: isOverdue ? FontWeight.w500 : FontWeight.normal)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${NumberFormat("#,##0").format(party.amount)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPartyDialog(BuildContext context, Party party) async {
    final nameController = TextEditingController(text: party.name);
    DateTime? selectedDate = party.dueDate;
    String selectedPartyType = party.partyType ?? 'Customer';

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Party'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Party Name'),
                  ),
                  const SizedBox(height: 16),
                   Row(
                    children: [
                       const Text('Type: '), 
                       ChoiceChip(
                         label: const Text('Customer'),
                         selected: selectedPartyType == 'Customer',
                         onSelected: (bool selected) {
                           setState(() {
                             selectedPartyType = 'Customer';
                           });
                         },
                       ),
                       const SizedBox(width: 8),
                       ChoiceChip(
                         label: const Text('Supplier'),
                         selected: selectedPartyType == 'Supplier',
                         onSelected: (bool selected) {
                           setState(() {
                             selectedPartyType = 'Supplier';
                           });
                         },
                       ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Text(selectedDate == null 
                          ? 'No Date Chosen!' 
                          : 'Due: ${DateFormat('MMM dd, yyyy').format(selectedDate!)}'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null && pickedDate != selectedDate) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: const Text('Choose Date'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text;
                    if (name.isNotEmpty) {
                      try {
                        await Supabase.instance.client.from('parties').update({
                          'name': name,
                          'avatar_text': name.substring(0, 2).toUpperCase(),
                          'party_type': selectedPartyType,
                          'due_date': selectedDate?.toIso8601String(),
                        }).eq('id', party.id);
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

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppColors.primary : AppColors.slate500), 
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? AppColors.primary : AppColors.slate500)),
        ],
      ),
    );
  }
}
