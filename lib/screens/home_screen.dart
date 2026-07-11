import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data_provider.dart';
import '../utils/constants.dart';
import '../widgets/big_button.dart';
import 'create_invoice_screen.dart';
import 'add_payment_screen.dart';
import 'reminder_screen.dart';

/// Home / Dashboard tab content (no own Scaffold/AppBar - lives inside
/// MainShell which supplies the AppBar, Drawer and Bottom Navigation).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DashboardCard(
          title: "Total Lena Hai",
          amount: provider.totalLenaHai,
          icon: Icons.arrow_downward_rounded,
          color: AppColors.danger,
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          title: "Aaj Cash Aya",
          amount: provider.aajCashAya,
          icon: Icons.arrow_upward_rounded,
          color: AppColors.safe,
        ),
        const SizedBox(height: 24),
        BigButton(
          label: "Naya Invoice",
          icon: Icons.receipt_long,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          ),
        ),
        const SizedBox(height: 12),
        BigButton(
          label: "Payment Add Karein",
          icon: Icons.payments_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
          ),
          outlined: true,
        ),
        const SizedBox(height: 12),
        BigButton(
          label: "Sab Ko Reminder",
          icon: Icons.notifications_active_outlined,
          color: AppColors.accent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReminderScreen()),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: AppColors.lightGreen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people_alt, color: AppColors.primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Total Customers: ${provider.customers.length}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final int amount;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(
                    formatRs(amount),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
