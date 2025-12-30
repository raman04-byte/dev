import 'package:hive/hive.dart';

part 'maintenance_nodes.g.dart';

// Enums for various status and types
@HiveType(typeId: 10)
enum MaintenanceStatus {
  @HiveField(0)
  running,
  @HiveField(1)
  breakdown,
  @HiveField(2)
  underMaintenance,
  @HiveField(3)
  standby, // For Machine
}

@HiveType(typeId: 11)
enum CriticalityLevel {
  @HiveField(0)
  critical,
  @HiveField(1)
  semiCritical,
  @HiveField(2)
  nonCritical,
}

@HiveType(typeId: 12)
class Supplier extends HiveObject {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String address;
  @HiveField(2)
  final String contactName;
  @HiveField(3)
  final String contactNumber;
  @HiveField(4)
  final double? lastPurchasedRate;

  Supplier({
    required this.name,
    required this.address,
    required this.contactName,
    required this.contactNumber,
    this.lastPurchasedRate,
  });
}

// Base class for all maintenance nodes
abstract class MaintenanceNode extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name; // Machine Name, Component Name, etc.
  @HiveField(2)
  final List<MaintenanceNode> children;

  MaintenanceNode({
    required this.id,
    required this.name,
    List<MaintenanceNode>? children,
  }) : children = children ?? [];
}

@HiveType(typeId: 13)
class MachineNode extends MaintenanceNode {
  @HiveField(3)
  final String code;
  @HiveField(4)
  final String manufacturer;
  @HiveField(5)
  final String modelNumber;
  @HiveField(6)
  final String serialNumber;
  @HiveField(7)
  final String location;

  // Technical Capability
  @HiveField(8)
  final double? ratedCapacity; // kg/hr
  @HiveField(9)
  final double? powerConsumption; // kW/hr

  // Status
  @HiveField(10)
  final DateTime? dateOfPurchase;
  @HiveField(11)
  final MaintenanceStatus currentStatus;

  // Maintenance Control
  @HiveField(12)
  final CriticalityLevel criticality;
  @HiveField(13)
  final DateTime? lastMaintenanceDate;
  @HiveField(14)
  final DateTime? nextMaintenanceDate;
  @HiveField(15)
  final int maintenanceCycleDays;

  MachineNode({
    required super.id,
    required super.name,
    super.children,
    required this.code,
    required this.manufacturer,
    required this.modelNumber,
    required this.serialNumber,
    required this.location,
    this.ratedCapacity,
    this.powerConsumption,
    this.dateOfPurchase,
    required this.currentStatus,
    required this.criticality,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    required this.maintenanceCycleDays,
  });
}

@HiveType(typeId: 14)
class MajorAssemblyNode extends MaintenanceNode {
  MajorAssemblyNode({required super.id, required super.name, super.children});

  int get subAssemblyCount => children.whereType<SubAssemblyNode>().length;
  int get componentCount => children.whereType<ComponentNode>().length;
}

@HiveType(typeId: 15)
class SubAssemblyNode extends MaintenanceNode {
  SubAssemblyNode({required super.id, required super.name, super.children});

  int get componentCount => children.whereType<ComponentNode>().length;
}

@HiveType(typeId: 16)
class ComponentNode extends MaintenanceNode {
  @HiveField(3)
  final String modelNumber;
  @HiveField(4)
  final String manufacturerOrBrand;
  @HiveField(5)
  final String specification;

  // Maintenance Control
  @HiveField(6)
  final CriticalityLevel criticality;
  @HiveField(7)
  final DateTime? lastMaintenanceDate;
  @HiveField(8)
  final DateTime? nextMaintenanceDate;
  @HiveField(9)
  final int maintenanceCycleDays;

  // Supplier
  @HiveField(10)
  final List<Supplier> suppliers;

  // Inventory
  @HiveField(11)
  final int currentStockQuantity;
  @HiveField(12)
  final int reorderLevel;
  @HiveField(13)
  final String location;
  @HiveField(14)
  final int? shelfLifeDays;

  ComponentNode({
    required super.id,
    required super.name,
    super.children,
    required this.modelNumber,
    required this.manufacturerOrBrand,
    required this.specification,
    required this.criticality,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    required this.maintenanceCycleDays,
    this.suppliers = const [],
    required this.currentStockQuantity,
    required this.reorderLevel,
    required this.location,
    this.shelfLifeDays,
  });
}
