class VoucherModel {
  final String? id;
  final String farmerName;
  final DateTime date;
  final String address;
  final String fileRegNo;
  final int amountOfExpenses;
  final String expensesBy;
  final List<String> natureOfExpenses;
  final List<String> amountToBePaid;
  final String state;

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
    );
  }
}
