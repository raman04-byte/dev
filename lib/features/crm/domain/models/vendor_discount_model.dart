class VendorDiscountModel {
  final String categoryId;
  final double discountPercentage;

  VendorDiscountModel({
    required this.categoryId,
    required this.discountPercentage,
  });

  Map<String, dynamic> toJson() {
    return {'category': categoryId, 'discount': discountPercentage};
  }

  factory VendorDiscountModel.fromJson(Map<String, dynamic> json) {
    return VendorDiscountModel(
      categoryId: json['category'] as String,
      discountPercentage: (json['discount'] as num).toDouble(),
    );
  }
}
