import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../models/customer.dart';
import '../providers/app_data_provider.dart';
import '../services/whatsapp_service.dart';
import '../widgets/big_button.dart';

/// Add or edit a customer. Shown as a modal bottom sheet.
class CustomerFormSheet extends StatefulWidget {
  final Customer? existing;
  const CustomerFormSheet({super.key, this.existing});

  @override
  State<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<CustomerFormSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _phoneController.text = widget.existing!.phone;
    }
  }

  Future<void> _pickFromContacts() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contacts permission chahiye.")),
        );
      }
      return;
    }
    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
        setState(() {
          _nameController.text = contact.displayName.isNotEmpty ? contact.displayName : _nameController.text;
          _phoneController.text = WhatsAppService.normalizePhone(phone);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contact select nahi ho saka.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? "Customer Edit Karein" : "Naya Customer",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Naam"),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Naam likhein" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone Number (+92...)"),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? "Number likhein" : null,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickFromContacts,
              icon: const Icon(Icons.contacts),
              label: const Text("Contacts se select karein"),
            ),
            const SizedBox(height: 12),
            BigButton(
              label: isEdit ? "Update Karein" : "Save Karein",
              icon: Icons.check,
              onTap: () async {
                if (!_formKey.currentState!.validate()) return;
                final provider = context.read<AppDataProvider>();
                final phone = WhatsAppService.normalizePhone(_phoneController.text);
                if (isEdit) {
                  widget.existing!.name = _nameController.text.trim();
                  widget.existing!.phone = phone;
                  await provider.updateCustomer(widget.existing!);
                } else {
                  await provider.addCustomer(name: _nameController.text.trim(), phone: phone);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
