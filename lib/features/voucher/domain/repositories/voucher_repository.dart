import '../models/voucher_model.dart';

abstract class VoucherRepository {
  Future<String> createVoucher(VoucherModel voucher);
  Future<List<VoucherModel>> getVouchers();
  Future<VoucherModel> getVoucherById(String id);
  Future<void> updateVoucher(String id, VoucherModel voucher);
  Future<void> deleteVoucher(String id);
}
