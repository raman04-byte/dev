// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PartyModelAdapter extends TypeAdapter<PartyModel> {
  @override
  final int typeId = 1;

  @override
  PartyModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PartyModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      address: fields[2] as String,
      pincode: fields[3] as String,
      district: fields[4] as String,
      state: fields[5] as String,
      gstNo: fields[6] as String,
      mobileNumber: fields[7] as String,
      email: fields[8] as String,
      productDiscounts: (fields[11] as Map).cast<String, double>(),
      status: fields[12] as String,
      paymentTerms: fields[13] as String,
      salesPerson: fields[14] as String,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PartyModel obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.paymentTerms)
      ..writeByte(14)
      ..write(obj.salesPerson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartyModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
