import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'customers_screen.dart';
import 'reminder_screen.dart';
import 'settings_screen.dart';
import 'create_invoice_screen.dart';
import 'add_payment_screen.dart';
import 'customer_form_sheet.dart';
import 'login_screen.dart';

/// The app's main shell after login: one AppBar (with shop logo top-left),
/// a Drawer, a Bottom Navigation Bar, and the 4 main tabs swapped via
/// IndexedStack (so each tab keeps its scroll position/state).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _titles = ["KhataBook WhatsApp", "Customers", "Reminders", "Settings"];

  final _pages = const [
    HomeScreen(),
    CustomersScreen(),
    ReminderScreenBody(),
    SettingsScreen(),
  ];

  void _go(int i) {
    setState(() => _index = i);
    Navigator.pop(context); // close drawer if open
  }

  Widget _shopLogo(BuildContext context) {
    final settings = context.watch<AppDataProvider>().shopSettings;
    if (settings.logoPath != null && File(settings.logoPath!).existsSync()) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.lightGreen,
        backgroundImage: FileImage(File(settings.logoPath!)),
      );
    }
    return const CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.lightGreen,
      child: Icon(Icons.storefront, color: AppColors.primaryGreen, size: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            padding: const EdgeInsets.all(6),
            icon: _shopLogo(context),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(_titles[_index]),
      ),
      drawer: _AppDrawer(currentIndex: _index, onSelect: _go),
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _index, children: _pages),
      ),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.person_add),
              label: const Text("Naya Customer"),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const CustomerFormSheet(),
              ),
            )
          : (_index == 0
              ? FloatingActionButton(
                  child: const Icon(Icons.receipt_long),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
                  ),
                )
              : null),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: "Customers"),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: "Reminders"),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _AppDrawer({required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final settings = provider.shopSettings;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.lightGreen,
                    backgroundImage: settings.logoPath != null && File(settings.logoPath!).existsSync()
                        ? FileImage(File(settings.logoPath!))
                        : null,
                    child: settings.logoPath == null
                        ? const Icon(Icons.storefront, color: AppColors.primaryGreen, size: 26)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.shopName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text("KhataBook WhatsApp", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _drawerTile(context, icon: Icons.home_outlined, label: "Home", index: 0),
            _drawerTile(context, icon: Icons.people_alt_outlined, label: "Customers", index: 1),
            _drawerTile(context, icon: Icons.notifications_outlined, label: "Reminders", index: 2),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: AppColors.primaryGreen),
              title: const Text("Naya Invoice"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined, color: AppColors.primaryGreen),
              title: const Text("Payment Add Karein"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPaymentScreen()));
              },
            ),
            const Divider(),
            _drawerTile(context, icon: Icons.settings_outlined, label: "Settings", index: 3),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text("Logout"),
              onTap: () {
                context.read<AppDataProvider>().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(BuildContext context, {required IconData icon, required String label, required int index}) {
    final selected = currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primaryGreen : AppColors.textMuted),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primaryGreen : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.lightGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => onSelect(index),
    );
  }
}

