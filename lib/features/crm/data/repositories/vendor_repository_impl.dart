import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/appwrite_service.dart';
import '../../domain/models/vendor_model.dart';
import '../../domain/repositories/vendor_repository.dart';

class VendorRepositoryImpl implements VendorRepository {
  final Databases _databases = AppwriteService().databases;
  static const String _databaseId = 'account_master';
  static const String _collectionId = 'vendor';
  static const String _priceListCollectionId = 'vendor_price_list';

  @override
  Future<String> createVendor(VendorModel vendor) async {
    try {
      // 1. Create the main vendor document
      final vendorResponse = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: vendor.toJson(),
      );

      final vendorId = vendorResponse.data[r'$id'] as String;

      // 2. Create vendor_price_list documents for each product variant with price
      final priceListIds = <String>[];
      for (final productEntry in vendor.productVariantPrices.entries) {
        final productId = productEntry.key;
        for (final variantEntry in productEntry.value.entries) {
          final variantId = variantEntry.key;
          final variantData = variantEntry.value;

          final priceResponse = await _databases.createDocument(
            databaseId: _databaseId,
            collectionId: _priceListCollectionId,
            documentId: ID.unique(),
            data: {
              'name':
                  '${productId}_$variantId', // Store as productId_variantId for easy parsing
              'mrp': variantData['mrp'],
              'price': variantData['price'],
            },
          );
          priceListIds.add(priceResponse.data[r'$id'] as String);
        }
      }

      // 3. Update vendor with the vendorPriceList relationship
      if (priceListIds.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _collectionId,
          documentId: vendorId,
          data: {'vendorPriceList': priceListIds},
        );
      }

      return vendorId;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<VendorModel>> getAllVendors() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.select(['*', 'vendorPriceList.*']),
          Query.orderDesc(r'$createdAt'),
          Query.limit(100),
        ],
      );
      return result.documents
          .map((doc) => VendorModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, List<VendorModel>>> getVendorsByState() async {
    try {
      final vendors = await getAllVendors();
      final Map<String, List<VendorModel>> vendorsByState = {};

      for (final vendor in vendors) {
        if (!vendorsByState.containsKey(vendor.state)) {
          vendorsByState[vendor.state] = [];
        }
        vendorsByState[vendor.state]!.add(vendor);
      }

      return vendorsByState;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<VendorModel> getVendorById(String id) async {
    try {
      final result = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        queries: [
          Query.select(['*', 'vendorPriceList.*']),
        ],
      );
      return VendorModel.fromJson(result.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateVendor(String id, VendorModel vendor) async {
    try {
      print('🔄 Starting updateVendor for ID: $id');

      // 1. Get existing price list IDs from the vendor BEFORE updating
      final vendorDoc = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        queries: [
          Query.select(['*', 'vendorPriceList.*']),
        ],
      );
      final existingPriceListIds =
          vendorDoc.data['vendorPriceList'] as List<dynamic>?;

      print('📋 Existing price list IDs: $existingPriceListIds');

      // 2. Delete old price list entries
      if (existingPriceListIds != null && existingPriceListIds.isNotEmpty) {
        print(
          '🗑️ Deleting ${existingPriceListIds.length} old price list entries...',
        );
        for (final priceDoc in existingPriceListIds) {
          try {
            final priceId = priceDoc[r'$id'] as String;
            await _databases.deleteDocument(
              databaseId: _databaseId,
              collectionId: _priceListCollectionId,
              documentId: priceId,
            );
            print('✅ Deleted price list entry: $priceId');
          } catch (e) {
            print('⚠️ Failed to delete price list entry: $e');
            continue;
          }
        }
      }

      // 3. Update main vendor document
      print('📝 Updating vendor document...');
      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        data: vendor.toJson(),
      );

      // 4. Create new price list entries
      final newPriceListIds = <String>[];
      print(
        '➕ Creating ${vendor.productVariantPrices.length} new price list entries...',
      );
      for (final productEntry in vendor.productVariantPrices.entries) {
        final productId = productEntry.key;
        for (final variantEntry in productEntry.value.entries) {
          final variantId = variantEntry.key;
          final variantData = variantEntry.value;

          final priceResponse = await _databases.createDocument(
            databaseId: _databaseId,
            collectionId: _priceListCollectionId,
            documentId: ID.unique(),
            data: {
              'name': '${productId}_$variantId',
              'mrp': variantData['mrp'],
              'price': variantData['price'],
            },
          );
          final newId = priceResponse.data[r'$id'] as String;
          newPriceListIds.add(newId);
          print(
            '✅ Created price list entry: $newId (product: $productId, variant: $variantId)',
          );
        }
      }

      // 5. Update vendor with new price list IDs
      if (newPriceListIds.isNotEmpty) {
        print(
          '🔗 Linking ${newPriceListIds.length} price list entries to vendor...',
        );
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _collectionId,
          documentId: id,
          data: {'vendorPriceList': newPriceListIds},
        );
        print('✅ Update complete!');
      } else {
        print('⚠️ No price list entries to link');
      }
    } catch (e) {
      print('❌ Error updating vendor: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteVendor(String id) async {
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

  @override
  Future<Map<String, String>?> getPincodeDetails(String pincode) async {
    try {
      // Using India Post Pincode API
      final response = await http.get(
        Uri.parse('https://api.postalpincode.in/pincode/$pincode'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[0]['Status'] == 'Success' && data[0]['PostOffice'] != null) {
          final postOffice = data[0]['PostOffice'][0];
          return {
            'district': postOffice['District'] ?? '',
            'state': postOffice['State'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
