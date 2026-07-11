import 'package:hive/hive.dart';

/// Single settings object for the shop (there's only ever one of these).
/// Holds shop details printed on Invoice/Ledger PDFs, the shop logo, and
/// the simple local login PIN.
class ShopSettings {
  String shopName;
  String phone;
  String address;
  String easypaisaNumber;
  String jazzcashNumber;
  String? logoPath; // local file path to picked logo image
  String? pin; // 4-digit local login PIN. null = no login set up yet.

  ShopSettings({
    this.shopName = "Meri Dukaan",
    this.phone = "",
    this.address = "",
    this.easypaisaNumber = "",
    this.jazzcashNumber = "",
    this.logoPath,
    this.pin,
  });

  bool get isPinSet => pin != null && pin!.isNotEmpty;
}

/// typeId 4
class ShopSettingsAdapter extends TypeAdapter<ShopSettings> {
  @override
  final int typeId = 4;

  @override
  ShopSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopSettings(
      shopName: fields[0] as String? ?? "Meri Dukaan",
      phone: fields[1] as String? ?? "",
      address: fields[2] as String? ?? "",
      easypaisaNumber: fields[3] as String? ?? "",
      jazzcashNumber: fields[4] as String? ?? "",
      logoPath: fields[5] as String?,
      pin: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ShopSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.shopName)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.easypaisaNumber)
      ..writeByte(4)
      ..write(obj.jazzcashNumber)
      ..writeByte(5)
      ..write(obj.logoPath)
      ..writeByte(6)
      ..write(obj.pin);
  }
}
