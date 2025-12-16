import 'package:hive/hive.dart';

part 'vendor_model.g.dart';

@HiveType(typeId: 2)
class VendorModel extends HiveObject {
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
  final String salesPersonName;

  @HiveField(13)
  final String salesPersonContact;

  @HiveField(14)
  final List<String> productIds; // IDs of products

  @HiveField(15)
  final Map<String, Map<String, dynamic>> productVariantPrices; // Map<productId, Map<variantId, price>>

  @HiveField(16)
  final List<String> categoryIds; // IDs of categories

  VendorModel({
    this.id,
    required this.name,
    required this.address,
    required this.pincode,
    required this.district,
    required this.state,
    required this.gstNo,
    required this.mobileNumber,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.productDiscounts = const {},
    this.salesPersonName = '',
    this.salesPersonContact = '',
    this.productIds = const [],
    this.productVariantPrices = const {},
    this.categoryIds = const [],
  });

  VendorModel copyWith({
    String? id,
    String? name,
    String? address,
    String? pincode,
    String? district,
    String? state,
    String? gstNo,
    String? mobileNumber,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, double>? productDiscounts,
    String? salesPersonName,
    String? salesPersonContact,
    List<String>? productIds,
    Map<String, Map<String, dynamic>>? productVariantPrices,
    List<String>? categoryIds,
  }) {
    return VendorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      district: district ?? this.district,
      state: state ?? this.state,
      gstNo: gstNo ?? this.gstNo,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productDiscounts: productDiscounts ?? this.productDiscounts,
      salesPersonName: salesPersonName ?? this.salesPersonName,
      salesPersonContact: salesPersonContact ?? this.salesPersonContact,
      productIds: productIds ?? this.productIds,
      productVariantPrices: productVariantPrices ?? this.productVariantPrices,
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_name': name,
      'address': address,
      'pincode': int.parse(pincode),
      'district': district,
      'state': state,
      'gst_number': gstNo,
      'mobile_number': int.parse(mobileNumber),
      'email': email,
      'sales_person': salesPersonName,
      'sales_contact': salesPersonContact.isNotEmpty
          ? int.parse(salesPersonContact)
          : null,
      if (categoryIds.isNotEmpty) 'category': categoryIds,
      // Note: vendorPriceList will be stored via relationship
    };
  }

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing vendor from JSON: ${json.keys}');

    // Parse product variant prices from vendorPriceList relationship
    Map<String, Map<String, dynamic>> variantPrices = {};
    if (json['vendorPriceList'] != null) {
      final pricesData = json['vendorPriceList'];
      if (pricesData is List) {
        print('📦 Found ${pricesData.length} price list entries');
        variantPrices = _parseVendorPriceList(pricesData);
      }
    }

    final vendor = VendorModel(
      id: json[r'$id'] as String?,
      name: json['vendor_name'] as String,
      address: json['address'] as String? ?? '',
      pincode: json['pincode']?.toString() ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      gstNo: json['gst_number'] as String? ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      createdAt: DateTime.parse(json[r'$createdAt'] as String),
      updatedAt: DateTime.parse(json[r'$updatedAt'] as String),
      productDiscounts: const {},
      salesPersonName: json['sales_person'] as String? ?? '',
      salesPersonContact: json['sales_contact']?.toString() ?? '',
      productIds: const [],
      productVariantPrices: variantPrices,
      categoryIds: json['category'] != null
          ? List<String>.from(json['category'] as List)
          : [],
    );

    print('✅ Successfully parsed vendor: ${vendor.name}');
    return vendor;
  }

  static Map<String, Map<String, dynamic>> _parseVendorPriceList(
    List<dynamic> pricesData,
  ) {
    final Map<String, Map<String, dynamic>> result = {};

    for (final priceEntry in pricesData) {
      if (priceEntry is Map<String, dynamic>) {
        // Extract variant ID from the name field (format: "productId_variantId")
        final name = priceEntry['name'] as String?;
        final mrp = priceEntry['mrp'];
        final price = priceEntry['price'];
        final priceId = priceEntry[r'$id'] as String?;

        if (name != null && name.contains('_')) {
          final parts = name.split('_');
          if (parts.length >= 2) {
            final productId = parts[0];
            final variantId = parts[1];

            if (!result.containsKey(productId)) {
              result[productId] = {};
            }
            result[productId]![variantId] = {
              'price': price != null ? (price as num).toDouble() : 0.0,
              'mrp': mrp != null ? (mrp as num).toDouble() : 0.0,
              'priceId': priceId,
            };
            print(
              '  ✓ Product: $productId, Variant: $variantId, Price: $price, MRP: $mrp',
            );
          }
        }
      }
    }

    print('⚠️ Total product-variant prices parsed: ${result.length}');
    return result;
  }
}
