import 'package:hive/hive.dart';

part 'voucher_model.g.dart';

@HiveType(typeId: 0)
class VoucherModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String farmerName;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String address;

  @HiveField(4)
  final String fileRegNo;

  @HiveField(5)
  final int amountOfExpenses;

  @HiveField(6)
  final String expensesBy;

  @HiveField(7)
  final List<String> natureOfExpenses;

  @HiveField(8)
  final List<String> amountToBePaid;

  @HiveField(9)
  final String state;

  @HiveField(10)
  final String? receiverSignature;

  @HiveField(11)
  final String? payorSignature;

  @HiveField(12)
  final String paymentMode; // 'Cash' or 'Credit'

  @HiveField(13)
  final String? recipientName;

  @HiveField(14)
  final String? recipientAddress;

  @HiveField(15)
  final DateTime? createdAt;

  VoucherModel({
    this.id,
    required this.farmerName,
    required this.date,
    required this.address,
    required this.fileRegNo,
    required this.amountOfExpenses,
    required this.expensesBy,
    required this.natureOfExpenses,
    required this.amountToBePaid,
    required this.state,
    this.receiverSignature,
    this.payorSignature,
    this.paymentMode = 'Cash',
    this.recipientName,
    this.recipientAddress,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'farmerName': farmerName,
      'date': date.toIso8601String(),
      'address': address,
      'fileRegNo': fileRegNo,
      'amountOfExpenses': amountOfExpenses,
      'expensesBy': expensesBy,
      'natureOfExpenses': natureOfExpenses,
      'amountToBePaid': amountToBePaid,
      'state': state,
      'receiverSignature': receiverSignature,
      'payorSignature': payorSignature,
      'paymentMode': paymentMode,
      if (recipientName != null) 'recipientName': recipientName,
      if (recipientAddress != null) 'recipientAddress': recipientAddress,
    };
  }

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['\$id'],
      farmerName: json['farmerName'],
      date: DateTime.parse(json['date']),
      address: json['address'],
      fileRegNo: json['fileRegNo'],
      amountOfExpenses: json['amountOfExpenses'],
      expensesBy: json['expensesBy'],
      natureOfExpenses: List<String>.from(json['natureOfExpenses']),
      amountToBePaid: List<String>.from(json['amountToBePaid']),
      state: json['state'],
      receiverSignature: json['receiverSignature'],
      payorSignature: json['payorSignature'],
      paymentMode: json['paymentMode'] ?? 'Cash',
      recipientName: json['recipientName'],
      recipientAddress: json['recipientAddress'],
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'])
          : null,
    );
  }
}
