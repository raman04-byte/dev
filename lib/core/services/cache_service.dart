import 'package:hive_flutter/hive_flutter.dart';

import '../../features/category/domain/models/category_model.dart';
import '../../features/factory/domain/models/machine_model.dart';
import '../../features/product/domain/models/product_model.dart';
import '../../features/voucher/domain/models/voucher_model.dart';

class CacheService {
  static const String _voucherBoxName = 'vouchers';
  static const String _productBoxName = 'products';
  static const String _categoryBoxName = 'categories';
  static const String _machineBoxName = 'machines';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VoucherModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ProductSizeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(MachineModelAdapter());
    }

    // Open boxes
    await Hive.openBox<VoucherModel>(_voucherBoxName);
    await Hive.openBox<ProductModel>(_productBoxName);
    await Hive.openBox<CategoryModel>(_categoryBoxName);
    await Hive.openBox<MachineModel>(_machineBoxName);
  }

  static Box<VoucherModel> get voucherBox =>
      Hive.box<VoucherModel>(_voucherBoxName);

  static Box<ProductModel> get productBox =>
      Hive.box<ProductModel>(_productBoxName);

  static Box<CategoryModel> get categoryBox =>
      Hive.box<CategoryModel>(_categoryBoxName);

  static Box<MachineModel> get machineBox =>
      Hive.box<MachineModel>(_machineBoxName);

  // Cache vouchers by state
  static Future<void> cacheVouchersByState(
    String stateCode,
    List<VoucherModel> vouchers,
  ) async {
    final box = voucherBox;

    // Remove old vouchers for this state
    final keysToDelete = box.keys.where((key) {
      final voucher = box.get(key);
      return voucher?.state == stateCode;
    }).toList();

    await box.deleteAll(keysToDelete);

    // Add new vouchers
    for (final voucher in vouchers) {
      if (voucher.id != null) {
        await box.put(voucher.id, voucher);
      }
    }
  }

  // Get cached vouchers by state
  static List<VoucherModel> getCachedVouchersByState(String stateCode) {
    final box = voucherBox;
    return box.values.where((v) => v.state == stateCode).toList();
  }

  // Cache single voucher
  static Future<void> cacheVoucher(VoucherModel voucher) async {
    if (voucher.id != null) {
      await voucherBox.put(voucher.id, voucher);
    }
  }

  // Get cached voucher by ID
  static VoucherModel? getCachedVoucher(String id) {
    return voucherBox.get(id);
  }

  // Delete cached voucher
  static Future<void> deleteCachedVoucher(String id) async {
    await voucherBox.delete(id);
  }

  // Clear all cached vouchers
  static Future<void> clearVoucherCache() async {
    await voucherBox.clear();
  }

  // Check if cache exists for state
  static bool hasCacheForState(String stateCode) {
    return voucherBox.values.any((v) => v.state == stateCode);
  }

  // Get cache timestamp (you can store this separately if needed)
  static DateTime? getLastCacheTime(String stateCode) {
    // For now, return null. You can implement a separate box for metadata if needed
    return null;
  }

  // ==================== Product Cache Methods ====================

  // Cache all products
  static Future<void> cacheProducts(List<ProductModel> products) async {
    final box = productBox;
    await box.clear(); // Clear old products

    // Add new products
    for (final product in products) {
      if (product.id != null) {
        await box.put(product.id, product);
      }
    }
  }

  // Get all cached products
  static List<ProductModel> getCachedProducts() {
    final box = productBox;
    return box.values.toList();
  }

  // Cache single product
  static Future<void> cacheProduct(ProductModel product) async {
    if (product.id != null) {
      await productBox.put(product.id, product);
    }
  }

  // Get cached product by ID
  static ProductModel? getCachedProduct(String id) {
    return productBox.get(id);
  }

  // Delete cached product
  static Future<void> deleteCachedProduct(String id) async {
    await productBox.delete(id);
  }

  // Clear all cached products
  static Future<void> clearProductCache() async {
    await productBox.clear();
  }

  // ==================== Category Cache Methods ====================

  // Get all cached categories
  static List<CategoryModel> getCachedCategories() {
    final box = categoryBox;
    return box.values.toList();
  }

  // Cache single category
  static Future<void> cacheCategory(CategoryModel category) async {
    await categoryBox.put(category.id, category);
  }

  // Get cached category by ID
  static CategoryModel? getCachedCategory(String id) {
    return categoryBox.get(id);
  }

  // Update cached category
  static Future<void> updateCachedCategory(
    String id,
    CategoryModel category,
  ) async {
    await categoryBox.put(id, category);
  }

  // Delete cached category
  static Future<void> deleteCachedCategory(String id) async {
    await categoryBox.delete(id);
  }

  // Clear all cached categories
  static Future<void> clearCategoryCache() async {
    await categoryBox.clear();
  }
}
