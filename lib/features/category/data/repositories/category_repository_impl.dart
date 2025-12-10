import 'package:appwrite/appwrite.dart';

import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final Databases _databases = AppwriteService().databases;
  static const String databaseId = 'product_database';
  static const String collectionId = 'product_category';

  @override
  Future<String> createCategory(CategoryModel category) async {
    try {
      final response = await _databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: category.toJson(),
      );

      final createdCategory = CategoryModel.fromJson(response.data);

      // Save to cache
      await CacheService.cacheCategory(createdCategory);

      return createdCategory.id;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
      );

      final categories = response.documents
          .map((doc) => CategoryModel.fromJson(doc.data))
          .toList();

      // Update cache
      for (var category in categories) {
        await CacheService.cacheCategory(category);
      }

      return categories;
    } catch (e) {
      // Fallback to cache if network fails
      try {
        return CacheService.getCachedCategories();
      } catch (_) {
        rethrow;
      }
    }
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final response = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
      );

      return CategoryModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(String id, CategoryModel category) async {
    try {
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
        data: category.toJson(),
      );

      // Update cache
      await CacheService.updateCachedCategory(id, category);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _databases.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
      );

      // Delete from cache
      await CacheService.deleteCachedCategory(id);
    } catch (e) {
      rethrow;
    }
  }
}
