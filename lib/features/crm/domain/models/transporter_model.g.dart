// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transporter_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransporterModelAdapter extends TypeAdapter<TransporterModel> {
  @override
  final int typeId = 4;

  @override
  TransporterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransporterModel(
      id: fields[0] as String?,
      transportName: fields[1] as String,
      address: fields[2] as String,
      gstNumber: fields[3] as String,
      contactName: fields[4] as String,
      contactNumber: fields[5] as String,
      remarks: fields[6] as String,
      rsPerCarton: fields[7] as double,
      rsPerKg: fields[8] as double,
      deliveryPinCodes: (fields[11] as List).cast<String>(),
      deliveryStates: (fields[12] as List).cast<String>(),
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TransporterModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.transportName)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.gstNumber)
      ..writeByte(4)
      ..write(obj.contactName)
      ..writeByte(5)
      ..write(obj.contactNumber)
      ..writeByte(6)
      ..write(obj.remarks)
      ..writeByte(7)
      ..write(obj.rsPerCarton)
      ..writeByte(8)
      ..write(obj.rsPerKg)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.deliveryPinCodes)
      ..writeByte(12)
      ..write(obj.deliveryStates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransporterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
