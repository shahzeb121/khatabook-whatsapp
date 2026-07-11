import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_data_provider.dart';
import '../services/pdf_service.dart';
import '../services/whatsapp_service.dart';
import '../utils/constants.dart';
import 'add_payment_screen.dart';

class LedgerScreen extends StatelessWidget {
  final String customerId;
  const LedgerScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final customer = provider.customerById(customerId);
    if (customer == null) {
      return const Scaffold(body: Center(child: Text("Customer nahi mila.")));
    }
    final entries = provider.ledgerForCustomer(customerId);
    final balance = provider.balanceForCustomer(customerId);
    final dateFmt = DateFormat('dd-MMM');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${customer.name}  |  ${formatRs(balance)} Lena Hai",
          style: const TextStyle(fontSize: 17),
        ),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Abhi tak koi hisaab nahi hai.\nInvoice ya Payment add karein.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  color: AppColors.lightGreen,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Row(
                    children: [
                      _HeaderCell("Date", flex: 2),
                      _HeaderCell("Details", flex: 4),
                      _HeaderCell("+", flex: 2),
                      _HeaderCell("-", flex: 2),
                      _HeaderCell("Balance", flex: 3),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = entries[entries.length - 1 - index]; // newest first
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(dateFmt.format(e.date), style: const TextStyle(fontSize: 13))),
                            Expanded(flex: 4, child: Text(e.details, style: const TextStyle(fontSize: 14))),
                            Expanded(
                              flex: 2,
                              child: Text(
                                e.plus > 0 ? e.plus.toString() : '-',
                                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                e.minus > 0 ? e.minus.toString() : '-',
                                style: const TextStyle(color: AppColors.safe, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                formatRs(e.runningBalance),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPaymentScreen(preselectedCustomerId: customerId),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Payment"),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: entries.isEmpty
                      ? null
                      : () async {
                          final start = entries.first.date;
                          final end = entries.last.date;
                          final path = await PdfService.generateLedgerPdf(
                            customer: customer,
                            entries: entries,
                            start: start,
                            end: end,
                            balance: balance,
                            shop: provider.shopSettings,
                          );
                          final message = WhatsAppService.ledgerMessage(
                            customerName: customer.name,
                            shopName: provider.shopSettings.shopName,
                            startStr: DateFormat('dd-MMM-yyyy').format(start),
                            endStr: DateFormat('dd-MMM-yyyy').format(end),
                            totalBaqi: balance,
                          );
                          await WhatsAppService.sharePdf(filePath: path, message: message);
                        },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text("Ledger Bhejein WhatsApp"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
