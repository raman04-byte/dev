import 'package:hive/hive.dart';

part 'transporter_model.g.dart';

@HiveType(typeId: 4)
class TransporterModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String transportName;

  @HiveField(2)
  final String address;

  @HiveField(3)
  final String gstNumber;

  @HiveField(4)
  final String contactName;

  @HiveField(5)
  final String contactNumber;

  @HiveField(6)
  final String remarks;

  @HiveField(7)
  final double rsPerCarton;

  @HiveField(8)
  final double rsPerKg;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  @HiveField(11)
  final List<String> deliveryPinCodes;

  @HiveField(12)
  final List<String> deliveryStates;

  TransporterModel({
    this.id,
    required this.transportName,
    required this.address,
    this.gstNumber = '',
    required this.contactName,
    required this.contactNumber,
    required this.remarks,
    this.rsPerCarton = 0.0,
    this.rsPerKg = 0.0,
    this.deliveryPinCodes = const [],
    this.deliveryStates = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'transportName': transportName,
      'address': address,
      'gstNumber': gstNumber,
      'contactName': contactName,
      'contactNumber': contactNumber,
      'remarks': remarks,
      'rsPerCarton': rsPerCarton,
      'rsPerKg': rsPerKg,
      'deliveryPinCodes': deliveryPinCodes,
      'deliveryStates': deliveryStates,
    };
  }

  factory TransporterModel.fromJson(Map<String, dynamic> json) {
    return TransporterModel(
      id: json['\$id'],
      transportName: json['transportName'] ?? '',
      address: json['address'] ?? '',
      gstNumber: json['gstNumber'] ?? '',
      contactName: json['contactName'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      remarks: json['remarks'] ?? '',
      rsPerCarton: (json['rsPerCarton'] ?? 0.0).toDouble(),
      rsPerKg: (json['rsPerKg'] ?? 0.0).toDouble(),
      deliveryPinCodes: json['deliveryPinCodes'] != null
          ? List<String>.from(json['deliveryPinCodes'])
          : [],
      deliveryStates: json['deliveryStates'] != null
          ? List<String>.from(json['deliveryStates'])
          : [],
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'])
          : DateTime.now(),
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.parse(json['\$updatedAt'])
          : DateTime.now(),
    );
  }

  TransporterModel copyWith({
    String? id,
    String? transportName,
    String? address,
    List<String>? deliveryPinCodes,
    List<String>? deliveryStates,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransporterModel(
      id: id ?? this.id,
      transportName: transportName ?? this.transportName,
      address: address ?? this.address,
      gstNumber: gstNumber,
      contactName: contactName,
      contactNumber: contactNumber,
      remarks: remarks,
      rsPerCarton: rsPerCarton,
      rsPerKg: rsPerKg,
      deliveryPinCodes: deliveryPinCodes ?? this.deliveryPinCodes,
      deliveryStates: deliveryStates ?? this.deliveryStates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
