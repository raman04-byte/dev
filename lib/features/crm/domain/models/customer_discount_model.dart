class CustomerDiscountModel {
  final String? id;
  final String categoryId;
  final double discountPercentage;

  CustomerDiscountModel({
    this.id,
    required this.categoryId,
    required this.discountPercentage,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '\$id': id,
      'category': categoryId,
      'discount': discountPercentage,
    };
  }

  factory CustomerDiscountModel.fromJson(Map<String, dynamic> json) {
    return CustomerDiscountModel(
      id: json['\$id'] as String?,
      categoryId: json['category'] as String,
      discountPercentage: (json['discount'] as num).toDouble(),
    );
  }

  CustomerDiscountModel copyWith({
    String? id,
    String? categoryId,
    double? discountPercentage,
  }) {
    return CustomerDiscountModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }
}
