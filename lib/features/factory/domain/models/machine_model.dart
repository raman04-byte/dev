import 'package:hive/hive.dart';

part 'machine_model.g.dart';

@HiveType(typeId: 4)
class MachineModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String code;

  @HiveField(3)
  final int level;

  @HiveField(4)
  final bool isChild;

  @HiveField(5)
  final int maintenancePeriodDays; // Duration in days

  @HiveField(6)
  final DateTime? lastMaintenanceDate;

  @HiveField(7)
  final DateTime? nextMaintenanceDate;

  @HiveField(8)
  final String status; // 'Needed new part', 'Can work', 'Needed attention'

  @HiveField(9)
  final String? parentId;

  @HiveField(10)
  final String manufacturerName;

  @HiveField(11)
  final double runningHours;

  // Additional fields for machines/components
  @HiveField(12)
  final String? manufacturerModel;

  @HiveField(13)
  final String? contactName;

  @HiveField(14)
  final String? contactNumber;

  @HiveField(15)
  final DateTime? purchaseDate;

  @HiveField(16)
  final double? capacity;

  @HiveField(17)
  final double? powerConsumption;

  @HiveField(18)
  final String? location;

  @HiveField(19)
  final String? specification;

  @HiveField(20)
  final String? criticality;

  @HiveField(21)
  final int? expectedLifespanDays;

  @HiveField(22)
  final int? currentStock;

  @HiveField(23)
  final int? reorderPoint;

  @HiveField(24)
  final String? storageLocation;

  @HiveField(25)
  final int? shelfLifeDays;

  @HiveField(26)
  final List<Map>? suppliers;

  MachineModel({
    required this.id,
    required this.name,
    required this.code,
    required this.level,
    required this.isChild,
    required this.maintenancePeriodDays,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    required this.status,
    this.parentId,
    required this.manufacturerName,
    required this.runningHours,
    this.manufacturerModel,
    this.contactName,
    this.contactNumber,
    this.purchaseDate,
    this.capacity,
    this.powerConsumption,
    this.location,
    this.specification,
    this.criticality,
    this.expectedLifespanDays,
    this.currentStock,
    this.reorderPoint,
    this.storageLocation,
    this.shelfLifeDays,
    this.suppliers,
  });

  MachineModel copyWith({
    String? id,
    String? name,
    String? code,
    int? level,
    bool? isChild,
    int? maintenancePeriodDays,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    String? status,
    String? parentId,
    String? manufacturerName,
    double? runningHours,
    String? manufacturerModel,
    String? contactName,
    String? contactNumber,
    DateTime? purchaseDate,
    double? capacity,
    double? powerConsumption,
    String? location,
    String? specification,
    String? criticality,
    int? expectedLifespanDays,
    int? currentStock,
    int? reorderPoint,
    String? storageLocation,
    int? shelfLifeDays,
    List<Map>? suppliers,
  }) {
    return MachineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      level: level ?? this.level,
      isChild: isChild ?? this.isChild,
      maintenancePeriodDays:
          maintenancePeriodDays ?? this.maintenancePeriodDays,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      status: status ?? this.status,
      parentId: parentId ?? this.parentId,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      runningHours: runningHours ?? this.runningHours,
      manufacturerModel: manufacturerModel ?? this.manufacturerModel,
      contactName: contactName ?? this.contactName,
      contactNumber: contactNumber ?? this.contactNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      capacity: capacity ?? this.capacity,
      powerConsumption: powerConsumption ?? this.powerConsumption,
      location: location ?? this.location,
      specification: specification ?? this.specification,
      criticality: criticality ?? this.criticality,
      expectedLifespanDays: expectedLifespanDays ?? this.expectedLifespanDays,
      currentStock: currentStock ?? this.currentStock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      storageLocation: storageLocation ?? this.storageLocation,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
      suppliers: suppliers ?? this.suppliers,
    );
  }
}
