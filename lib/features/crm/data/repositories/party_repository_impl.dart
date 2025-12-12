import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/appwrite_service.dart';
import '../../domain/models/party_model.dart';
import '../../domain/repositories/party_repository.dart';

class PartyRepositoryImpl implements PartyRepository {
  final Databases _databases = AppwriteService().databases;
  static const String _databaseId = 'crm_database';
  static const String _collectionId = 'parties';

  @override
  Future<String> createParty(PartyModel party) async {
    try {
      final result = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: party.toJson(),
      );
      return result.$id;
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
        queries: [Query.orderDesc('\$createdAt')],
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
        queries: [Query.equal('state', state), Query.orderDesc('\$createdAt')],
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
      );
      return PartyModel.fromJson(result.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateParty(String id, PartyModel party) async {
    try {
      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        data: party.toJson(),
      );
    } catch (e) {
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

  @override
  Future<Map<String, String>?> getGSTDetails(String gstNumber) async {
    try {
      // Clean GST number (remove spaces and convert to uppercase)
      final cleanGst = gstNumber.replaceAll(' ', '').toUpperCase();

      // Validate GST format (15 characters)
      if (cleanGst.length != 15) {
        return null;
      }

      // Using GST public search API
      final response = await http
          .get(
            Uri.parse(
              'https://services.gst.gov.in/services/api/search/taxpayerDetails',
            ),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('GST API response: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract details from response
        if (data != null) {
          return {
            'name': data['lgnm'] ?? data['tradeNam'] ?? '',
            'address': _formatAddress(data),
            'pincode': data['pradr']?['addr']?['pncd'] ?? '',
            'district': data['pradr']?['addr']?['dst'] ?? '',
            'state': _getStateName(data['pradr']?['addr']?['stcd']),
          };
        }
      }

      // Fallback: Extract basic info from GST number itself
      return _extractGSTBasicInfo(cleanGst);
    } catch (e) {
      // If API fails, extract basic info from GST number
      return _extractGSTBasicInfo(gstNumber.replaceAll(' ', '').toUpperCase());
    }
  }

  Map<String, String> _extractGSTBasicInfo(String gstNumber) {
    // GST format: 22AAAAA0000A1Z5
    // First 2 digits: State code
    final stateCode = gstNumber.substring(0, 2);

    return {
      'name': '',
      'address': '',
      'pincode': '',
      'district': '',
      'state': _getStateName(stateCode),
    };
  }

  String _formatAddress(Map<String, dynamic> data) {
    final addr = data['pradr']?['addr'];
    if (addr == null) return '';

    final parts = <String>[
      addr['bno'] ?? '',
      addr['bnm'] ?? '',
      addr['st'] ?? '',
      addr['loc'] ?? '',
      addr['dst'] ?? '',
    ].where((s) => s.isNotEmpty).toList();

    return parts.join(', ');
  }

  String _getStateName(String? stateCode) {
    if (stateCode == null || stateCode.isEmpty) return '';

    final stateMap = {
      '01': 'Jammu and Kashmir',
      '02': 'Himachal Pradesh',
      '03': 'Punjab',
      '04': 'Chandigarh',
      '05': 'Uttarakhand',
      '06': 'Haryana',
      '07': 'Delhi',
      '08': 'Rajasthan',
      '09': 'Uttar Pradesh',
      '10': 'Bihar',
      '11': 'Sikkim',
      '12': 'Arunachal Pradesh',
      '13': 'Nagaland',
      '14': 'Manipur',
      '15': 'Mizoram',
      '16': 'Tripura',
      '17': 'Meghalaya',
      '18': 'Assam',
      '19': 'West Bengal',
      '20': 'Jharkhand',
      '21': 'Odisha',
      '22': 'Chhattisgarh',
      '23': 'Madhya Pradesh',
      '24': 'Gujarat',
      '26': 'Dadra and Nagar Haveli and Daman and Diu',
      '27': 'Maharashtra',
      '29': 'Karnataka',
      '30': 'Goa',
      '31': 'Lakshadweep',
      '32': 'Kerala',
      '33': 'Tamil Nadu',
      '34': 'Puducherry',
      '35': 'Andaman and Nicobar Islands',
      '36': 'Telangana',
      '37': 'Andhra Pradesh',
      '38': 'Ladakh',
    };

    return stateMap[stateCode] ?? '';
  }
}
