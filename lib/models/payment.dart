import 'package:hive/hive.dart';

enum PaymentMethod { cash, jazzcash, easypaisa }

/// Payment = money received from a customer (reduces balance / "Lena Hai").
class Payment {
  final String id;
  final String customerId;
  final DateTime date;
  final int amount;
  final PaymentMethod method;
  final String? screenshotPath;

  Payment({
    required this.id,
    required this.customerId,
    required this.date,
    required this.amount,
    required this.method,
    this.screenshotPath,
  });
}

/// typeId 3
class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 3;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      id: fields[0] as String,
      customerId: fields[1] as String,
      date: fields[2] as DateTime,
      amount: fields[3] as int,
      method: PaymentMethod.values[fields[4] as int],
      screenshotPath: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.method.index)
      ..writeByte(5)
      ..write(obj.screenshotPath);
  }
}

/// Helper for showing method name in Roman Urdu / English
String paymentMethodLabel(PaymentMethod m) {
  switch (m) {
    case PaymentMethod.cash:
      return "Cash";
    case PaymentMethod.jazzcash:
      return "JazzCash";
    case PaymentMethod.easypaisa:
      return "Easypaisa";
  }
}
