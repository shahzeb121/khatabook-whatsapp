import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data_provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/big_button.dart';
import 'login_screen.dart';
import 'pending_approval_screen.dart';

/// First screen for a brand-new device: sign in with Google. This is the
/// SaaS account identity - separate from the local app-lock PIN used on
/// the device day-to-day.
class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  final _authService = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        setState(() {
          _loading = false;
          _error = "Login cancel ho gaya.";
        });
        return;
      }

      final provider = context.read<AppDataProvider>();
      final isActive = await _authService.ensureUserDocAndCheckActive(
        user,
        shopNameHint: provider.shopSettings.shopName,
      );
      await provider.setCloudActive(isActive, email: user.email);

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
        _loading = false;
        _error = "Login mein masla hua. Dubara koshish karein.";
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
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error != null) ...[
                        Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                      ],
                      _loading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            )
                          : BigButton(label: "Google Se Login Karein", icon: Icons.login, onTap: _signIn),
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
