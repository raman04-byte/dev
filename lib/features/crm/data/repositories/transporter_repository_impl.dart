import 'package:appwrite/appwrite.dart';

import '../../../../core/services/appwrite_service.dart';
import '../../domain/models/transporter_model.dart';
import '../../domain/repositories/transporter_repository.dart';

class TransporterRepositoryImpl implements TransporterRepository {
  final Databases _databases = AppwriteService().databases;
  static const String _databaseId = 'account_master';
  static const String _collectionId = 'transport_master';

  @override
  Future<String> createTransporter(TransporterModel transporter) async {
    try {
      final response = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: transporter.toJson(),
      );

      return response.data[r'$id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<TransporterModel>> getAllTransporters() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [Query.orderDesc('\$createdAt')],
      );
      return result.documents
          .map((doc) => TransporterModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TransporterModel> getTransporterById(String id) async {
    try {
      final result = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
      );
      return TransporterModel.fromJson(result.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateTransporter(
    String id,
    TransporterModel transporter,
  ) async {
    try {
      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        data: transporter.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteTransporter(String id) async {
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
