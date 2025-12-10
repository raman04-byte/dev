import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 1)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String productCode;

  @HiveField(3)
  final String barcode;

  @HiveField(4)
  final List<String> photos; // URLs of uploaded photos

  @HiveField(5)
  final String hsnCode;

  @HiveField(6)
  final String unit;

  @HiveField(7)
  final String description;

  @HiveField(8)
  final double saleGst;

  @HiveField(9)
  final double purchaseGst;

  @HiveField(10)
  final double mrp;

  @HiveField(11)
  final int reorderPoint;

  @HiveField(12)
  final String packagingSize;

  @HiveField(13)
  final List<ProductSize> sizes;

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final DateTime updatedAt;

  @HiveField(16)
  final String? categoryId;

  ProductModel({
    this.id,
    required this.name,
    required this.productCode,
    required this.barcode,
    required this.photos,
    required this.hsnCode,
    required this.unit,
    required this.description,
    required this.saleGst,
    required this.purchaseGst,
    required this.mrp,
    required this.reorderPoint,
    required this.packagingSize,
    required this.sizes,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'productCode': productCode,
      'barcode': barcode,
      'photos': photos,
      'hsnCode': hsnCode,
      'unit': unit,
      'description': description,
      'saleGst': saleGst,
      'purchaseGst': purchaseGst,
      'mrp': mrp,
      'reorderPoint': reorderPoint,
      'packagingSize': packagingSize,
      'sizes': sizes.map((size) => size.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (categoryId != null) 'categoryId': categoryId,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['\$id'],
      name: json['name'],
      productCode: json['productCode'],
      barcode: json['barcode'],
      photos: List<String>.from(json['photos'] ?? []),
      hsnCode: json['hsnCode'],
      unit: json['unit'],
      description: json['description'],
      saleGst: (json['saleGst'] as num).toDouble(),
      purchaseGst: (json['purchaseGst'] as num).toDouble(),
      mrp: (json['mrp'] as num).toDouble(),
      reorderPoint: json['reorderPoint'],
      packagingSize: json['packagingSize'],
      sizes: (json['sizes'] as List<dynamic>)
          .map((size) => ProductSize.fromJson(size))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      categoryId: json['categoryId'],
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? productCode,
    String? barcode,
    List<String>? photos,
    String? hsnCode,
    String? unit,
    String? description,
    double? saleGst,
    double? purchaseGst,
    double? mrp,
    int? reorderPoint,
    String? packagingSize,
    List<ProductSize>? sizes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryId,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      productCode: productCode ?? this.productCode,
      barcode: barcode ?? this.barcode,
      photos: photos ?? this.photos,
      hsnCode: hsnCode ?? this.hsnCode,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      saleGst: saleGst ?? this.saleGst,
      purchaseGst: purchaseGst ?? this.purchaseGst,
      mrp: mrp ?? this.mrp,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      packagingSize: packagingSize ?? this.packagingSize,
      sizes: sizes ?? this.sizes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

@HiveType(typeId: 2)
class ProductSize extends HiveObject {
  @HiveField(0)
  final String sizeName;

  @HiveField(1)
  final double price;

  @HiveField(2)
  final int stock;

  @HiveField(3)
  final String productCode;

  @HiveField(4)
  final String barcode;

  @HiveField(5)
  final double mrp;

  @HiveField(6)
  final int reorderPoint;

  @HiveField(7)
  final String packagingSize;

  @HiveField(8)
  final double weight;

  ProductSize({
    required this.sizeName,
    required this.price,
    required this.stock,
    required this.productCode,
    required this.barcode,
    required this.mrp,
    required this.reorderPoint,
    required this.packagingSize,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'sizeName': sizeName,
      'price': price,
      'stock': stock,
      'productCode': productCode,
      'barcode': barcode,
      'mrp': mrp,
      'reorderPoint': reorderPoint,
      'packagingSize': packagingSize,
      'weight': weight,
    };
  }

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      sizeName: json['sizeName'],
      price: (json['price'] as num).toDouble(),
      stock: json['stock'],
      productCode: json['productCode'],
      barcode: json['barcode'],
      mrp: (json['mrp'] as num).toDouble(),
      reorderPoint: json['reorderPoint'],
      packagingSize: json['packagingSize'],
      weight: (json['weight'] as num).toDouble(),
    );
  }

  ProductSize copyWith({
    String? sizeName,
    double? price,
    int? stock,
    String? productCode,
    String? barcode,
    double? mrp,
    int? reorderPoint,
    String? packagingSize,
    double? weight,
  }) {
    return ProductSize(
      sizeName: sizeName ?? this.sizeName,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      productCode: productCode ?? this.productCode,
      barcode: barcode ?? this.barcode,
      mrp: mrp ?? this.mrp,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      packagingSize: packagingSize ?? this.packagingSize,
      weight: weight ?? this.weight,
    );
  }
}
