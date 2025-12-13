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
      'mobile_number': mobileNumber,
      'email': email,
      'sales_person_name': salesPersonName,
      'sales_person_contact': salesPersonContact,
      // Note: productDiscounts will be stored separately via relationship
      // Note: productIds will be stored via relationship
    };
  }

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing vendor from JSON: ${json.keys}');

    // Parse product discounts from vendorProductDiscount relationship
    Map<String, double> discounts = {};
    if (json['vendorProductDiscount'] != null) {
      final discountData = json['vendorProductDiscount'];
      if (discountData is List) {
        print('📦 Found ${discountData.length} discount entries');
        discounts = _parseVendorDiscounts(discountData);
      }
    }

    // Parse product IDs from vendorProducts relationship
    List<String> products = [];
    if (json['vendorProducts'] != null) {
      final productsData = json['vendorProducts'];
      if (productsData is List) {
        print('📦 Found ${productsData.length} products');
        products = productsData
            .map((p) => p is Map ? p[r'$id'] as String? : null)
            .whereType<String>()
            .toList();
      }
    }

    // Parse product variant prices from vendorProductPrices relationship
    Map<String, Map<String, dynamic>> variantPrices = {};
    if (json['vendorProductPrices'] != null) {
      final pricesData = json['vendorProductPrices'];
      if (pricesData is List) {
        print('📦 Found ${pricesData.length} product variant prices');
        variantPrices = _parseVendorProductPrices(pricesData);
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
      mobileNumber: json['mobile_number'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: DateTime.parse(json[r'$createdAt'] as String),
      updatedAt: DateTime.parse(json[r'$updatedAt'] as String),
      productDiscounts: discounts,
      salesPersonName: json['sales_person_name'] as String? ?? '',
      salesPersonContact: json['sales_person_contact'] as String? ?? '',
      productIds: products,
      productVariantPrices: variantPrices,
    );

    print('✅ Successfully parsed vendor: ${vendor.name}');
    return vendor;
  }

  static Map<String, double> _parseVendorDiscounts(List<dynamic> discountData) {
    final Map<String, double> result = {};

    for (final discount in discountData) {
      if (discount is Map<String, dynamic>) {
        final categoryId = discount['category'] as String?;
        final discountValue = discount['discount'];

        if (categoryId != null && discountValue != null) {
          result[categoryId] = (discountValue as num).toDouble();
          print('  ✓ Category: $categoryId, Discount: $discountValue%');
        }
      }
    }

    print('⚠️ Total discounts parsed: ${result.length}');
    return result;
  }

  static Map<String, Map<String, dynamic>> _parseVendorProductPrices(
    List<dynamic> pricesData,
  ) {
    final Map<String, Map<String, dynamic>> result = {};

    for (final priceEntry in pricesData) {
      if (priceEntry is Map<String, dynamic>) {
        final productId = priceEntry['product'] as String?;
        final variantId = priceEntry['variant'] as String?;
        final price = priceEntry['price'];

        if (productId != null && variantId != null && price != null) {
          if (!result.containsKey(productId)) {
            result[productId] = {};
          }
          result[productId]![variantId] = (price as num).toDouble();
          print('  ✓ Product: $productId, Variant: $variantId, Price: $price');
        }
      }
    }

    print('⚠️ Total product-variant prices parsed: ${result.length}');
    return result;
  }
}
