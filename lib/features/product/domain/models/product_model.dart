import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 1)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<String> photos; // URLs of uploaded photos

  @HiveField(3)
  final String hsnCode;

  @HiveField(4)
  final String unit;

  @HiveField(5)
  final String description;

  @HiveField(6)
  final double saleGst;

  @HiveField(7)
  final double purchaseGst;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final String? categoryId;

  @HiveField(11)
  final List<ProductSize> sizes; // For local cache only

  ProductModel({
    this.id,
    required this.name,
    required this.photos,
    required this.hsnCode,
    required this.unit,
    required this.description,
    required this.saleGst,
    required this.purchaseGst,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.sizes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'product_name': name,
      'product_photos': photos,
      'hsn_code': hsnCode,
      'unit': unit,
      'description': description,
      'sale_tax': saleGst,
      'purchase_tax': purchaseGst,
      if (categoryId != null) 'category': categoryId,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse variants from sizeVariants relationship if available
    List<ProductSize> variants = [];
    if (json['sizeVariants'] != null) {
      final sizeVariantsData = json['sizeVariants'];
      if (sizeVariantsData is List) {
        variants = sizeVariantsData
            .map((variantData) {
              // Handle if variant is already a map or needs to be extracted
              if (variantData is Map<String, dynamic>) {
                return ProductSize.fromJson(variantData);
              }
              return null;
            })
            .whereType<ProductSize>()
            .toList();
      }
    }

    return ProductModel(
      id: json[r'$id'] as String?,
      name: json['product_name'] as String,
      photos: List<String>.from(json['product_photos'] ?? []),
      hsnCode: json['hsn_code'] as String,
      unit: json['unit'] as String,
      description: json['description'] as String,
      saleGst: (json['sale_tax'] as num).toDouble(),
      purchaseGst: (json['purchase_tax'] as num).toDouble(),
      createdAt: DateTime.parse(json[r'$createdAt'] as String),
      updatedAt: DateTime.parse(json[r'$updatedAt'] as String),
      categoryId: json['category'] as String?,
      sizes: variants, // Use parsed variants from relationship
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    List<String>? photos,
    String? hsnCode,
    String? unit,
    String? description,
    double? saleGst,
    double? purchaseGst,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryId,
    List<ProductSize>? sizes,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      photos: photos ?? this.photos,
      hsnCode: hsnCode ?? this.hsnCode,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      saleGst: saleGst ?? this.saleGst,
      purchaseGst: purchaseGst ?? this.purchaseGst,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      sizes: sizes ?? this.sizes,
    );
  }
}

@HiveType(typeId: 2)
class ProductSize extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String sizeName;

  @HiveField(2)
  final String productCode;

  @HiveField(3)
  final String barcode;

  @HiveField(4)
  final double mrp;

  @HiveField(5)
  final int stockQuantity;

  @HiveField(6)
  final int reorderPoint;

  @HiveField(7)
  final int packagingSize;

  @HiveField(8)
  final double weight;

  @HiveField(9)
  final String? productId; // Foreign key reference

  ProductSize({
    this.id,
    required this.sizeName,
    required this.productCode,
    required this.barcode,
    required this.mrp,
    required this.stockQuantity,
    required this.reorderPoint,
    required this.packagingSize,
    required this.weight,
    this.productId,
  });

  Map<String, dynamic> toJson() {
    return {
      'size_name': sizeName,
      'product_code': productCode,
      'barcode': barcode,
      'mrp': mrp,
      'stock_quantity': stockQuantity,
      'reorder_point': reorderPoint,
      'packaging_size': packagingSize.toInt(), // Ensure it's sent as integer
      'weight': weight,
      // Note: sizeVariants is a relationship field, handled separately
    };
  }

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      id: json[r'$id'] as String?,
      sizeName: json['size_name'] as String,
      productCode: json['product_code'] as String,
      barcode: json['barcode'] as String,
      mrp: (json['mrp'] as num).toDouble(),
      stockQuantity: json['stock_quantity'] as int,
      reorderPoint: json['reorder_point'] as int,
      packagingSize: json['packaging_size'] as int,
      weight: (json['weight'] as num).toDouble(),
      productId: json['sizeVariants'] as String?,
    );
  }

  ProductSize copyWith({
    String? id,
    String? sizeName,
    String? productCode,
    String? barcode,
    double? mrp,
    int? stockQuantity,
    int? reorderPoint,
    int? packagingSize,
    double? weight,
    String? productId,
  }) {
    return ProductSize(
      id: id ?? this.id,
      sizeName: sizeName ?? this.sizeName,
      productCode: productCode ?? this.productCode,
      barcode: barcode ?? this.barcode,
      mrp: mrp ?? this.mrp,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      packagingSize: packagingSize ?? this.packagingSize,
      weight: weight ?? this.weight,
      productId: productId ?? this.productId,
    );
  }
}
