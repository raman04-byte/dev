import 'package:hive_flutter/hive_flutter.dart';
import '../../features/voucher/domain/models/voucher_model.dart';

class CacheService {
  static const String _voucherBoxName = 'vouchers';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VoucherModelAdapter());
    }

    // Open boxes
    await Hive.openBox<VoucherModel>(_voucherBoxName);
  }

  static Box<VoucherModel> get voucherBox =>
      Hive.box<VoucherModel>(_voucherBoxName);

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
}
