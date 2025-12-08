import '../../../../core/services/cache_service.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  @override
  Future<String> createCategory(CategoryModel category) async {
    try {
      // Generate unique ID
      final id = 'category_${DateTime.now().millisecondsSinceEpoch}';
      final categoryWithId = category.copyWith(id: id);

      // Save to cache
      await CacheService.cacheCategory(categoryWithId);

      return id;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      return CacheService.getCachedCategories();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final categories = await getCategories();
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(String id, CategoryModel category) async {
    try {
      await CacheService.updateCachedCategory(id, category);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await CacheService.deleteCachedCategory(id);
    } catch (e) {
      rethrow;
    }
  }
}
