import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../models/shop_settings.dart';
import '../providers/app_data_provider.dart';
import '../utils/constants.dart';
import '../widgets/big_button.dart';
import 'login_screen.dart';

/// Settings tab content - shop details (name, phone, address, payment
/// numbers, logo) that get printed on Invoice/Ledger PDFs. Also has
/// Change PIN and Logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _easypaisaCtrl;
  late TextEditingController _jazzcashCtrl;
  String? _logoPath;
  bool _loaded = false;

  void _loadFromSettings(ShopSettings s) {
    _nameCtrl = TextEditingController(text: s.shopName);
    _phoneCtrl = TextEditingController(text: s.phone);
    _addressCtrl = TextEditingController(text: s.address);
    _easypaisaCtrl = TextEditingController(text: s.easypaisaNumber);
    _jazzcashCtrl = TextEditingController(text: s.jazzcashNumber);
    _logoPath = s.logoPath;
    _loaded = true;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _logoPath = image.path);
  }

  Future<void> _save(BuildContext context) async {
    final provider = context.read<AppDataProvider>();
    final settings = provider.shopSettings;
    settings.shopName = _nameCtrl.text.trim().isEmpty ? "Meri Dukaan" : _nameCtrl.text.trim();
    settings.phone = _phoneCtrl.text.trim();
    settings.address = _addressCtrl.text.trim();
    settings.easypaisaNumber = _easypaisaCtrl.text.trim();
    settings.jazzcashNumber = _jazzcashCtrl.text.trim();
    settings.logoPath = _logoPath;
    await provider.saveShopSettings(settings);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings save ho gayi.")),
      );
    }
  }

  Future<void> _changePin(BuildContext context) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Naya PIN"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(labelText: "Naya 4-digit PIN"),
            ),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(labelText: "PIN dubara likhein"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().length == 4 && controller.text.trim() == confirmController.text.trim()) {
                dialogContext.read<AppDataProvider>().setPin(controller.text.trim());
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("PIN update ho gaya.")),
                );
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text("PIN match nahi hua.")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    if (!_loaded) _loadFromSettings(provider.shopSettings);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Shop Ki Tafseel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          "Yeh tafseel har Invoice aur Ledger PDF ke neeche print hogi.",
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _pickLogo,
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _logoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(File(_logoPath!), fit: BoxFit.cover),
                        )
                      : const Icon(Icons.storefront, color: AppColors.primaryGreen, size: 40),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: TextButton(onPressed: _pickLogo, child: const Text("Logo Upload Karein")),
        ),
        const SizedBox(height: 12),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Shop Ka Naam")),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: "Phone Number"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressCtrl,
          maxLines: 2,
          decoration: const InputDecoration(labelText: "Address"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _easypaisaCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: "Easypaisa Number"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _jazzcashCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: "JazzCash Number"),
        ),
        const SizedBox(height: 20),
        BigButton(label: "Settings Save Karein", icon: Icons.save_outlined, onTap: () => _save(context)),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 12),
        const Text("Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(backgroundColor: AppColors.lightGreen, child: Icon(Icons.lock_outline, color: AppColors.primaryGreen)),
          title: const Text("PIN Change Karein"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _changePin(context),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(backgroundColor: AppColors.lightGreen, child: Icon(Icons.logout, color: AppColors.danger)),
          title: const Text("Logout"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.read<AppDataProvider>().logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
