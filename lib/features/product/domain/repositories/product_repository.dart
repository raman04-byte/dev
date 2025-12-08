import '../models/product_model.dart';

abstract class ProductRepository {
  Future<String> createProduct(ProductModel product);
  Future<List<ProductModel>> getProducts({bool forceRefresh = false});
  Future<ProductModel> getProductById(String id);
  Future<void> updateProduct(String id, ProductModel product);
  Future<void> deleteProduct(String id);
  Future<String> uploadProductPhoto(String filePath);
  Future<void> deleteProductPhoto(String fileId);
}
