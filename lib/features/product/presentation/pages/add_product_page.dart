import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../category/data/repositories/category_repository_impl.dart';
import '../../../category/domain/models/category_model.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/models/product_model.dart';

class AddProductPage extends StatefulWidget {
  final ProductModel? product; // Optional product for editing

  const AddProductPage({super.key, this.product});

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
  List<String> _existingPhotoIds = []; // For existing product photos
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _populateFieldsIfEditing();
  }

  void _populateFieldsIfEditing() {
    if (widget.product != null) {
      final product = widget.product!;
      _nameController.text = product.name;
      _hsnCodeController.text = product.hsnCode;
      _unitController.text = product.unit;
      _descriptionController.text = product.description;
      _saleGstController.text = product.saleGst.toString();
      _purchaseGstController.text = product.purchaseGst.toString();
      _selectedCategoryId = product.categoryId;
      _sizes.addAll(product.sizes);
      _existingPhotoIds = List.from(product.photos);
    }
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

  void _editSize(int index) {
    final size = _sizes[index];
    showDialog(
      context: context,
      builder: (context) {
        final sizeNameController = TextEditingController(text: size.sizeName);
        final productCodeController = TextEditingController(
          text: size.productCode,
        );
        final barcodeController = TextEditingController(text: size.barcode);
        final mrpController = TextEditingController(text: size.mrp.toString());
        final stockController = TextEditingController(
          text: size.stockQuantity.toString(),
        );
        final reorderPointController = TextEditingController(
          text: size.reorderPoint.toString(),
        );
        final packagingSizeController = TextEditingController(
          text: size.packagingSize.toString(),
        );
        final weightController = TextEditingController(
          text: size.weight.toString(),
        );

        return AlertDialog(
          title: const Text('Edit Size Variant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sizeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Size Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: productCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Product Code *',
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
                    productCodeController.text.isNotEmpty &&
                    barcodeController.text.isNotEmpty &&
                    mrpController.text.isNotEmpty &&
                    stockController.text.isNotEmpty &&
                    reorderPointController.text.isNotEmpty &&
                    packagingSizeController.text.isNotEmpty &&
                    weightController.text.isNotEmpty) {
                  setState(() {
                    _sizes[index] = ProductSize(
                      id: size.id,
                      sizeName: sizeNameController.text,
                      productCode: productCodeController.text,
                      barcode: barcodeController.text,
                      mrp: double.parse(mrpController.text),
                      stockQuantity: int.parse(stockController.text),
                      reorderPoint: int.parse(reorderPointController.text),
                      packagingSize: int.parse(packagingSizeController.text),
                      weight: double.parse(weightController.text),
                      productId: size.productId,
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
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

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotoIds.removeAt(index);
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
      // Upload new photos and get their file paths
      List<String> newPhotoIds = [];
      for (final photo in _selectedPhotos) {
        final photoId = await _productRepository.uploadProductPhoto(photo.path);
        newPhotoIds.add(photoId);
      }

      // Combine existing and new photo IDs
      final allPhotoIds = [..._existingPhotoIds, ...newPhotoIds];

      final product = ProductModel(
        id: widget.product?.id,
        name: _nameController.text,
        photos: allPhotoIds,
        hsnCode: _hsnCodeController.text,
        unit: _unitController.text,
        description: _descriptionController.text,
        saleGst: double.parse(_saleGstController.text),
        purchaseGst: double.parse(_purchaseGstController.text),
        sizes: _sizes,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        categoryId: _selectedCategoryId,
      );

      if (widget.product != null) {
        // Update existing product
        await _productRepository.updateProduct(widget.product!.id!, product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully!')),
          );
        }
      } else {
        // Create new product
        await _productRepository.createProduct(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully!')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${widget.product != null ? "updating" : "adding"} product: $e',
            ),
          ),
        );
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
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
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
                  if (_existingPhotoIds.isNotEmpty ||
                      _selectedPhotos.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            _existingPhotoIds.length + _selectedPhotos.length,
                        itemBuilder: (context, index) {
                          final isExistingPhoto =
                              index < _existingPhotoIds.length;

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
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: isExistingPhoto
                                      ? Image.network(
                                          _productRepository.getProductPhotoUrl(
                                                _existingPhotoIds[index],
                                              )
                                              as String,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                  ),
                                                );
                                              },
                                        )
                                      : Image.file(
                                          _selectedPhotos[index -
                                              _existingPhotoIds.length],
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
                                  onPressed: () => isExistingPhoto
                                      ? _removeExistingPhoto(index)
                                      : _removePhoto(
                                          index - _existingPhotoIds.length,
                                        ),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppColors.primaryCyan,
                                  ),
                                  onPressed: () => _editSize(index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeSize(index),
                                ),
                              ],
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
                    child: Text(
                      widget.product != null
                          ? 'Update Product'
                          : 'Save Product',
                      style: const TextStyle(
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
