import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data_provider.dart';
import '../utils/constants.dart';
import '../widgets/big_button.dart';
import 'main_shell.dart';

/// Simple local login screen. No server / accounts involved - this just
/// protects the app with a 4-digit PIN stored on-device.
/// First run: lets the shop owner set a PIN.
/// Later runs: asks for that PIN before showing the app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  void _submit(BuildContext context, bool isSetup) {
    final provider = context.read<AppDataProvider>();
    final pin = _pinController.text.trim();

    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _error = "4 digit PIN likhein (numbers only).");
      return;
    }

    if (isSetup) {
      if (pin != _confirmController.text.trim()) {
        setState(() => _error = "PIN match nahi hua. Dubara likhein.");
        return;
      }
      provider.setPin(pin);
    } else {
      if (!provider.verifyPin(pin)) {
        setState(() => _error = "Galat PIN. Dubara koshish karein.");
        return;
      }
    }

    provider.markLoggedIn();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final isSetup = !provider.shopSettings.isPinSet;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryGreen, size: 46),
                ),
                const SizedBox(height: 20),
                const Text(
                  "KhataBook WhatsApp",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isSetup ? "Apna 4-digit PIN set karein" : "Apna PIN likhein",
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(counterText: "", hintText: "••••"),
                      ),
                      if (isSetup) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(counterText: "", hintText: "PIN dubara likhein"),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                      ],
                      const SizedBox(height: 18),
                      BigButton(
                        label: isSetup ? "PIN Set Karein" : "Login",
                        icon: Icons.lock_open_rounded,
                        onTap: () => _submit(context, isSetup),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
