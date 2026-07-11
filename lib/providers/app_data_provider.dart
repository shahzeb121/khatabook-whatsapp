import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/payment.dart';
import '../models/ledger_entry.dart';
import '../models/shop_settings.dart';

/// Central app state. Holds references to the Hive boxes and exposes
/// simple methods the UI calls. Using Provider (ChangeNotifier) keeps this
/// v1 simple - no need for Riverpod's extra boilerplate.
class AppDataProvider extends ChangeNotifier {
  static const customerBoxName = 'customers';
  static const invoiceBoxName = 'invoices';
  static const paymentBoxName = 'payments';
  static const settingsBoxName = 'settings';
  static const _settingsKey = 'shop_settings';

  late Box<Customer> _customerBox;
  late Box<Invoice> _invoiceBox;
  late Box<Payment> _paymentBox;
  late Box<ShopSettings> _settingsBox;

  final _uuid = const Uuid();

  /// In-memory only - resets on cold app start, so login is required again.
  bool isLoggedIn = false;

  Future<void> init() async {
    _customerBox = await Hive.openBox<Customer>(customerBoxName);
    _invoiceBox = await Hive.openBox<Invoice>(invoiceBoxName);
    _paymentBox = await Hive.openBox<Payment>(paymentBoxName);
    _settingsBox = await Hive.openBox<ShopSettings>(settingsBoxName);
    if (_settingsBox.get(_settingsKey) == null) {
      _settingsBox.put(_settingsKey, ShopSettings());
    }
  }

  // ---------------- SHOP SETTINGS / LOGIN ----------------

  ShopSettings get shopSettings => _settingsBox.get(_settingsKey) ?? ShopSettings();

  Future<void> saveShopSettings(ShopSettings settings) async {
    await _settingsBox.put(_settingsKey, settings);
    notifyListeners();
  }

  bool verifyPin(String enteredPin) => shopSettings.pin == enteredPin;

  Future<void> setPin(String newPin) async {
    final settings = shopSettings;
    settings.pin = newPin;
    await saveShopSettings(settings);
  }

  void markLoggedIn() {
    isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    notifyListeners();
  }

  // ---------------- CUSTOMERS ----------------

  List<Customer> get customers => _customerBox.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Customer? customerById(String id) {
    try {
      return _customerBox.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Customer> addCustomer({required String name, required String phone}) async {
    final customer = Customer(id: _uuid.v4(), name: name, phone: phone);
    await _customerBox.put(customer.id, customer);
    notifyListeners();
    return customer;
  }

  Future<void> updateCustomer(Customer customer) async {
    await _customerBox.put(customer.id, customer);
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    await _customerBox.delete(id);
    notifyListeners();
  }

  // ---------------- INVOICES ----------------

  List<Invoice> get invoices => _invoiceBox.values.toList();

  List<Invoice> invoicesForCustomer(String customerId) {
    final list = _invoiceBox.values.where((i) => i.customerId == customerId).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<Invoice> addInvoice({
    required String customerId,
    required List<InvoiceItem> items,
    double taxPercent = 0,
    bool isPaid = false,
    DateTime? dueDate,
    DateTime? date,
  }) async {
    final nextNumber = _invoiceBox.values.isEmpty
        ? 101
        : (_invoiceBox.values.map((i) => i.invoiceNumber).reduce((a, b) => a > b ? a : b) + 1);
    final invoice = Invoice(
      id: _uuid.v4(),
      invoiceNumber: nextNumber,
      customerId: customerId,
      date: date ?? DateTime.now(),
      items: items,
      taxPercent: taxPercent,
      isPaid: isPaid,
      dueDate: dueDate,
    );
    await _invoiceBox.put(invoice.id, invoice);
    notifyListeners();
    return invoice;
  }

  // ---------------- PAYMENTS ----------------

  List<Payment> get payments => _paymentBox.values.toList();

  List<Payment> paymentsForCustomer(String customerId) {
    final list = _paymentBox.values.where((p) => p.customerId == customerId).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<Payment> addPayment({
    required String customerId,
    required int amount,
    required PaymentMethod method,
    DateTime? date,
    String? screenshotPath,
  }) async {
    final payment = Payment(
      id: _uuid.v4(),
      customerId: customerId,
      date: date ?? DateTime.now(),
      amount: amount,
      method: method,
      screenshotPath: screenshotPath,
    );
    await _paymentBox.put(payment.id, payment);
    notifyListeners();
    return payment;
  }

  // ---------------- BALANCE / LEDGER LOGIC ----------------

  /// Balance = sum(credit invoice totals) - sum(payments).
  /// Positive => customer owes shop ("Lena Hai" from shop's point of view).
  int balanceForCustomer(String customerId) {
    final creditTotal = _invoiceBox.values
        .where((i) => i.customerId == customerId && !i.isPaid)
        .fold<int>(0, (sum, i) => sum + i.total);
    final paidTotal = _paymentBox.values
        .where((p) => p.customerId == customerId)
        .fold<int>(0, (sum, p) => sum + p.amount);
    return creditTotal - paidTotal;
  }

  /// Sum of all positive balances across all customers -> Dashboard Card 1.
  int get totalLenaHai {
    int total = 0;
    for (final c in customers) {
      final bal = balanceForCustomer(c.id);
      if (bal > 0) total += bal;
    }
    return total;
  }

  /// Cash received today = today's payments + today's "Paid" invoices.
  int get aajCashAya {
    final now = DateTime.now();
    bool isToday(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;

    final fromPayments = _paymentBox.values
        .where((p) => isToday(p.date))
        .fold<int>(0, (sum, p) => sum + p.amount);
    final fromPaidInvoices = _invoiceBox.values
        .where((i) => i.isPaid && isToday(i.date))
        .fold<int>(0, (sum, i) => sum + i.total);
    return fromPayments + fromPaidInvoices;
  }

  /// Builds full running-balance ledger for a customer, sorted by date.
  /// Only CREDIT invoices count as "+" - paid invoices are cash sales and
  /// don't affect Udhaar balance, so they're left out of the Khata table.
  List<LedgerEntry> ledgerForCustomer(String customerId) {
    final events = <_LedgerEvent>[];

    for (final inv in invoicesForCustomer(customerId)) {
      if (!inv.isPaid) {
        events.add(_LedgerEvent(
          date: inv.date,
          details: "Invoice #${inv.invoiceNumber}",
          plus: inv.total,
          minus: 0,
        ));
      }
    }
    for (final pay in paymentsForCustomer(customerId)) {
      events.add(_LedgerEvent(
        date: pay.date,
        details: "Payment (${paymentMethodLabel(pay.method)})",
        plus: 0,
        minus: pay.amount,
      ));
    }

    events.sort((a, b) => a.date.compareTo(b.date));

    int running = 0;
    final entries = <LedgerEntry>[];
    for (final e in events) {
      running += e.plus - e.minus;
      entries.add(LedgerEntry(
        date: e.date,
        details: e.details,
        plus: e.plus,
        minus: e.minus,
        runningBalance: running,
      ));
    }
    return entries;
  }

  /// Customers who currently owe money (balance > 0), for the reminder screen.
  List<Customer> customersWithDues() {
    return customers.where((c) => balanceForCustomer(c.id) > 0).toList();
  }
}

class _LedgerEvent {
  final DateTime date;
  final String details;
  final int plus;
  final int minus;
  _LedgerEvent({required this.date, required this.details, required this.plus, required this.minus});
}
