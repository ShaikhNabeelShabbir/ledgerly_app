import 'package:flutter/material.dart';
import 'package:ledgerly_app/theme/app_theme.dart';
import 'package:ledgerly_app/screens/party_ledger_screen.dart';
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
              final status = p['status'] as String? ?? 'Unpaid';
              final type = p['party_type'] as String? ?? 'Customer';

              if (status == 'Unpaid' || status == 'Overdue') {
                if (type == 'Customer') {
                  receivable += amount;
                } else {
                  payable += amount;
                }
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
                              GestureDetector(
                                onTap: () => _updateBusinessName(context, businessName),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Text(businessName, style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.edit, size: 14, color: AppColors.slate500),
                                      ],
                                    ),
                                    Text(DateFormat('MMM dd, yyyy').format(DateTime.now()), style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                                  ],
                                ),
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
                          _buildSummaryCard(context, Icons.payments, 'Cash in Hand', '\$${NumberFormat("#,##0").format(cashInHand)}', onTap: () => _updateBalance(context, 'cash_in_hand', cashInHand), isEditable: true),
                          const SizedBox(width: 16),
                          _buildSummaryCard(context, Icons.account_balance, 'Bank Balance', '\$${NumberFormat("#,##0").format(bankBalance)}', onTap: () => _updateBalance(context, 'bank_balance', bankBalance), isEditable: true),
                          const SizedBox(width: 16),
                          _buildSummaryCard(context, Icons.call_received, 'Receivable', '\$${NumberFormat("#,##0").format(receivable)}', onTap: () => setState(() => _isCustomerTab = true)),
                          const SizedBox(width: 16),
                          _buildSummaryCard(context, Icons.call_made, 'Payable', '\$${NumberFormat("#,##0").format(payable)}', onTap: () => setState(() => _isCustomerTab = false)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Net Position Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(right: -40, bottom: -40, child: Container(width: 160, height: 160, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
                            Positioned(left: -40, top: -40, child: Container(width: 120, height: 120, decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle))),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('OVERALL HEALTH', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                        const SizedBox(height: 4),
                                        const Text('Net Position', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.trending_up, color: AppColors.success, size: 16),
                                          const SizedBox(width: 4),
                                          Text('\$${NumberFormat("#,##0").format(netPosition)}', style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
                    _buildNavItem(Icons.receipt_long, 'Transactions'),
                    _buildNavItem(Icons.assessment, 'Reports'),
                    _buildNavItem(Icons.settings, 'Settings'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateBusinessName(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Update Business Name'),
      content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await Supabase.instance.client.from('profiles').update({'business_name': controller.text}).eq('id', _userId!);
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    ));
  }

  Future<void> _updateBalance(BuildContext context, String field, double currentAmount) async {
    final controller = TextEditingController(text: currentAmount.toString());
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text('Update ${field.replaceAll('_', ' ').toUpperCase()}'),
      content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          final val = double.tryParse(controller.text) ?? 0.0;
          await Supabase.instance.client.from('profiles').update({field: val}).eq('id', _userId!);
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    ));
  }

  Future<void> _showAddPartyDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 7));
    String selectedStatus = 'Unpaid';
    final List<String> statusOptions = ['Paid', 'Unpaid', 'Overdue'];
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
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
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
                      const Text('Status: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedStatus,
                        items: statusOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedStatus = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (name.isNotEmpty) {
                      try {
                        final userId = Supabase.instance.client.auth.currentUser!.id;
                        await Supabase.instance.client.from('parties').insert({
                          'user_id': userId,
                          'name': name,
                          'amount': amount,
                          'avatar_text': name.substring(0, 2).toUpperCase(),
                          'status': selectedStatus,
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
    // Determine colors/status logic
    Color statusColor;
    bool isOverdue = false;
    
    switch (party.status) {
      case 'Paid':
        statusColor = AppColors.success;
        break;
      case 'Overdue':
        statusColor = AppColors.danger;
        isOverdue = true;
        break;
      case 'Unpaid':
      default:
        statusColor = AppColors.warning;
        break;
    }

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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(party.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPartyDialog(BuildContext context, Party party) async {
    final nameController = TextEditingController(text: party.name);
    final amountController = TextEditingController(text: party.amount.toString());
    DateTime? selectedDate = party.dueDate;
    String selectedStatus = party.status;
    String selectedPartyType = party.partyType ?? 'Customer';
    final List<String> statusOptions = ['Paid', 'Unpaid', 'Overdue'];

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
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
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
                      const Text('Status: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedStatus,
                        items: statusOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedStatus = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (name.isNotEmpty) {
                      try {
                        await Supabase.instance.client.from('parties').update({
                          'name': name,
                          'amount': amount,
                          'avatar_text': name.substring(0, 2).toUpperCase(),
                          'status': selectedStatus,
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

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? AppColors.primary : AppColors.slate500), 
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? AppColors.primary : AppColors.slate500)),
      ],
    );
  }
}
