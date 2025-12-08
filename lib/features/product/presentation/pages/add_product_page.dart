import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../category/data/repositories/category_repository_impl.dart';
import '../../../category/domain/models/category_model.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/models/product_model.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productRepository = ProductRepositoryImpl();
  final _categoryRepository = CategoryRepositoryImpl();
  final _imagePicker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _saleGstController = TextEditingController();
  final _purchaseGstController = TextEditingController();
  final _mrpController = TextEditingController();
  final _reorderPointController = TextEditingController();
  final _packagingSizeController = TextEditingController();

  // State
  final List<ProductSize> _sizes = [];
  final List<File> _selectedPhotos = [];
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // Add dummy data in debug mode
    assert(() {
      _nameController.text = 'Premium Cotton T-Shirt';
      _productCodeController.text = 'PROD-001';
      _barcodeController.text = '1234567890123';
      _hsnCodeController.text = '6109';
      _unitController.text = 'Pcs';
      _descriptionController.text =
          'High-quality cotton t-shirt with premium fabric and comfortable fit. Perfect for everyday wear.';
      _saleGstController.text = '12';
      _purchaseGstController.text = '12';
      _mrpController.text = '599';
      _reorderPointController.text = '20';
      _packagingSizeController.text = '1 Piece per Pack';

      // Add dummy sizes
      _sizes.addAll([
        ProductSize(sizeName: 'Small', price: 499, stock: 50),
        ProductSize(sizeName: 'Medium', price: 549, stock: 75),
        ProductSize(sizeName: 'Large', price: 599, stock: 60),
        ProductSize(sizeName: 'XL', price: 649, stock: 40),
        ProductSize(sizeName: 'XXL', price: 699, stock: 25),
      ]);
      return true;
    }());
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productCodeController.dispose();
    _barcodeController.dispose();
    _hsnCodeController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _saleGstController.dispose();
    _purchaseGstController.dispose();
    _mrpController.dispose();
    _reorderPointController.dispose();
    _packagingSizeController.dispose();
    super.dispose();
  }

  void _addSize() {
    showDialog(
      context: context,
      builder: (context) {
        final sizeNameController = TextEditingController();
        final priceController = TextEditingController();
        final stockController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Size'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sizeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Size Name',
                    hintText: 'e.g., Small, Medium, Large, XL',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (sizeNameController.text.isNotEmpty &&
                    priceController.text.isNotEmpty &&
                    stockController.text.isNotEmpty) {
                  setState(() {
                    _sizes.add(
                      ProductSize(
                        sizeName: sizeNameController.text,
                        price: double.parse(priceController.text),
                        stock: int.parse(stockController.text),
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeSize(int index) {
    setState(() {
      _sizes.removeAt(index);
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedPhotos.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one size variant')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload photos and get their file paths
      List<String> photoIds = [];
      for (final photo in _selectedPhotos) {
        final photoId = await _productRepository.uploadProductPhoto(photo.path);
        photoIds.add(photoId);
      }

      // Create product
      final product = ProductModel(
        name: _nameController.text,
        productCode: _productCodeController.text,
        barcode: _barcodeController.text,
        photos: photoIds,
        hsnCode: _hsnCodeController.text,
        unit: _unitController.text,
        description: _descriptionController.text,
        saleGst: double.parse(_saleGstController.text),
        purchaseGst: double.parse(_purchaseGstController.text),
        mrp: double.parse(_mrpController.text),
        reorderPoint: int.parse(_reorderPointController.text),
        packagingSize: _packagingSizeController.text,
        sizes: _sizes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categoryId: _selectedCategoryId,
      );

      await _productRepository.createProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding product: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Product Photos Section
                  Text(
                    'Product Photos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedPhotos.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedPhotos.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primaryCyan,
                                    width: 2,
                                  ),
                                  image: DecorationImage(
                                    image: FileImage(_selectedPhotos[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 12,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _removePhoto(index),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Photos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryCyan,
                      side: const BorderSide(color: AppColors.primaryCyan),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Basic Information
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _productCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Product Code',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hsnCodeController,
                    decoration: const InputDecoration(
                      labelText: 'HSN Code',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit (e.g., Pcs, Kg, L)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category (Optional)',
                      border: OutlineInputBorder(),
                      helperText: 'Select a category for this product',
                    ),
                    items: _loadingCategories
                        ? []
                        : _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    hint: _loadingCategories
                        ? const Text('Loading categories...')
                        : _categories.isEmpty
                        ? const Text('No categories available')
                        : const Text('Select a category'),
                  ),
                  const SizedBox(height: 24),

                  // Pricing & Tax
                  Text(
                    'Pricing & Tax',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mrpController,
                    decoration: const InputDecoration(
                      labelText: 'MRP',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _saleGstController,
                    decoration: const InputDecoration(
                      labelText: 'Sale GST (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _purchaseGstController,
                    decoration: const InputDecoration(
                      labelText: 'Purchase GST (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Inventory
                  Text(
                    'Inventory',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reorderPointController,
                    decoration: const InputDecoration(
                      labelText: 'Reorder Point',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _packagingSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Packaging Size',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Sizes Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Size Variants',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _addSize,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.primaryCyan,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_sizes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No sizes added yet. Click + to add size variants.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sizes.length,
                      itemBuilder: (context, index) {
                        final size = _sizes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(size.sizeName),
                            subtitle: Text(
                              'Price: ₹${size.price} | Stock: ${size.stock}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeSize(index),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Product',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
