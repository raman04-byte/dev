import '../models/category_model.dart';

abstract class CategoryRepository {
  Future<String> createCategory(CategoryModel category);
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> getCategoryById(String id);
  Future<void> updateCategory(String id, CategoryModel category);
  Future<void> deleteCategory(String id);
}
