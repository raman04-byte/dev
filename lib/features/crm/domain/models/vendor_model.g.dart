// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VendorModelAdapter extends TypeAdapter<VendorModel> {
  @override
  final int typeId = 2;

  @override
  VendorModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VendorModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      address: fields[2] as String,
      pincode: fields[3] as String,
      district: fields[4] as String,
      state: fields[5] as String,
      gstNo: fields[6] as String,
      mobileNumber: fields[7] as String,
      email: fields[8] as String,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      productDiscounts: (fields[11] as Map).cast<String, double>(),
      salesPersonName: fields[12] as String,
      salesPersonContact: fields[13] as String,
      productIds: (fields[14] as List).cast<String>(),
      productVariantPrices: (fields[15] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map).cast<String, dynamic>())),
      categoryIds: (fields[16] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, VendorModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.pincode)
      ..writeByte(4)
      ..write(obj.district)
      ..writeByte(5)
      ..write(obj.state)
      ..writeByte(6)
      ..write(obj.gstNo)
      ..writeByte(7)
      ..write(obj.mobileNumber)
      ..writeByte(8)
      ..write(obj.email)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.productDiscounts)
      ..writeByte(12)
      ..write(obj.salesPersonName)
      ..writeByte(13)
      ..write(obj.salesPersonContact)
      ..writeByte(14)
      ..write(obj.productIds)
      ..writeByte(15)
      ..write(obj.productVariantPrices)
      ..writeByte(16)
      ..write(obj.categoryIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
