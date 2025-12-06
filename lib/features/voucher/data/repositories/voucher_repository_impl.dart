import 'package:appwrite/appwrite.dart';
import 'dart:typed_data';
import '../../../../core/services/appwrite_service.dart';
import '../../domain/models/voucher_model.dart';
import '../../domain/repositories/voucher_repository.dart';

class VoucherRepositoryImpl implements VoucherRepository {
  final Databases _databases = AppwriteService().databases;
  final Storage _storage = AppwriteService().storage;
  static const String _databaseId = 'voucher_database';
  static const String _collectionId = 'voucher';
  static const String _signatureBucketId = 'signature';

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

  /// Upload signature image to Appwrite storage
  /// Returns the file ID
  Future<String?> uploadSignature(Uint8List signatureBytes) async {
    try {
      final fileId = ID.unique();
      final file = await _storage.createFile(
        bucketId: _signatureBucketId,
        fileId: fileId,
        file: InputFile.fromBytes(
          bytes: signatureBytes,
          filename: 'signature_$fileId.png',
        ),
      );
      return file.$id;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete signature image from Appwrite storage
  Future<void> deleteSignature(String fileId) async {
    try {
      await _storage.deleteFile(bucketId: _signatureBucketId, fileId: fileId);
    } catch (e) {
      // Silently fail if file doesn't exist
    }
  }

  /// Get signature image URL from Appwrite storage
  String getSignatureUrl(String fileId) {
    return '${AppwriteService().client.endPoint}/storage/buckets/$_signatureBucketId/files/$fileId/view?project=${AppwriteService().client.config['project']}';
  }

  /// Download signature image from Appwrite storage
  Future<Uint8List> downloadSignature(String fileId) async {
    try {
      final bytes = await _storage.getFileDownload(
        bucketId: _signatureBucketId,
        fileId: fileId,
      );
      return bytes;
    } catch (e) {
      rethrow;
    }
  }
}
