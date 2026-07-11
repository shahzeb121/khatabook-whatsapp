import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/invoice_item.dart';
import '../providers/app_data_provider.dart';
import '../services/pdf_service.dart';
import '../services/whatsapp_service.dart';
import '../utils/constants.dart';
import '../widgets/big_button.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final String? preselectedCustomerId;
  const CreateInvoiceScreen({super.key, this.preselectedCustomerId});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _ItemRow {
  final nameController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final priceController = TextEditingController();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  Customer? _selectedCustomer;
  final List<_ItemRow> _rows = [_ItemRow()];
  final _taxController = TextEditingController(text: '0');
  bool _isCredit = true; // true = Credit (Lena Hai), false = Paid
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    // Preselect customer if navigated from Customers list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preselectedCustomerId != null) {
        final provider = context.read<AppDataProvider>();
        setState(() {
          _selectedCustomer = provider.customerById(widget.preselectedCustomerId!);
        });
      }
    });
  }

  int get _subtotal {
    int total = 0;
    for (final row in _rows) {
      final qty = int.tryParse(row.qtyController.text) ?? 0;
      final price = int.tryParse(row.priceController.text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  double get _taxPercent => double.tryParse(_taxController.text) ?? 0;

  int get _taxAmount => ((_subtotal * _taxPercent) / 100).round();

  int get _total => _subtotal + _taxAmount;

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  List<InvoiceItem> _buildItems() {
    return _rows
        .where((r) => r.nameController.text.trim().isNotEmpty)
        .map((r) => InvoiceItem(
              name: r.nameController.text.trim(),
              qty: int.tryParse(r.qtyController.text) ?? 1,
              price: int.tryParse(r.priceController.text) ?? 0,
            ))
        .toList();
  }

  bool _validate() {
    if (_selectedCustomer == null) {
      _showMsg("Pehle customer select karein.");
      return false;
    }
    if (_buildItems().isEmpty) {
      _showMsg("Kam az kam ek item add karein.");
      return false;
    }
    return true;
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save({required bool andWhatsapp}) async {
    if (!_validate()) return;
    final provider = context.read<AppDataProvider>();
    final invoice = await provider.addInvoice(
      customerId: _selectedCustomer!.id,
      items: _buildItems(),
      taxPercent: _taxPercent,
      isPaid: !_isCredit,
      dueDate: _dueDate,
    );

    if (andWhatsapp) {
      final path = await PdfService.generateInvoicePdf(
        invoice: invoice,
        customer: _selectedCustomer!,
        shop: provider.shopSettings,
      );
      final message = WhatsAppService.invoiceMessage(
        customerName: _selectedCustomer!.name,
        shopName: provider.shopSettings.shopName,
        invoiceId: invoice.invoiceNumber,
        amount: invoice.total,
        dueDateStr: _dueDate != null ? DateFormat('dd-MMM-yyyy').format(_dueDate!) : "N/A",
      );
      await WhatsAppService.sharePdf(filePath: path, message: message);
    }

    if (mounted) {
      _showMsg("Invoice #${invoice.invoiceNumber} save ho gaya.");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<AppDataProvider>().customers;

    return Scaffold(
      appBar: AppBar(title: const Text("Naya Invoice")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Customer", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<Customer>(
            value: _selectedCustomer,
            hint: const Text("Customer select karein"),
            items: customers
                .map((c) => DropdownMenuItem(value: c, child: Text("${c.name} (${c.phone})")))
                .toList(),
            onChanged: (v) => setState(() => _selectedCustomer = v),
          ),
          const SizedBox(height: 20),
          const Text("Items", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (int i = 0; i < _rows.length; i++) _buildItemRow(i),
          TextButton.icon(
            onPressed: () => setState(() => _rows.add(_ItemRow())),
            icon: const Icon(Icons.add),
            label: const Text("+ Add Item"),
          ),
          const Divider(height: 30),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Tax %"),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summaryRow("Subtotal", _subtotal),
          _summaryRow("Tax", _taxAmount),
          const Divider(),
          _summaryRow("Total", _total, big: true),
          const SizedBox(height: 20),
          const Text("Payment Status", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _toggleChip(
                  label: "Credit (Lena Hai)",
                  selected: _isCredit,
                  onTap: () => setState(() => _isCredit = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _toggleChip(
                  label: "Paid",
                  selected: !_isCredit,
                  onTap: () => setState(() => _isCredit = false),
                ),
              ),
            ],
          ),
          if (_isCredit) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDueDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_dueDate == null
                  ? "Due Date select karein (optional)"
                  : "Due: ${DateFormat('dd-MMM-yyyy').format(_dueDate!)}"),
            ),
          ],
          const SizedBox(height: 28),
          BigButton(
            label: "Save",
            icon: Icons.save_outlined,
            outlined: true,
            onTap: () => _save(andWhatsapp: false),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: "Save & WhatsApp Karein",
            icon: Icons.send,
            onTap: () => _save(andWhatsapp: true),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final row = _rows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: row.nameController,
              decoration: const InputDecoration(labelText: "Item Naam"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Qty"),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price"),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_rows.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
              onPressed: () => setState(() => _rows.removeAt(index)),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, int amount, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: big ? 18 : 15, fontWeight: big ? FontWeight.bold : FontWeight.normal)),
          Text(
            formatRs(amount),
            style: TextStyle(
              fontSize: big ? 20 : 15,
              fontWeight: FontWeight.bold,
              color: big ? AppColors.primaryGreen : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : Colors.white,
          border: Border.all(color: AppColors.primaryGreen),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
