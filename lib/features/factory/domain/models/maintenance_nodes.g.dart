// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_nodes.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SupplierAdapter extends TypeAdapter<Supplier> {
  @override
  final int typeId = 12;

  @override
  Supplier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Supplier(
      name: fields[0] as String,
      address: fields[1] as String,
      contactName: fields[2] as String,
      contactNumber: fields[3] as String,
      lastPurchasedRate: fields[4] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Supplier obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.contactName)
      ..writeByte(3)
      ..write(obj.contactNumber)
      ..writeByte(4)
      ..write(obj.lastPurchasedRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MachineNodeAdapter extends TypeAdapter<MachineNode> {
  @override
  final int typeId = 13;

  @override
  MachineNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MachineNode(
      id: fields[0] as String,
      name: fields[1] as String,
      children: (fields[2] as List).cast<MaintenanceNode>(),
      code: fields[3] as String,
      manufacturer: fields[4] as String,
      modelNumber: fields[5] as String,
      serialNumber: fields[6] as String,
      location: fields[7] as String,
      ratedCapacity: fields[8] as double?,
      powerConsumption: fields[9] as double?,
      dateOfPurchase: fields[10] as DateTime?,
      currentStatus: fields[11] as MaintenanceStatus,
      criticality: fields[12] as CriticalityLevel,
      lastMaintenanceDate: fields[13] as DateTime?,
      nextMaintenanceDate: fields[14] as DateTime?,
      maintenanceCycleDays: fields[15] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MachineNode obj) {
    writer
      ..writeByte(16)
      ..writeByte(3)
      ..write(obj.code)
      ..writeByte(4)
      ..write(obj.manufacturer)
      ..writeByte(5)
      ..write(obj.modelNumber)
      ..writeByte(6)
      ..write(obj.serialNumber)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.ratedCapacity)
      ..writeByte(9)
      ..write(obj.powerConsumption)
      ..writeByte(10)
      ..write(obj.dateOfPurchase)
      ..writeByte(11)
      ..write(obj.currentStatus)
      ..writeByte(12)
      ..write(obj.criticality)
      ..writeByte(13)
      ..write(obj.lastMaintenanceDate)
      ..writeByte(14)
      ..write(obj.nextMaintenanceDate)
      ..writeByte(15)
      ..write(obj.maintenanceCycleDays)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.children);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MachineNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MajorAssemblyNodeAdapter extends TypeAdapter<MajorAssemblyNode> {
  @override
  final int typeId = 14;

  @override
  MajorAssemblyNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MajorAssemblyNode(
      id: fields[0] as String,
      name: fields[1] as String,
      children: (fields[2] as List).cast<MaintenanceNode>(),
    );
  }

  @override
  void write(BinaryWriter writer, MajorAssemblyNode obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.children);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MajorAssemblyNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubAssemblyNodeAdapter extends TypeAdapter<SubAssemblyNode> {
  @override
  final int typeId = 15;

  @override
  SubAssemblyNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubAssemblyNode(
      id: fields[0] as String,
      name: fields[1] as String,
      children: (fields[2] as List).cast<MaintenanceNode>(),
    );
  }

  @override
  void write(BinaryWriter writer, SubAssemblyNode obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.children);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubAssemblyNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ComponentNodeAdapter extends TypeAdapter<ComponentNode> {
  @override
  final int typeId = 16;

  @override
  ComponentNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComponentNode(
      id: fields[0] as String,
      name: fields[1] as String,
      children: (fields[2] as List).cast<MaintenanceNode>(),
      modelNumber: fields[3] as String,
      manufacturerOrBrand: fields[4] as String,
      specification: fields[5] as String,
      criticality: fields[6] as CriticalityLevel,
      lastMaintenanceDate: fields[7] as DateTime?,
      nextMaintenanceDate: fields[8] as DateTime?,
      maintenanceCycleDays: fields[9] as int,
      suppliers: (fields[10] as List).cast<Supplier>(),
      currentStockQuantity: fields[11] as int,
      reorderLevel: fields[12] as int,
      location: fields[13] as String,
      shelfLifeDays: fields[14] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ComponentNode obj) {
    writer
      ..writeByte(15)
      ..writeByte(3)
      ..write(obj.modelNumber)
      ..writeByte(4)
      ..write(obj.manufacturerOrBrand)
      ..writeByte(5)
      ..write(obj.specification)
      ..writeByte(6)
      ..write(obj.criticality)
      ..writeByte(7)
      ..write(obj.lastMaintenanceDate)
      ..writeByte(8)
      ..write(obj.nextMaintenanceDate)
      ..writeByte(9)
      ..write(obj.maintenanceCycleDays)
      ..writeByte(10)
      ..write(obj.suppliers)
      ..writeByte(11)
      ..write(obj.currentStockQuantity)
      ..writeByte(12)
      ..write(obj.reorderLevel)
      ..writeByte(13)
      ..write(obj.location)
      ..writeByte(14)
      ..write(obj.shelfLifeDays)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.children);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MaintenanceStatusAdapter extends TypeAdapter<MaintenanceStatus> {
  @override
  final int typeId = 10;

  @override
  MaintenanceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MaintenanceStatus.running;
      case 1:
        return MaintenanceStatus.breakdown;
      case 2:
        return MaintenanceStatus.underMaintenance;
      case 3:
        return MaintenanceStatus.standby;
      default:
        return MaintenanceStatus.running;
    }
  }

  @override
  void write(BinaryWriter writer, MaintenanceStatus obj) {
    switch (obj) {
      case MaintenanceStatus.running:
        writer.writeByte(0);
        break;
      case MaintenanceStatus.breakdown:
        writer.writeByte(1);
        break;
      case MaintenanceStatus.underMaintenance:
        writer.writeByte(2);
        break;
      case MaintenanceStatus.standby:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CriticalityLevelAdapter extends TypeAdapter<CriticalityLevel> {
  @override
  final int typeId = 11;

  @override
  CriticalityLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CriticalityLevel.critical;
      case 1:
        return CriticalityLevel.semiCritical;
      case 2:
        return CriticalityLevel.nonCritical;
      default:
        return CriticalityLevel.critical;
    }
  }

  @override
  void write(BinaryWriter writer, CriticalityLevel obj) {
    switch (obj) {
      case CriticalityLevel.critical:
        writer.writeByte(0);
        break;
      case CriticalityLevel.semiCritical:
        writer.writeByte(1);
        break;
      case CriticalityLevel.nonCritical:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CriticalityLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
