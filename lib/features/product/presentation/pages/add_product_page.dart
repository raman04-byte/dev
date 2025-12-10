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

  // Controllers - Only for common fields now
  final _nameController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _saleGstController = TextEditingController();
  final _purchaseGstController = TextEditingController();

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
    _hsnCodeController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _saleGstController.dispose();
    _purchaseGstController.dispose();
    super.dispose();
  }

  void _addSize() {
    showDialog(
      context: context,
      builder: (context) {
        final sizeNameController = TextEditingController();
        final productCodeController = TextEditingController();
        final barcodeController = TextEditingController();
        final mrpController = TextEditingController();
        final stockController = TextEditingController();
        final reorderPointController = TextEditingController();
        final packagingSizeController = TextEditingController();
        final weightController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Size Variant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sizeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Size Name *',
                    hintText: 'e.g., Small, Medium, Large, XL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: productCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Product Code *',
                    hintText: 'e.g., TS-XL-001',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mrpController,
                  decoration: const InputDecoration(
                    labelText: 'MRP *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reorderPointController,
                  decoration: const InputDecoration(
                    labelText: 'Reorder Point *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: packagingSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Packaging Size *',
                    hintText: 'e.g., 1 Piece',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
                    productCodeController.text.isNotEmpty &&
                    barcodeController.text.isNotEmpty &&
                    mrpController.text.isNotEmpty &&
                    stockController.text.isNotEmpty &&
                    reorderPointController.text.isNotEmpty &&
                    packagingSizeController.text.isNotEmpty &&
                    weightController.text.isNotEmpty) {
                  setState(() {
                    _sizes.add(
                      ProductSize(
                        sizeName: sizeNameController.text,
                        productCode: productCodeController.text,
                        barcode: barcodeController.text,
                        mrp: double.parse(mrpController.text),
                        stockQuantity: int.parse(stockController.text),
                        reorderPoint: int.parse(reorderPointController.text),
                        packagingSize: int.parse(packagingSizeController.text),
                        weight: double.parse(weightController.text),
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

      // Create product - using first variant's data for backward compatibility
      final product = ProductModel(
        name: _nameController.text,
        photos: photoIds,
        hsnCode: _hsnCodeController.text,
        unit: _unitController.text,
        description: _descriptionController.text,
        saleGst: double.parse(_saleGstController.text),
        purchaseGst: double.parse(_purchaseGstController.text),
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

                  // Tax Information
                  Text(
                    'Tax Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      ElevatedButton.icon(
                        onPressed: _addSize,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Variant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: AppColors.white,
                        ),
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
                          child: ExpansionTile(
                            title: Text(
                              size.sizeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Code: ${size.productCode} | Price: ₹${size.mrp}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeSize(index),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(
                                      'Product Code',
                                      size.productCode,
                                    ),
                                    _buildDetailRow('Barcode', size.barcode),
                                    _buildDetailRow('MRP', '₹${size.mrp}'),
                                    _buildDetailRow(
                                      'Stock',
                                      '${size.stockQuantity} units',
                                    ),
                                    _buildDetailRow(
                                      'Reorder Point',
                                      '${size.reorderPoint} units',
                                    ),
                                    _buildDetailRow(
                                      'Packaging',
                                      size.packagingSize.toString(),
                                    ),
                                    _buildDetailRow(
                                      'Weight',
                                      '${size.weight} kg',
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                ], // children
              ), // ListView
            ), // Form
    ); // return statement
  } // build method

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
