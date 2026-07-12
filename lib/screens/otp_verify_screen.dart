import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data_provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/big_button.dart';
import 'login_screen.dart';
import 'pending_approval_screen.dart';

/// Enter the 6-digit SMS code, verify it with Firebase, then check whether
/// an admin has activated this account yet.
class OtpVerifyScreen extends StatefulWidget {
  final String verificationId;
  final String phone;
  const OtpVerifyScreen({super.key, required this.verificationId, required this.phone});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _verifying = false;
  String? _error;

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = "6-digit code likhein.");
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final user = await _authService.verifyOtp(verificationId: widget.verificationId, smsCode: code);
      if (user == null) {
        setState(() {
          _verifying = false;
          _error = "Verify nahi ho saka. Dubara koshish karein.";
        });
        return;
      }

      final provider = context.read<AppDataProvider>();
      final isActive = await _authService.ensureUserDocAndCheckActive(
        user,
        shopNameHint: provider.shopSettings.shopName,
      );
      await provider.setCloudActive(isActive, phone: widget.phone);

      if (!mounted) return;

      if (!isActive) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _verifying = false;
        _error = "Galat code. Dubara koshish karein.";
      });
    }
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
                const Icon(Icons.sms_outlined, color: Colors.white, size: 56),
                const SizedBox(height: 16),
                const Text(
                  "Code Verify Karein",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "${widget.phone} par SMS bheja gaya hai",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(counterText: "", hintText: "000000"),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                      ],
                      const SizedBox(height: 18),
                      _verifying
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            )
                          : BigButton(label: "Verify Karein", icon: Icons.check_circle_outline, onTap: _verify),
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
