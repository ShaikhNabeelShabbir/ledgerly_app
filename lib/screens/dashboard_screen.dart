import 'package:flutter/material.dart';
import 'package:ledgerly_app/theme/app_theme.dart';
import 'package:ledgerly_app/screens/party_ledger_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ledgerly_app/models/party.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Custom Header part of body or AppBar? Design has it sticky.
      // AppBar is sticky by default.
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
                          Text('Global Traders', style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Oct 24, 2023', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
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
                            Text('ONLINE', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
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
            // Horizontal Scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildSummaryCard(context, Icons.payments, 'Cash in Hand', '\$12,450'),
                  const SizedBox(width: 16),
                  _buildSummaryCard(context, Icons.account_balance, 'Bank Balance', '\$45,200'),
                  const SizedBox(width: 16),
                  _buildSummaryCard(context, Icons.call_received, 'Receivable', '\$8,900'),
                  const SizedBox(width: 16),
                  _buildSummaryCard(context, Icons.call_made, 'Payable', '\$3,400'),
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
                    // Background decorations
                    Positioned(
                      right: -40,
                      bottom: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                      ),
                    ),
                    Positioned(
                      left: -40,
                      top: -40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                      ),
                    ),
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
                                  const Text('+\$5,500', style: TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold)),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Outstanding Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      children: [
                        Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Tabs
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: Container(
            //     padding: const EdgeInsets.all(4),
            //     decoration: BoxDecoration(
            //       color: Colors.grey.withOpacity(0.1),
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     child: Row(
            //       children: [
            //         Expanded(
            //           child: Container(
            //             padding: const EdgeInsets.symmetric(vertical: 10),
            //             decoration: BoxDecoration(
            //               color: Theme.of(context).cardTheme.color,
            //               borderRadius: BorderRadius.circular(8),
            //               boxShadow: [
            //                 BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
            //               ],
            //             ),
            //             child: Center(
            //               child: Text('Customers', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
            //             ),
            //           ),
            //         ),
            //         Expanded(
            //           child: Container(
            //             padding: const EdgeInsets.symmetric(vertical: 10),
            //             child: Center(
            //               child: Text('Suppliers', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.bold, fontSize: 14)),
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            const SizedBox(height: 16),
            // List Items using StreamBuilder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('parties')
                    .stream(primaryKey: ['id'])
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.waiting) {
                     return const Center(child: CircularProgressIndicator());
                   }
                   if (snapshot.hasError) {
                     return Center(child: Text('Error: ${snapshot.error}'));
                   }
                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
                     return const Center(child: Text('No parties found'));
                   }
                   final partiesData = snapshot.data!;
                   return Column(
                     children: partiesData.map((data) {
                       final party = Party.fromJson(data);
                       return Column(
                         children: [
                           _buildPartyItem(context, party),
                           const SizedBox(height: 12),
                         ],
                       );
                     }).toList(),
                   );
                },
              ),
            ),
            const SizedBox(height: 100), // Bottom padding for FAB and Nav
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60), // Add padding to float above bottom nav
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
  }

  Future<void> _showAddPartyDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 7));
    String selectedStatus = 'Unpaid';
    final List<String> statusOptions = ['Paid', 'Unpaid', 'Overdue'];

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

  Widget _buildSummaryCard(BuildContext context, IconData icon, String title, String amount) {
    return Container(
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
            children: [
              Icon(icon, size: 16, color: AppColors.slate500),
              const SizedBox(width: 8),
              Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPartyItem(BuildContext context, Party party) {
    // Determine colors/status logic
    // Using a simple logic for now based on status enum string from DB
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
        // Navigate to Party Ledger
        // In this step we just navigate, ideally passing the party object
         Navigator.pushNamed(context, '/party_ledger', arguments: party);
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Party'),
            content: Text('Are you sure you want to delete ${party.name}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  await Supabase.instance.client.from('parties').delete().eq('id', party.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
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
                Text('\$${party.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Simple formatting
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(party.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? AppColors.primary : AppColors.slate500), // active-icon uses FILL 1 in CSS, we simulate
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? AppColors.primary : AppColors.slate500)),
      ],
    );
  }
}
