import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data_provider.dart';
import '../services/whatsapp_service.dart';
import '../utils/constants.dart';
import '../widgets/balance_text.dart';

/// "Sab Ko Reminder" screen (full page - used when pushed from Home/Drawer).
/// NOTE: Since we're not using WhatsApp Business API, WhatsApp does not allow
/// a 3rd-party app to silently auto-send messages to many contacts at once.
/// So this screen lists everyone with dues and lets the shop owner tap each
/// one to open their WhatsApp chat directly with the reminder pre-typed -
/// owner just taps WhatsApp's own Send button.
class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sab Ko Reminder")),
      body: const ReminderScreenBody(),
    );
  }
}

/// Body-only version (no Scaffold/AppBar) - reused as the "Reminders" tab
/// inside MainShell, which supplies its own shared AppBar.
class ReminderScreenBody extends StatelessWidget {
  const ReminderScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final duesCustomers = provider.customersWithDues();
    final shopName = provider.shopSettings.shopName;

    if (duesCustomers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Kisi ka bhi Lena Hai nahi hai. 🎉",
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.lightGreen,
          padding: const EdgeInsets.all(14),
          child: Text(
            "${duesCustomers.length} customers ka Lena Hai baqi hai.\nHar ek ko WhatsApp par reminder bhejein.",
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: duesCustomers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final customer = duesCustomers[index];
              final balance = provider.balanceForCustomer(customer.id);
              return ListTile(
                title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(customer.phone),
                trailing: SizedBox(
                  width: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      BalanceText(balance: balance, fontSize: 14),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.chat, color: AppColors.accent),
                        tooltip: "Reminder Bhejein",
                        onPressed: () async {
                          final message = WhatsAppService.reminderMessage(
                            customerName: customer.name,
                            shopName: shopName,
                            totalBaqi: balance,
                          );
                          final sent = await WhatsAppService.sendTextDirectToChat(
                            phone: customer.phone,
                            message: message,
                          );
                          if (!sent && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("WhatsApp open nahi ho saka.")),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
