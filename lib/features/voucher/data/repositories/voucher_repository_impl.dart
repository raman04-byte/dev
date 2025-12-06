import 'package:appwrite/appwrite.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../domain/models/voucher_model.dart';
import '../../domain/repositories/voucher_repository.dart';

class VoucherRepositoryImpl implements VoucherRepository {
  final Databases _databases = AppwriteService().databases;
  static const String _databaseId = 'voucher_database';
  static const String _collectionId = 'voucher';

  @override
  Future<String> createVoucher(VoucherModel voucher) async {
    try {
      final result = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: voucher.toJson(),
      );
      return result.$id;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<VoucherModel>> getVouchers() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
      );
      return result.documents
          .map((doc) => VoucherModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get vouchers filtered by state code (server-side filtering)
  Future<List<VoucherModel>> getVouchersByState(String stateCode) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('state', stateCode),
          Query.orderDesc('\$createdAt'), // Show newest first
        ],
      );
      return result.documents
          .map((doc) => VoucherModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<VoucherModel> getVoucherById(String id) async {
    try {
      final result = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
      );
      return VoucherModel.fromJson(result.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateVoucher(String id, VoucherModel voucher) async {
    try {
      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        data: voucher.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteVoucher(String id) async {
    try {
      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
      );
    } catch (e) {
      rethrow;
    }
  }
}
