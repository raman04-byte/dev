import 'package:hive/hive.dart';

part 'party_model.g.dart';

@HiveType(typeId: 1)
class PartyModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String address;

  @HiveField(3)
  final String pincode;

  @HiveField(4)
  final String district;

  @HiveField(5)
  final String state;

  @HiveField(6)
  final String gstNo;

  @HiveField(7)
  final String mobileNumber;

  @HiveField(8)
  final String email;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  @HiveField(11)
  final Map<String, double> productDiscounts;

  @HiveField(12)
  final String status;

  @HiveField(13)
  final String paymentTerms;

  @HiveField(14)
  final String salesPerson;

  PartyModel({
    this.id,
    required this.name,
    required this.address,
    required this.pincode,
    required this.district,
    required this.state,
    required this.gstNo,
    required this.mobileNumber,
    required this.email,
    this.productDiscounts = const {},
    this.status = 'Active',
    this.paymentTerms = 'On Credit',
    this.salesPerson = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'pincode': pincode,
      'district': district,
      'state': state,
      'gstNo': gstNo,
      'mobileNumber': mobileNumber,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'productDiscounts': productDiscounts,
      'status': status,
      'paymentTerms': paymentTerms,
      'salesPerson': salesPerson,
    };
  }

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    return PartyModel(
      id: json['\$id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      pincode: json['pincode'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      gstNo: json['gstNo'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      productDiscounts: json['productDiscounts'] != null
          ? Map<String, double>.from(json['productDiscounts'])
          : const {},
      status: json['status'] ?? 'Active',
      paymentTerms: json['paymentTerms'] ?? 'On Credit',
      salesPerson: json['salesPerson'] ?? '',
    );
  }

  PartyModel copyWith({
    String? id,
    String? name,
    String? address,
    String? pincode,
    String? district,
    String? state,
    String? gstNo,
    String? mobileNumber,
    String? email,
    Map<String, double>? productDiscounts,
    String? status,
    String? paymentTerms,
    String? salesPerson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PartyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      district: district ?? this.district,
      state: state ?? this.state,
      gstNo: gstNo ?? this.gstNo,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      productDiscounts: productDiscounts ?? this.productDiscounts,
      status: status ?? this.status,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      salesPerson: salesPerson ?? this.salesPerson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
