// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voucher_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoucherModelAdapter extends TypeAdapter<VoucherModel> {
  @override
  final int typeId = 0;

  @override
  VoucherModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VoucherModel(
      id: fields[0] as String?,
      farmerName: fields[1] as String,
      date: fields[2] as DateTime,
      address: fields[3] as String,
      fileRegNo: fields[4] as String,
      amountOfExpenses: fields[5] as int,
      expensesBy: fields[6] as String,
      natureOfExpenses: (fields[7] as List).cast<String>(),
      amountToBePaid: (fields[8] as List).cast<String>(),
      state: fields[9] as String,
      receiverSignature: fields[10] as String?,
      payorSignature: fields[11] as String?,
      paymentMode: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, VoucherModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.farmerName)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.fileRegNo)
      ..writeByte(5)
      ..write(obj.amountOfExpenses)
      ..writeByte(6)
      ..write(obj.expensesBy)
      ..writeByte(7)
      ..write(obj.natureOfExpenses)
      ..writeByte(8)
      ..write(obj.amountToBePaid)
      ..writeByte(9)
      ..write(obj.state)
      ..writeByte(10)
      ..write(obj.receiverSignature)
      ..writeByte(11)
      ..write(obj.payorSignature)
      ..writeByte(12)
      ..write(obj.paymentMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoucherModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
