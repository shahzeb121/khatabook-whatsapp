/// A single row in the Customer Ledger / Khata screen.
/// Derived on-the-fly from Invoice + Payment records — never stored directly.
class LedgerEntry {
  final DateTime date;
  final String details; // e.g. "Invoice #102" or "Payment (Cash)"
  final int plus; // "+" column -> increases Lena Hai (new invoice/credit)
  final int minus; // "-" column -> decreases Lena Hai (payment received)
  final int runningBalance;

  LedgerEntry({
    required this.date,
    required this.details,
    required this.plus,
    required this.minus,
    required this.runningBalance,
  });
}
