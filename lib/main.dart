import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/customer.dart';
import 'models/invoice_item.dart';
import 'models/invoice.dart';
import 'models/payment.dart';
import 'models/shop_settings.dart';
import 'providers/app_data_provider.dart';
import 'services/sample_data_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/google_sign_in_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(InvoiceItemAdapter());
  Hive.registerAdapter(InvoiceAdapter());
  Hive.registerAdapter(PaymentAdapter());
  Hive.registerAdapter(ShopSettingsAdapter());

  // Reads android/app/google-services.json automatically via the
  // google-services Gradle plugin - no explicit options needed on Android.
  await Firebase.initializeApp();

  final appDataProvider = AppDataProvider();
  await appDataProvider.init();
  await SampleDataService.seedIfEmpty(appDataProvider);

  runApp(
    ChangeNotifierProvider.value(
      value: appDataProvider,
      child: const KhataBookApp(),
    ),
  );
}

class KhataBookApp extends StatelessWidget {
  const KhataBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KhataBook WhatsApp',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

/// Decides which screen to show at app start:
/// 1. No cloud account yet (never signed in with Google) -> GoogleSignInScreen
/// 2. Cloud account exists but not yet activated by admin -> PendingApprovalScreen
/// 3. Cloud account active -> local PIN gate (LoginScreen) -> MainShell
///
/// The activation check needs internet once; after that it's cached in
/// ShopSettings.cloudActive so the shop can keep working offline day-to-day.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  bool _checking = true;
  bool _needsSignIn = false;
  bool _pendingApproval = false;

  @override
  void initState() {
    super.initState();
    _resolveStartupRoute();
  }

  Future<void> _resolveStartupRoute() async {
    final provider = context.read<AppDataProvider>();
    final user = _authService.currentUser;

    if (user == null) {
      setState(() {
        _needsSignIn = true;
        _checking = false;
      });
      return;
    }

    // Start with the last known cached status (works offline).
    bool active = provider.shopSettings.cloudActive;
    try {
      active = await _authService.checkActiveStatus(user.uid);
      await provider.setCloudActive(active, email: user.email);
    } catch (_) {
      // No internet right now - fall back to the cached value above.
    }

    setState(() {
      _pendingApproval = !active;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_needsSignIn) {
      return const GoogleSignInScreen();
    }
    if (_pendingApproval) {
      return const PendingApprovalScreen();
    }

    final provider = context.watch<AppDataProvider>();
    return provider.isLoggedIn ? const MainShell() : const LoginScreen();
  }
}
