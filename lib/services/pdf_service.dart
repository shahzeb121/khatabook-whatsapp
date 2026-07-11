import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/ledger_entry.dart';
import '../models/shop_settings.dart';
import '../utils/constants.dart';

class PdfService {
  static final _dateFmt = DateFormat('dd-MMM-yyyy');

  /// Builds the small shop logo widget for PDF headers, if a logo has been
  /// set in Settings. Falls back to nothing (no broken box) if unset/missing.
  static pw.Widget? _logoWidget(ShopSettings shop) {
    if (shop.logoPath == null) return null;
    final file = File(shop.logoPath!);
    if (!file.existsSync()) return null;
    final bytes = file.readAsBytesSync();
    return pw.Container(
      width: 56,
      height: 56,
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 8,
        verticalRadius: 8,
        child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
      ),
    );
  }

  /// Shop contact-details block reused at the bottom of every report.
  static pw.Widget _shopFooterBlock(ShopSettings shop) {
    final parts = <String>[];
    if (shop.phone.trim().isNotEmpty) parts.add("Phone: ${shop.phone}");
    if (shop.address.trim().isNotEmpty) parts.add(shop.address);
    final paymentParts = <String>[];
    if (shop.easypaisaNumber.trim().isNotEmpty) paymentParts.add("Easypaisa: ${shop.easypaisaNumber}");
    if (shop.jazzcashNumber.trim().isNotEmpty) paymentParts.add("JazzCash: ${shop.jazzcashNumber}");

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (parts.isNotEmpty) pw.Text(parts.join('   |   '), style: const pw.TextStyle(fontSize: 10)),
        if (paymentParts.isNotEmpty)
          pw.Text(paymentParts.join('   |   '), style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  /// Generates a simple A4 Ledger / Hisaab Kitaab PDF for a customer and
  /// saves it to the app's temp directory. Returns the saved file path.
  static Future<String> generateLedgerPdf({
    required Customer customer,
    required List<LedgerEntry> entries,
    required DateTime start,
    required DateTime end,
    required int balance,
    required ShopSettings shop,
  }) async {
    final doc = pw.Document();
    final logo = _logoWidget(shop);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Hisab Kitaab - ${shop.shopName}",
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                if (logo != null) logo,
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text("Customer: ${customer.name}   |   Phone: ${customer.phone}"),
            pw.Text(
              "Date Range: ${_dateFmt.format(start)} to ${_dateFmt.format(end)}",
            ),
            pw.Divider(thickness: 1),
          ],
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.4),
              1: const pw.FlexColumnWidth(2.4),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.4),
            },
            children: [
              _tableHeaderRow(["Date", "Details", "Debit (+)", "Credit (-)", "Balance"]),
              for (final e in entries)
                pw.TableRow(children: [
                  _cell(_dateFmt.format(e.date)),
                  _cell(e.details),
                  _cell(e.plus > 0 ? e.plus.toString() : '-'),
                  _cell(e.minus > 0 ? e.minus.toString() : '-'),
                  _cell(e.runningBalance.toString()),
                ]),
            ],
          ),
        ],
        footer: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Divider(thickness: 1),
            pw.Text(
              "Total Baqi: ${formatRs(balance)}",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            _shopFooterBlock(shop),
          ],
        ),
      ),
    );

    return _saveDoc(doc, "ledger_${customer.name}_${DateTime.now().millisecondsSinceEpoch}.pdf");
  }

  /// Generates a standard invoice PDF and saves it. Returns the file path.
  static Future<String> generateInvoicePdf({
    required Invoice invoice,
    required Customer customer,
    required ShopSettings shop,
  }) async {
    final doc = pw.Document();
    final logo = _logoWidget(shop);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header: shop name + logo (if set)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(shop.shopName,
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Invoice #${invoice.invoiceNumber}"),
                  ],
                ),
                if (logo != null)
                  logo
                else
                  pw.Container(
                    width: 56,
                    height: 56,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text("LOGO", style: const pw.TextStyle(color: PdfColors.grey500)),
                  ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Text("Customer: ${customer.name}"),
            pw.Text("Phone: ${customer.phone}"),
            pw.Text("Date: ${_dateFmt.format(invoice.date)}"),
            if (invoice.dueDate != null) pw.Text("Due Date: ${_dateFmt.format(invoice.dueDate!)}"),
            pw.Text("Status: ${invoice.isPaid ? 'Paid' : 'Credit (Udhaar)'}"),
            pw.SizedBox(height: 14),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.6),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.4),
              },
              children: [
                _tableHeaderRow(["Item", "Qty", "Price", "Total"]),
                for (final item in invoice.items)
                  pw.TableRow(children: [
                    _cell(item.name),
                    _cell(item.qty.toString()),
                    _cell(item.price.toString()),
                    _cell(item.total.toString()),
                  ]),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Subtotal: ${formatRs(invoice.subtotal)}"),
                  pw.Text("Tax (${invoice.taxPercent.toStringAsFixed(0)}%): ${formatRs(invoice.taxAmount)}"),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "Total: ${formatRs(invoice.total)}",
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Divider(),
            _shopFooterBlock(shop),
            pw.SizedBox(height: 4),
            pw.Text("Shukriya! (Thank you)", style: const pw.TextStyle(color: PdfColors.grey700)),
          ],
        ),
      ),
    );

    return _saveDoc(doc, "invoice_${invoice.invoiceNumber}_${customer.name}.pdf");
  }

  static pw.TableRow _tableHeaderRow(List<String> labels) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.green100),
      children: labels
          .map((l) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ))
          .toList(),
    );
  }

  static pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text),
    );
  }

  static Future<String> _saveDoc(pw.Document doc, String filename) async {
    final dir = await getTemporaryDirectory();
    final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(await doc.save());
    return file.path;
  }
}
