import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data_provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/big_button.dart';
import 'login_screen.dart';
import 'google_sign_in_screen.dart';

/// Shown when a shop has signed in (verified their Google account) but the
/// admin hasn't flipped their account to active yet. They can tap
/// "Check Again" once they've been approved.
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  final _authService = AuthService();
  bool _checking = false;

  Future<void> _checkAgain() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _checking = true);
    try {
      final isActive = await _authService.checkActiveStatus(user.uid);
      final provider = context.read<AppDataProvider>();
      await provider.setCloudActive(isActive);

      if (!mounted) return;
      if (isActive) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        setState(() => _checking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Abhi tak activate nahi hua. Thori dair mein dubara try karein.")),
        );
      }
    } catch (_) {
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Internet check karein aur dubara koshish karein.")),
      );
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AppDataProvider>().shopSettings.loginEmail ?? "";

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
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.hourglass_top_rounded, color: AppColors.primaryGreen, size: 42),
                ),
                const SizedBox(height: 22),
                const Text(
                  "Approval Ka Intezar",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Aapka account ($email) register ho gaya hai.\nHumari team jald hi ise activate kar degi.",
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      _checking
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            )
                          : BigButton(label: "Dubara Check Karein", icon: Icons.refresh, onTap: _checkAgain),
                      const SizedBox(height: 10),
                      TextButton(onPressed: _logout, child: const Text("Logout")),
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
