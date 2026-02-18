import 'package:flutter/material.dart';
import 'package:ledgerly_app/theme/app_theme.dart';

class PartyLedgerScreen extends StatelessWidget {
  const PartyLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                          const Text('Acme Corp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const Text('Last active: 2 hours ago', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
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
                  // Summary Card
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
                            const Text('\$2,500', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
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
                                const Text('Next due: Oct 24, 2023', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('RECEIVABLE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                      const SizedBox(width: 24),
                      _buildTabItem('Details'),
                      const SizedBox(width: 24),
                      _buildTabItem('Reports'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Date Group: October 2023
                  _buildDateGroup('October 2023'),
                  const SizedBox(height: 12),
                  _buildTransactionItem(
                    context,
                    icon: Icons.receipt_long,
                    iconColor: AppColors.warning,
                    title: 'Expense: Office Supplies',
                    subtitle: 'Oct 18, 2:15 PM',
                    amount: '+\$100.00',
                    balance: 'Bal: \$3,300',
                    isPositive: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTransactionItem(
                    context,
                    icon: Icons.shopping_cart,
                    iconColor: Colors.blue,
                    title: 'Purchase Bill #PB-882',
                    subtitle: 'Oct 15, 11:00 AM',
                    amount: '+\$200.00',
                    balance: 'Bal: \$3,200',
                    isPositive: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTransactionItem(
                    context,
                    icon: Icons.payments, // Emerald
                    iconColor: AppColors.success,
                    title: 'Payment Received',
                    subtitle: 'Oct 12, 09:45 AM',
                    amount: '-\$500.00',
                    balance: 'Bal: \$3,000',
                    isPositive: false,
                    badge: 'SETTLED',
                  ),
                  const SizedBox(height: 24),
                   // Date Group: September 2023
                  _buildDateGroup('September 2023'),
                  const SizedBox(height: 12),
                  _buildTransactionItem(
                    context,
                    icon: Icons.description,
                    iconColor: AppColors.primary,
                    title: 'Invoice Created #INV-441',
                    subtitle: 'Sep 28, 04:30 PM',
                    amount: '+\$1,000.00',
                    balance: 'Bal: \$3,500',
                    isPositive: true,
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
                     onPressed: () {},
                     icon: const Icon(Icons.add_circle_outline),
                     label: const Text('Add Transaction'),
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
                     onPressed: () {},
                     icon: const Icon(Icons.account_balance_wallet),
                     label: const Text('Record Payment'),
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
