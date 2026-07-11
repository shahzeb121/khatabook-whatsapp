import 'package:hive/hive.dart';

/// A single line item inside an Invoice (item name, qty, price per unit).
class InvoiceItem {
  String name;
  int qty;
  int price; // Rs. per unit, whole numbers only (no decimals)

  InvoiceItem({
    required this.name,
    required this.qty,
    required this.price,
  });

  int get total => qty * price;
}

/// typeId 1
class InvoiceItemAdapter extends TypeAdapter<InvoiceItem> {
  @override
  final int typeId = 1;

  @override
  InvoiceItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceItem(
      name: fields[0] as String,
      qty: fields[1] as int,
      price: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.qty)
      ..writeByte(2)
      ..write(obj.price);
  }
}
