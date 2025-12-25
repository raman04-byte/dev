// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MachineModelAdapter extends TypeAdapter<MachineModel> {
  @override
  final int typeId = 4;

  @override
  MachineModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MachineModel(
      id: fields[0] as String,
      name: fields[1] as String,
      code: fields[2] as String,
      level: fields[3] as int,
      isChild: fields[4] as bool,
      maintenancePeriodDays: fields[5] as int,
      lastMaintenanceDate: fields[6] as DateTime?,
      nextMaintenanceDate: fields[7] as DateTime?,
      status: fields[8] as String,
      parentId: fields[9] as String?,
      manufacturerName: fields[10] as String,
      runningHours: fields[11] as double,
      manufacturerModel: fields[12] as String?,
      contactName: fields[13] as String?,
      contactNumber: fields[14] as String?,
      purchaseDate: fields[15] as DateTime?,
      capacity: fields[16] as double?,
      powerConsumption: fields[17] as double?,
      location: fields[18] as String?,
      specification: fields[19] as String?,
      criticality: fields[20] as String?,
      expectedLifespanDays: fields[21] as int?,
      currentStock: fields[22] as int?,
      reorderPoint: fields[23] as int?,
      storageLocation: fields[24] as String?,
      shelfLifeDays: fields[25] as int?,
      suppliers: (fields[26] as List?)
          ?.map((dynamic e) => (e as Map).cast<dynamic, dynamic>())
          ?.toList(),
    );
  }

  @override
  void write(BinaryWriter writer, MachineModel obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.code)
      ..writeByte(3)
      ..write(obj.level)
      ..writeByte(4)
      ..write(obj.isChild)
      ..writeByte(5)
      ..write(obj.maintenancePeriodDays)
      ..writeByte(6)
      ..write(obj.lastMaintenanceDate)
      ..writeByte(7)
      ..write(obj.nextMaintenanceDate)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.parentId)
      ..writeByte(10)
      ..write(obj.manufacturerName)
      ..writeByte(11)
      ..write(obj.runningHours)
      ..writeByte(12)
      ..write(obj.manufacturerModel)
      ..writeByte(13)
      ..write(obj.contactName)
      ..writeByte(14)
      ..write(obj.contactNumber)
      ..writeByte(15)
      ..write(obj.purchaseDate)
      ..writeByte(16)
      ..write(obj.capacity)
      ..writeByte(17)
      ..write(obj.powerConsumption)
      ..writeByte(18)
      ..write(obj.location)
      ..writeByte(19)
      ..write(obj.specification)
      ..writeByte(20)
      ..write(obj.criticality)
      ..writeByte(21)
      ..write(obj.expectedLifespanDays)
      ..writeByte(22)
      ..write(obj.currentStock)
      ..writeByte(23)
      ..write(obj.reorderPoint)
      ..writeByte(24)
      ..write(obj.storageLocation)
      ..writeByte(25)
      ..write(obj.shelfLifeDays)
      ..writeByte(26)
      ..write(obj.suppliers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MachineModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
