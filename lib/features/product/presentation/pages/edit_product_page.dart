import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/models/product_model.dart';

class EditProductPage extends StatefulWidget {
  final ProductModel product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productRepository = ProductRepositoryImpl();
  final _imagePicker = ImagePicker();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _productCodeController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _hsnCodeController;
  late final TextEditingController _unitController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _saleGstController;
  late final TextEditingController _purchaseGstController;
  late final TextEditingController _mrpController;
  late final TextEditingController _reorderPointController;
  late final TextEditingController _packagingSizeController;

  // State
  late List<ProductSize> _sizes;
  late List<String> _existingPhotoIds;
  final List<File> _newPhotos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product data
    _nameController = TextEditingController(text: widget.product.name);
    _hsnCodeController = TextEditingController(text: widget.product.hsnCode);
    _unitController = TextEditingController(text: widget.product.unit);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _saleGstController = TextEditingController(
      text: widget.product.saleGst.toString(),
    );
    _purchaseGstController = TextEditingController(
      text: widget.product.purchaseGst.toString(),
    );

    // Initialize sizes and photos
    _sizes = List.from(widget.product.sizes);
    _existingPhotoIds = List.from(widget.product.photos);
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

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _newPhotos.addAll(images.map((img) => File(img.path)));
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

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotoIds.removeAt(index);
    });
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
    });
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
                    // _sizes.add(
                    //   ProductSize(
                    //     sizeName: sizeNameController.text,
                    //     price: double.parse(priceController.text),
                    //     stock: int.parse(stockController.text),
                    //   ),
                    // );
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

  void _editSize(int index) {
    final size = _sizes[index];
    showDialog(
      context: context,
      builder: (context) {
        final sizeNameController = TextEditingController(text: size.sizeName);
        final priceController = TextEditingController(
          text: size.mrp.toString(),
        );
        final stockController = TextEditingController(
          text: size.stockQuantity.toString(),
        );

        return AlertDialog(
          title: const Text('Edit Size'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sizeNameController,
                  decoration: const InputDecoration(labelText: 'Size Name'),
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
                  // setState(() {
                  //   _sizes[index] = ProductSize(
                  //     sizeName: sizeNameController.text,
                  //     price: double.parse(priceController.text),
                  //     stock: int.parse(stockController.text),
                  //   );
                  // });
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

  void _removeSize(int index) {
    setState(() {
      _sizes.removeAt(index);
    });
  }

  Future<void> _updateProduct() async {
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
      // Upload new photos
      List<String> newPhotoIds = [];
      for (final photo in _newPhotos) {
        final photoId = await _productRepository.uploadProductPhoto(photo.path);
        newPhotoIds.add(photoId);
      }

      // Combine existing and new photo IDs
      final allPhotoIds = [..._existingPhotoIds, ...newPhotoIds];

      // Update product
      final updatedProduct = ProductModel(
        id: widget.product.id,
        name: _nameController.text,
        photos: allPhotoIds,
        hsnCode: _hsnCodeController.text,
        unit: _unitController.text,
        description: _descriptionController.text,
        saleGst: double.parse(_saleGstController.text),
        purchaseGst: double.parse(_purchaseGstController.text),
        sizes: _sizes,
        createdAt: widget.product.createdAt,
        updatedAt: DateTime.now(),
      );

      await _productRepository.updateProduct(
        widget.product.id!,
        updatedProduct,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating product: $e')));
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
        title: const Text('Edit Product'),
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
                  if (_existingPhotoIds.isNotEmpty || _newPhotos.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Existing photos
                          ..._existingPhotoIds.asMap().entries.map((entry) {
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
                                    color: AppColors.grey.withOpacity(0.3),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 40,
                                      color: AppColors.primaryCyan,
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
                                    onPressed: () =>
                                        _removeExistingPhoto(entry.key),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          // New photos
                          ..._newPhotos.asMap().entries.map((entry) {
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
                                      image: FileImage(entry.value),
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
                                    onPressed: () => _removeNewPhoto(entry.key),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add More Photos'),
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
                              'Price: ₹${size.mrp} | Stock: ${size.stockQuantity}',
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
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 32),

                  // Update Button
                  ElevatedButton(
                    onPressed: _updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Update Product',
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
