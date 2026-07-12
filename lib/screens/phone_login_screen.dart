import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/whatsapp_service.dart';
import '../utils/constants.dart';
import '../widgets/big_button.dart';
import 'otp_verify_screen.dart';

/// First screen for a brand-new device: enter phone number to receive an
/// OTP code via SMS. This is the SaaS account identity - separate from the
/// local app-lock PIN used on the device day-to-day.
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _sending = false;
  String? _error;

  Future<void> _sendOtp() async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = "Apna phone number likhein.");
      return;
    }
    final phone = WhatsAppService.normalizePhone(raw);

    setState(() {
      _sending = true;
      _error = null;
    });

    await _authService.sendOtp(
      phone: phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _sending = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerifyScreen(verificationId: verificationId, phone: phone),
          ),
        );
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = message;
        });
      },
      onAutoVerified: (credential) {
        // Some Android devices auto-detect the SMS in the background.
        // We keep the flow simple by still letting the user go through
        // the OTP screen if this doesn't resolve before they get there.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  ),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.primaryGreen, size: 46),
                ),
                const SizedBox(height: 20),
                const Text(
                  "KhataBook WhatsApp",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Apna account banayein ya login karein",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
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
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(hintText: "+92 3xx xxxxxxx"),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13), textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 18),
                      _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            )
                          : BigButton(label: "OTP Bhejein", icon: Icons.sms_outlined, onTap: _sendOtp),
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
