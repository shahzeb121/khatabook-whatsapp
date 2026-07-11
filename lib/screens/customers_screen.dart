import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/app_data_provider.dart';
import '../utils/constants.dart';
import '../widgets/balance_text.dart';
import 'ledger_screen.dart';
import 'create_invoice_screen.dart';
import 'customer_form_sheet.dart';

/// Customers tab content (no own Scaffold/AppBar/FAB - lives inside
/// MainShell, which supplies the "Naya Customer" FAB for this tab).
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final allCustomers = provider.customers;
    final filtered = _query.isEmpty
        ? allCustomers
        : allCustomers
            .where((c) =>
                c.name.toLowerCase().contains(_query.toLowerCase()) ||
                c.phone.contains(_query))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: "Naam ya number search karein...",
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "Koi customer nahi mila.\n'+' button se naya customer add karein.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    final balance = provider.balanceForCustomer(customer.id);
                    return _CustomerTile(customer: customer, balance: balance);
                  },
                ),
        ),
      ],
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final int balance;

  const _CustomerTile({required this.customer, required this.balance});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: AppColors.lightGreen,
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : "?",
          style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(customer.phone, style: const TextStyle(fontSize: 14)),
      onLongPress: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => CustomerFormSheet(existing: customer),
      ),
      trailing: SizedBox(
        width: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            BalanceText(balance: balance, fontSize: 14),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.receipt_long, color: AppColors.primaryGreen),
              tooltip: "Invoice",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateInvoiceScreen(preselectedCustomerId: customer.id),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.menu_book, color: AppColors.darkGreen),
              tooltip: "Ledger",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LedgerScreen(customerId: customer.id)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

