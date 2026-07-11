import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/payment.dart';
import '../providers/app_data_provider.dart';
import '../utils/constants.dart';
import '../widgets/big_button.dart';

class AddPaymentScreen extends StatefulWidget {
  final String? preselectedCustomerId;
  const AddPaymentScreen({super.key, this.preselectedCustomerId});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  Customer? _selectedCustomer;
  final _amountController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _date = DateTime.now();
  String? _screenshotPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preselectedCustomerId != null) {
        final provider = context.read<AppDataProvider>();
        setState(() {
          _selectedCustomer = provider.customerById(widget.preselectedCustomerId!);
        });
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _screenshotPath = image.path);
  }

  Future<void> _save() async {
    if (_selectedCustomer == null) {
      _showMsg("Pehle customer select karein.");
      return;
    }
    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      _showMsg("Sahi amount likhein.");
      return;
    }
    final provider = context.read<AppDataProvider>();
    await provider.addPayment(
      customerId: _selectedCustomer!.id,
      amount: amount,
      method: _method,
      date: _date,
      screenshotPath: _screenshotPath,
    );
    if (mounted) {
      _showMsg("Payment save ho gaya.");
      Navigator.pop(context);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<AppDataProvider>().customers;

    return Scaffold(
      appBar: AppBar(title: const Text("Payment Add Karein")),
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
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Amount (Rs.)"),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text("Date: ${DateFormat('dd-MMM-yyyy').format(_date)}"),
          ),
          const SizedBox(height: 20),
          const Text("Method", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: PaymentMethod.values.map((m) {
              final selected = _method == m;
              return ChoiceChip(
                label: Text(paymentMethodLabel(m)),
                selected: selected,
                selectedColor: AppColors.primaryGreen,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                onSelected: (_) => setState(() => _method = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text("Screenshot (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_screenshotPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(_screenshotPath!), height: 140, fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickScreenshot,
            icon: const Icon(Icons.image_outlined),
            label: Text(_screenshotPath == null ? "Screenshot Upload Karein" : "Screenshot Badlein"),
          ),
          const SizedBox(height: 28),
          BigButton(label: "Save Payment", icon: Icons.check_circle_outline, onTap: _save),
        ],
      ),
    );
  }
}
