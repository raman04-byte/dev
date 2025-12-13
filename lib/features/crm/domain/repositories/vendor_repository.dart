import '../models/vendor_model.dart';

abstract class VendorRepository {
  Future<String> createVendor(VendorModel vendor);
  Future<List<VendorModel>> getAllVendors();
  Future<Map<String, List<VendorModel>>> getVendorsByState();
  Future<VendorModel> getVendorById(String id);
  Future<void> updateVendor(String id, VendorModel vendor);
  Future<void> deleteVendor(String id);
  Future<Map<String, String>?> getPincodeDetails(String pincode);
}
