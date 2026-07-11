import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/customer.dart';
import 'models/invoice_item.dart';
import 'models/invoice.dart';
import 'models/payment.dart';
import 'models/shop_settings.dart';
import 'providers/app_data_provider.dart';
import 'services/sample_data_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(InvoiceItemAdapter());
  Hive.registerAdapter(InvoiceAdapter());
  Hive.registerAdapter(PaymentAdapter());
  Hive.registerAdapter(ShopSettingsAdapter());

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

/// Decides whether to show the Login screen or jump straight into the app.
/// Since login state (`isLoggedIn`) is in-memory only, every cold app start
/// requires the PIN again - this is intentional for a shared shop device.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    if (provider.isLoggedIn) {
      return const MainShell();
    }
    return const LoginScreen();
  }
}
