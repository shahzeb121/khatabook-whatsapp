import '../models/invoice_item.dart';
import '../models/payment.dart';
import '../providers/app_data_provider.dart';

/// Seeds a few customers, invoices and payments on very first app launch,
/// so the user can immediately see how the app works without setup.
class SampleDataService {
  static Future<void> seedIfEmpty(AppDataProvider provider) async {
    if (provider.customers.isNotEmpty) return; // already has data

    final ali = await provider.addCustomer(name: "Ahmed Furniture", phone: "+923001112222");
    final sara = await provider.addCustomer(name: "Sara Tailors", phone: "+923004445555");
    final usman = await provider.addCustomer(name: "Usman Bhai", phone: "+923007778888");

    // Ahmed: credit invoice, no payment yet -> Lena Hai
    await provider.addInvoice(
      customerId: ali.id,
      items: [
        InvoiceItem(name: "Sofa Cover", qty: 2, price: 1500),
        InvoiceItem(name: "Cushion", qty: 4, price: 500),
      ],
      taxPercent: 0,
      isPaid: false,
      date: DateTime.now().subtract(const Duration(days: 10)),
      dueDate: DateTime.now().add(const Duration(days: 5)),
    );

    // Sara: credit invoice + partial payment
    await provider.addInvoice(
      customerId: sara.id,
      items: [
        InvoiceItem(name: "Shirt Stitching", qty: 3, price: 800),
      ],
      isPaid: false,
      date: DateTime.now().subtract(const Duration(days: 6)),
    );
    await provider.addPayment(
      customerId: sara.id,
      amount: 1000,
      method: PaymentMethod.jazzcash,
      date: DateTime.now().subtract(const Duration(days: 2)),
    );

    // Usman: fully paid invoice -> 0 balance (green)
    await provider.addInvoice(
      customerId: usman.id,
      items: [
        InvoiceItem(name: "Chai Patti 1kg", qty: 1, price: 950),
      ],
      isPaid: true,
      date: DateTime.now(),
    );
  }
}
