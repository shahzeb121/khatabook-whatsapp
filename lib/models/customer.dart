import 'package:hive/hive.dart';

/// Customer model. Kept plain (no HiveObject) - identified by [id].
class Customer {
  final String id;
  String name;
  String phone; // Stored as +92xxxxxxxxxx

  Customer({
    required this.id,
    required this.name,
    required this.phone,
  });
}

/// Manual Hive adapter (equivalent to what build_runner would generate).
/// typeId 0
class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 0;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Customer(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone);
  }
}
