import 'package:appwrite/appwrite.dart';

import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final Databases _databases = AppwriteService().databases;
  static const String databaseId = 'product_database';
  static const String productsCollectionId = 'product_database';
  static const String variantsCollectionId = 'size_variants';

  @override
  Future<String> createProduct(ProductModel product) async {
    try {
      // 1. Create the main product document (without variants initially)
      final productResponse = await _databases.createDocument(
        databaseId: databaseId,
        collectionId: productsCollectionId,
        documentId: ID.unique(),
        data: product.toJson(),
      );

      final productId = productResponse.data[r'$id'] as String;

      // 2. Create size variants and collect their IDs
      final variantIds = <String>[];
      for (final size in product.sizes) {
        final variantResponse = await _databases.createDocument(
          databaseId: databaseId,
          collectionId: variantsCollectionId,
          documentId: ID.unique(),
          data: size.toJson(),
        );
        variantIds.add(variantResponse.data[r'$id'] as String);
      }

      // 3. Update product with the sizeVariants relationship
      if (variantIds.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: productsCollectionId,
          documentId: productId,
          data: {'sizeVariants': variantIds},
        );
      }

      // 4. Cache the created product
      final createdProduct = ProductModel.fromJson(productResponse.data);
      await CacheService.cacheProduct(
        createdProduct.copyWith(sizes: product.sizes),
      );

      return productId;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getProducts({bool forceRefresh = false}) async {
    try {
      // Get all products with their sizeVariants relationship populated
      final productsResponse = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: productsCollectionId,
        queries: [
          Query.select([
            '\$id',
            'product_name',
            'product_photos',
            'hsn_code',
            'unit',
            'description',
            'sale_tax',
            'purchase_tax',
            'category',
            '\$createdAt',
            '\$updatedAt',
            'sizeVariants.*', // Fetch all fields from related sizeVariants
          ]),
        ],
      );

      final products = productsResponse.documents
          .map((doc) => ProductModel.fromJson(doc.data))
          .toList();

      // Cache products
      for (final product in products) {
        await CacheService.cacheProduct(product);
      }

      return products;
    } catch (e) {
      // Fallback to cache if network fails
      try {
        return CacheService.getCachedProducts();
      } catch (_) {
        rethrow;
      }
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      // Get the product with sizeVariants relationship populated
      final productResponse = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: productsCollectionId,
        documentId: id,
        queries: [
          Query.select([
            '\$id',
            'product_name',
            'product_photos',
            'hsn_code',
            'unit',
            'description',
            'sale_tax',
            'purchase_tax',
            'category',
            '\$createdAt',
            '\$updatedAt',
            'sizeVariants.*', // Fetch all fields from related sizeVariants
          ]),
        ],
      );

      final product = ProductModel.fromJson(productResponse.data);
      return product;
    } catch (e) {
      // Try cache
      final cachedProduct = CacheService.getCachedProduct(id);
      if (cachedProduct != null) {
        return cachedProduct;
      }
      rethrow;
    }
  }

  @override
  Future<void> updateProduct(String id, ProductModel product) async {
    try {
      // 1. Update main product
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: productsCollectionId,
        documentId: id,
        data: product.toJson(),
      );

      // 2. Get existing variant IDs from the product
      final productDoc = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: productsCollectionId,
        documentId: id,
      );
      final existingVariantIds =
          productDoc.data['sizeVariants'] as List<dynamic>?;

      // 3. Delete old variants
      if (existingVariantIds != null && existingVariantIds.isNotEmpty) {
        for (final variantId in existingVariantIds) {
          try {
            await _databases.deleteDocument(
              databaseId: databaseId,
              collectionId: variantsCollectionId,
              documentId: variantId.toString(),
            );
          } catch (e) {
            // Continue if variant already deleted
            continue;
          }
        }
      }

      // 4. Create new variants and collect their IDs
      final newVariantIds = <String>[];
      for (final size in product.sizes) {
        final variantResponse = await _databases.createDocument(
          databaseId: databaseId,
          collectionId: variantsCollectionId,
          documentId: ID.unique(),
          data: size.toJson(),
        );
        newVariantIds.add(variantResponse.data[r'$id'] as String);
      }

      // 5. Update product with new variant IDs
      if (newVariantIds.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: productsCollectionId,
          documentId: id,
          data: {'sizeVariants': newVariantIds},
        );
      }

      // Update cache
      await CacheService.cacheProduct(product.copyWith(id: id));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      // 1. Get variant IDs from the product
      final productDoc = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: productsCollectionId,
        documentId: id,
      );
      final variantIds = productDoc.data['sizeVariants'] as List<dynamic>?;

      // 2. Delete all variants first
      if (variantIds != null && variantIds.isNotEmpty) {
        for (final variantId in variantIds) {
          try {
            await _databases.deleteDocument(
              databaseId: databaseId,
              collectionId: variantsCollectionId,
              documentId: variantId.toString(),
            );
          } catch (e) {
            // Continue if variant already deleted
            continue;
          }
        }
      }

      // 2. Delete the product
      await _databases.deleteDocument(
        databaseId: databaseId,
        collectionId: productsCollectionId,
        documentId: id,
      );

      // Delete from cache
      await CacheService.deleteCachedProduct(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> uploadProductPhoto(String filePath) async {
    // Photo upload to Appwrite Storage can be implemented here
    // For now, return file path
    return filePath;
  }

  @override
  Future<void> deleteProductPhoto(String fileId) async {
    // Photo deletion from Appwrite Storage
  }

  Future<String> getProductPhotoUrl(String fileId) async {
    return fileId;
  }
}
