import '../../../../core/services/cache_service.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<String> createProduct(ProductModel product) async {
    // Generate a unique ID for the product using timestamp
    final productId =
        'product_${DateTime.now().millisecondsSinceEpoch}_${product.productCode}';

    // Create product with ID
    final createdProduct = product.copyWith(id: productId);

    // Save only to local cache (Hive)
    await CacheService.cacheProduct(createdProduct);

    return productId;
  }

  @override
  Future<List<ProductModel>> getProducts({bool forceRefresh = false}) async {
    // Get products from local cache only
    return CacheService.getCachedProducts();
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    // Get product from local cache only
    final cachedProduct = CacheService.getCachedProduct(id);
    if (cachedProduct != null) {
      return cachedProduct;
    }
    throw Exception('Product not found');
  }

  @override
  Future<void> updateProduct(String id, ProductModel product) async {
    // Update in local cache only
    final updatedProduct = product.copyWith(id: id, updatedAt: DateTime.now());
    await CacheService.cacheProduct(updatedProduct);
  }

  @override
  Future<void> deleteProduct(String id) async {
    // Delete from local cache only
    await CacheService.deleteCachedProduct(id);
  }

  @override
  Future<String> uploadProductPhoto(String filePath) async {
    // Store photo path locally (for future upload to Appwrite)
    // For now, just return the local file path as ID
    return filePath;
  }

  @override
  Future<void> deleteProductPhoto(String fileId) async {
    // Photo deletion will be implemented when syncing with Appwrite
    // For now, do nothing as photos are stored locally
  }

  Future<String> getProductPhotoUrl(String fileId) async {
    // Return local file path for now
    return fileId;
  }
}
