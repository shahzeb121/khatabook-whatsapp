import 'package:hive/hive.dart';
import 'invoice_item.dart';

/// Invoice = a bill given to a customer. Can be "Credit" (Lena Hai -> adds to
/// balance) or "Paid" (settled immediately, does not add to balance).
class Invoice {
  final String id;
  final int invoiceNumber; // simple incrementing display number
  final String customerId;
  final DateTime date;
  final List<InvoiceItem> items;
  final double taxPercent;
  final bool isPaid; // true = Paid on the spot, false = Credit (Udhaar)
  final DateTime? dueDate;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.date,
    required this.items,
    this.taxPercent = 0,
    this.isPaid = false,
    this.dueDate,
  });

  int get subtotal => items.fold(0, (sum, item) => sum + item.total);

  int get taxAmount => ((subtotal * taxPercent) / 100).round();

  int get total => subtotal + taxAmount;
}

/// typeId 2
class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 2;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invoice(
      id: fields[0] as String,
      invoiceNumber: fields[1] as int,
      customerId: fields[2] as String,
      date: fields[3] as DateTime,
      items: (fields[4] as List).cast<InvoiceItem>(),
      taxPercent: (fields[5] as num).toDouble(),
      isPaid: fields[6] as bool,
      dueDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.customerId)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.taxPercent)
      ..writeByte(6)
      ..write(obj.isPaid)
      ..writeByte(7)
      ..write(obj.dueDate);
  }
}
