import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/appwrite_service.dart';
import '../../domain/models/customer_discount_model.dart';
import '../../domain/models/party_model.dart';
import '../../domain/repositories/party_repository.dart';

class PartyRepositoryImpl implements PartyRepository {
  final Databases _databases = AppwriteService().databases;
  static const String _databaseId = 'account_master';
  static const String _collectionId = 'customer';
  static const String _discountsCollectionId = 'customer_product_discount';

  @override
  Future<String> createParty(PartyModel party) async {
    try {
      // 1. Create the main customer document (without discounts initially)
      final customerResponse = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: party.toJson(),
      );

      final customerId = customerResponse.data[r'$id'] as String;

      // 2. Create customer discount documents and collect their IDs
      final discountIds = <String>[];
      for (final entry in party.productDiscounts.entries) {
        final discount = CustomerDiscountModel(
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

      // 3. Update customer with the customerProductDiscount relationship
      if (discountIds.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _collectionId,
          documentId: customerId,
          data: {'customerProductDiscount': discountIds},
        );
      }

      return customerId;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PartyModel>> getAllParties() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.orderDesc('\$createdAt'),
          Query.select(['*', 'customerProductDiscount.*']),
        ],
      );
      return result.documents
          .map((doc) => PartyModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PartyModel>> getPartiesByState(String state) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('state', state),
          Query.orderDesc('\$createdAt'),
          Query.select(['*', 'customerProductDiscount.*']),
        ],
      );
      return result.documents
          .map((doc) => PartyModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PartyModel> getPartyById(String id) async {
    try {
      final result = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        queries: [
          Query.select(['*', 'customerProductDiscount.*']),
        ],
      );
      return PartyModel.fromJson(result.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateParty(String id, PartyModel party) async {
    try {
      // 1. Get existing discount IDs from the customer BEFORE updating
      final customerDoc = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        queries: [
          Query.select(['*', 'customerProductDiscount.*']),
        ],
      );
      final existingDiscountIds =
          customerDoc.data['customerProductDiscount'] as List<dynamic>?;
      // 2. Delete old discounts
      if (existingDiscountIds != null && existingDiscountIds.isNotEmpty) {
        for (final discountDoc in existingDiscountIds) {
          try {
            // Extract the $id from the discount document
            final discountId = discountDoc[r'$id'] as String;
            await _databases.deleteDocument(
              databaseId: _databaseId,
              collectionId: _discountsCollectionId,
              documentId: discountId,
            );
          } catch (e) {
            // Continue if discount already deleted
            continue;
          }
        }
      }
      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        data: party.toJson(),
      );

      // 4. Create new discounts and collect their IDs
      final newDiscountIds = <String>[];
      for (final entry in party.productDiscounts.entries) {
        final discount = CustomerDiscountModel(
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

      // 5. Update customer with new discount IDs
      if (newDiscountIds.isNotEmpty) {
        print('🔗 Linking ${newDiscountIds.length} discounts to customer...');
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _collectionId,
          documentId: id,
          data: {'customerProductDiscount': newDiscountIds},
        );
        print('✅ Update complete!');
      } else {
        print('⚠️ No discounts to link');
      }
    } catch (e) {
      print('❌ Error updating party: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteParty(String id) async {
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
