import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/appwrite_service.dart';
import '../../domain/models/vendor_discount_model.dart';
import '../../domain/models/vendor_model.dart';
import '../../domain/repositories/vendor_repository.dart';

class VendorRepositoryImpl implements VendorRepository {
  final Databases _databases = AppwriteService().databases;
  static const String _databaseId = 'account_master';
  static const String _collectionId = 'vendor';
  static const String _discountsCollectionId = 'vendor_product_discount';
  static const String _productPricesCollectionId = 'vendor_product_prices';

  @override
  Future<String> createVendor(VendorModel vendor) async {
    try {
      // 1. Create the main vendor document (without discounts and products initially)
      final vendorResponse = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: vendor.toJson(),
      );

      final vendorId = vendorResponse.data[r'$id'] as String;

      // 2. Create vendor discount documents and collect their IDs
      final discountIds = <String>[];
      for (final entry in vendor.productDiscounts.entries) {
        final discount = VendorDiscountModel(
          categoryId: entry.key,
          discountPercentage: entry.value,
        );
        final discountResponse = await _databases.createDocument(
          databaseId: _databaseId,
          collectionId: _discountsCollectionId,
          documentId: ID.unique(),
          data: discount.toJson(),
        );
        discountIds.add(discountResponse.data[r'$id'] as String);
      }

      // 2b. Create product variant price documents
      final priceIds = <String>[];
      for (final productEntry in vendor.productVariantPrices.entries) {
        final productId = productEntry.key;
        for (final variantEntry in productEntry.value.entries) {
          final variantId = variantEntry.key;
          final price = variantEntry.value;
          final priceResponse = await _databases.createDocument(
            databaseId: _databaseId,
            collectionId: _productPricesCollectionId,
            documentId: ID.unique(),
            data: {'product': productId, 'variant': variantId, 'price': price},
          );
          priceIds.add(priceResponse.data[r'$id'] as String);
        }
      }

      // 3. Update vendor with the vendorProductDiscount, vendorProductPrices, and vendorProducts relationships
      final updateData = <String, dynamic>{};
      if (discountIds.isNotEmpty) {
        updateData['vendorProductDiscount'] = discountIds;
      }
      if (priceIds.isNotEmpty) {
        updateData['vendorProductPrices'] = priceIds;
      }
      if (vendor.productIds.isNotEmpty) {
        updateData['vendorProducts'] = vendor.productIds;
      }

      if (updateData.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _collectionId,
          documentId: vendorId,
          data: updateData,
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
          Query.select([
            '*',
            'vendorProductDiscount.*',
            'vendorProducts.*',
            'vendorProductPrices.*',
          ]),
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
          Query.select([
            '*',
            'vendorProductDiscount.*',
            'vendorProducts.*',
            'vendorProductPrices.*',
          ]),
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

      // 1. Get existing discount IDs and price IDs from the vendor BEFORE updating
      final vendorDoc = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        queries: [
          Query.select([
            '*',
            'vendorProductDiscount.*',
            'vendorProducts.*',
            'vendorProductPrices.*',
          ]),
        ],
      );
      final existingDiscountIds =
          vendorDoc.data['vendorProductDiscount'] as List<dynamic>?;
      final existingPriceIds =
          vendorDoc.data['vendorProductPrices'] as List<dynamic>?;

      print('📋 Existing discount IDs: $existingDiscountIds');
      print('📋 Existing price IDs: $existingPriceIds');

      // 2. Delete old discounts
      if (existingDiscountIds != null && existingDiscountIds.isNotEmpty) {
        print('🗑️ Deleting ${existingDiscountIds.length} old discounts...');
        for (final discountDoc in existingDiscountIds) {
          try {
            // Extract the $id from the discount document
            final discountId = discountDoc[r'$id'] as String;
            await _databases.deleteDocument(
              databaseId: _databaseId,
              collectionId: _discountsCollectionId,
              documentId: discountId,
            );
            print('✅ Deleted discount: $discountId');
          } catch (e) {
            print('⚠️ Failed to delete discount: $e');
            // Continue if discount already deleted
            continue;
          }
        }
      }

      // 2b. Delete old product prices
      if (existingPriceIds != null && existingPriceIds.isNotEmpty) {
        print('🗑️ Deleting ${existingPriceIds.length} old product prices...');
        for (final priceDoc in existingPriceIds) {
          try {
            final priceId = priceDoc[r'$id'] as String;
            await _databases.deleteDocument(
              databaseId: _databaseId,
              collectionId: _productPricesCollectionId,
              documentId: priceId,
            );
            print('✅ Deleted price: $priceId');
          } catch (e) {
            print('⚠️ Failed to delete price: $e');
            continue;
          }
        }
      }

      // 3. Update main vendor document (after deleting old discounts)
      print('📝 Updating vendor document...');
      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        data: vendor.toJson(),
      );

      // 4. Create new discounts and collect their IDs
      final newDiscountIds = <String>[];
      print('➕ Creating ${vendor.productDiscounts.length} new discounts...');
      for (final entry in vendor.productDiscounts.entries) {
        final discount = VendorDiscountModel(
          categoryId: entry.key,
          discountPercentage: entry.value,
        );
        final discountResponse = await _databases.createDocument(
          databaseId: _databaseId,
          collectionId: _discountsCollectionId,
          documentId: ID.unique(),
          data: discount.toJson(),
        );
        final newId = discountResponse.data[r'$id'] as String;
        newDiscountIds.add(newId);
        print(
          '✅ Created discount: $newId (category: ${entry.key}, discount: ${entry.value}%)',
        );
      }

      // 4b. Create new product variant prices
      final newPriceIds = <String>[];
      print(
        '➕ Creating ${vendor.productVariantPrices.length} new product prices...',
      );
      for (final productEntry in vendor.productVariantPrices.entries) {
        final productId = productEntry.key;
        for (final variantEntry in productEntry.value.entries) {
          final variantId = variantEntry.key;
          final price = variantEntry.value;
          final priceResponse = await _databases.createDocument(
            databaseId: _databaseId,
            collectionId: _productPricesCollectionId,
            documentId: ID.unique(),
            data: {'product': productId, 'variant': variantId, 'price': price},
          );
          final newId = priceResponse.data[r'$id'] as String;
          newPriceIds.add(newId);
          print(
            '✅ Created price: $newId (product: $productId, variant: $variantId, price: $price)',
          );
        }
      }

      // 5. Update vendor with new discount IDs, price IDs, and product IDs
      final updateData = <String, dynamic>{};
      if (newDiscountIds.isNotEmpty) {
        print('🔗 Linking ${newDiscountIds.length} discounts to vendor...');
        updateData['vendorProductDiscount'] = newDiscountIds;
      }
      if (newPriceIds.isNotEmpty) {
        print('🔗 Linking ${newPriceIds.length} product prices to vendor...');
        updateData['vendorProductPrices'] = newPriceIds;
      }
      if (vendor.productIds.isNotEmpty) {
        print('🔗 Linking ${vendor.productIds.length} products to vendor...');
        updateData['vendorProducts'] = vendor.productIds;
      }

      if (updateData.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _collectionId,
          documentId: id,
          data: updateData,
        );
        print('✅ Update complete!');
      } else {
        print('⚠️ No discounts or products to link');
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
