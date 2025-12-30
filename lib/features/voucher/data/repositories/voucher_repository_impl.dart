import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../domain/models/voucher_model.dart';
import '../../domain/models/voucher_signature_model.dart';
import '../../domain/repositories/voucher_repository.dart';

class VoucherRepositoryImpl implements VoucherRepository {
  final Databases _databases = AppwriteService().databases;
  final Storage _storage = AppwriteService().storage;
  static const String _databaseId = 'voucher_database';
  static const String _collectionId = 'voucher';
  static const String _signatureCollectionId = 'voucher_signature';
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

      // Cache the created voucher
      final createdVoucher = VoucherModel.fromJson({
        ...voucher.toJson(),
        '\$id': result.$id,
      });
      await CacheService.cacheVoucher(createdVoucher);

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
  /// Uses cache-first strategy: returns cached data immediately, then updates from server
  Future<List<VoucherModel>> getVouchersByState(
    String stateCode, {
    bool forceRefresh = false,
  }) async {
    try {
      // If not forcing refresh and cache exists, return cached data first
      if (!forceRefresh && CacheService.hasCacheForState(stateCode)) {
        final cachedVouchers = CacheService.getCachedVouchersByState(stateCode);
        if (cachedVouchers.isNotEmpty) {
          // Return cached data immediately
          // Optionally fetch fresh data in background
          _fetchAndCacheVouchers(stateCode);
          return cachedVouchers;
        }
      }

      // Fetch from server
      return await _fetchAndCacheVouchers(stateCode);
    } catch (e) {
      // If server fetch fails, try to return cached data
      final cachedVouchers = CacheService.getCachedVouchersByState(stateCode);
      if (cachedVouchers.isNotEmpty) {
        return cachedVouchers;
      }
      rethrow;
    }
  }

  Future<List<VoucherModel>> _fetchAndCacheVouchers(String stateCode) async {
    final result = await _databases.listDocuments(
      databaseId: _databaseId,
      collectionId: _collectionId,
      queries: [
        Query.equal('state', stateCode),
        Query.orderDesc('\$createdAt'), // Show newest first
        Query.limit(5000), // Get up to 5000 documents (Appwrite's max limit)
      ],
    );

    final vouchers = result.documents
        .map((doc) => VoucherModel.fromJson(doc.data))
        .toList();

    // Cache the fetched vouchers
    await CacheService.cacheVouchersByState(stateCode, vouchers);

    return vouchers;
  }

  @override
  Future<VoucherModel> getVoucherById(String id) async {
    // Try cache first
    final cachedVoucher = CacheService.getCachedVoucher(id);
    if (cachedVoucher != null) {
      return cachedVoucher;
    }

    try {
      final result = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
      );
      final voucher = VoucherModel.fromJson(result.data);

      // Cache the fetched voucher
      await CacheService.cacheVoucher(voucher);

      return voucher;
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

      // Update cache
      await CacheService.cacheVoucher(voucher);
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

      // Delete from cache
      await CacheService.deleteCachedVoucher(id);
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

  /// Download multiple signatures in batch with caching
  /// Returns a map of fileId -> signature bytes
  /// Checks cache first, then downloads missing signatures from Appwrite
  Future<Map<String, Uint8List>> downloadSignatureBatch(
    List<String> fileIds,
  ) async {
    final Map<String, Uint8List> signatures = {};

    // First, check cache for existing signatures
    final List<String> missingFileIds = [];
    for (final fileId in fileIds) {
      final cachedSignature = CacheService.getCachedSignature(fileId);
      if (cachedSignature != null) {
        signatures[fileId] = cachedSignature;
      } else {
        missingFileIds.add(fileId);
      }
    }

    // Download missing signatures from Appwrite
    if (missingFileIds.isNotEmpty) {
      final Map<String, Uint8List> downloadedSignatures = {};
      for (final fileId in missingFileIds) {
        try {
          final bytes = await downloadSignature(fileId);
          downloadedSignatures[fileId] = bytes;
          signatures[fileId] = bytes;
        } catch (e) {
          // Skip failed downloads
        }
      }

      // Cache the downloaded signatures in batch
      if (downloadedSignatures.isNotEmpty) {
        await CacheService.cacheSignatureBatch(downloadedSignatures);
      }
    }

    return signatures;
  }

  /// Fetch all staff signatures from voucher_signature collection
  @override
  Future<List<VoucherSignatureModel>> getAllStaffSignatures() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _signatureCollectionId,
        queries: [
          Query.limit(5000), // Get up to 5000 signatures
        ],
      );

      return result.documents
          .map((doc) => VoucherSignatureModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      // Return empty list if collection doesn't exist or error occurs
      return [];
    }
  }

  /// Download signature image from URL and return as Uint8List
  /// Automatically converts Google Drive viewer URLs to direct download URLs
  Future<Uint8List?> downloadSignatureFromUrl(String url) async {
    try {
      // Convert Google Drive viewer URL to direct download URL
      String downloadUrl = url;
      if (url.contains('drive.google.com')) {
        downloadUrl = _convertGoogleDriveUrl(url);
      }

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        // Check if we got HTML instead of an image
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('text/html')) {
          // This means the URL is not accessible or needs authentication
          return null;
        }
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert Google Drive viewer URL to direct download URL
  /// Supports formats:
  /// - https://drive.google.com/file/d/FILE_ID/view
  /// - https://drive.google.com/open?id=FILE_ID
  String _convertGoogleDriveUrl(String url) {
    // Extract file ID from different Google Drive URL formats
    String? fileId;

    // Format: https://drive.google.com/file/d/FILE_ID/view
    final viewPattern = RegExp(r'drive\.google\.com/file/d/([^/]+)');
    final viewMatch = viewPattern.firstMatch(url);
    if (viewMatch != null) {
      fileId = viewMatch.group(1);
    }

    // Format: https://drive.google.com/open?id=FILE_ID
    if (fileId == null) {
      final openPattern = RegExp('[?&]id=([^&]+)');
      final openMatch = openPattern.firstMatch(url);
      if (openMatch != null) {
        fileId = openMatch.group(1);
      }
    }

    // If we found a file ID, return direct download URL
    if (fileId != null) {
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }

    // Return original URL if we couldn't parse it
    return url;
  }
}
