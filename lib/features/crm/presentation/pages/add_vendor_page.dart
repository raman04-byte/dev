import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../category/data/repositories/category_repository_impl.dart';
import '../../../category/domain/models/category_model.dart';
import '../../../product/data/repositories/product_repository_impl.dart';
import '../../../product/domain/models/product_model.dart';
import '../../data/repositories/vendor_repository_impl.dart';
import '../../domain/models/vendor_model.dart';

class AddVendorPage extends StatefulWidget {
  const AddVendorPage({super.key});

  @override
  State<AddVendorPage> createState() => _AddVendorPageState();
}

class _AddVendorPageState extends State<AddVendorPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = VendorRepositoryImpl();
  final _productRepository = ProductRepositoryImpl();
  final _categoryRepository = CategoryRepositoryImpl();

  // Basic Information Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _gstNoController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _salesPersonNameController = TextEditingController();
  final _salesPersonContactController = TextEditingController();

  bool _isLoadingPincode = false;
  bool _isSaving = false;
  bool _isLoadingProducts = true;
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  final Set<String> _selectedProductIds = {};
  final Set<String> _expandedCategoryIds = {}; // Track expanded categories

  // Map<productId, Map<variantId, priceController>>
  final Map<String, Map<String, TextEditingController>>
  _variantPriceControllers = {};

  VendorModel? _editingVendor;
  bool get _isEditing => _editingVendor != null;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get vendor from route arguments if editing
    final vendor = ModalRoute.of(context)?.settings.arguments as VendorModel?;
    if (vendor != null && _editingVendor == null) {
      _editingVendor = vendor;
      _populateFields(vendor);
    }
  }

  void _populateFields(VendorModel vendor) {
    _nameController.text = vendor.name;
    _addressController.text = vendor.address;
    _pincodeController.text = vendor.pincode;
    _districtController.text = vendor.district;
    _stateController.text = vendor.state;
    _gstNoController.text = vendor.gstNo;
    _mobileController.text = vendor.mobileNumber;
    _emailController.text = vendor.email;
    _salesPersonNameController.text = vendor.salesPersonName;
    _salesPersonContactController.text = vendor.salesPersonContact;
    _selectedProductIds.clear();
    _selectedProductIds.addAll(vendor.productIds);

    // Populate variant prices
    _variantPriceControllers.clear();
    for (var entry in vendor.productVariantPrices.entries) {
      final productId = entry.key;
      for (var variantEntry in entry.value.entries) {
        final variantId = variantEntry.key;
        final variantData = variantEntry.value;

        // Extract price from the nested map structure
        final price = variantData is Map ? variantData['price'] : variantData;

        if (!_variantPriceControllers.containsKey(productId)) {
          _variantPriceControllers[productId] = {};
        }
        if (!_variantPriceControllers[productId]!.containsKey(variantId)) {
          _variantPriceControllers[productId]![variantId] =
              TextEditingController();
        }
        _variantPriceControllers[productId]![variantId]!.text = price
            .toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _gstNoController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _salesPersonNameController.dispose();
    _salesPersonContactController.dispose();
    for (var productControllers in _variantPriceControllers.values) {
      for (var controller in productControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final products = await _productRepository.getProducts();
      final categories = await _categoryRepository.getCategories();
      setState(() {
        _products = products;
        _categories = categories;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    }
  }

  Future<void> _fetchPincodeDetails(String pincode) async {
    if (pincode.length != 6) return;

    setState(() {
      _isLoadingPincode = true;
    });

    try {
      final details = await _repository.getPincodeDetails(pincode);
      if (details != null) {
        setState(() {
          _districtController.text = details['district'] ?? '';
          _stateController.text = details['state'] ?? '';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid pincode or details not found'),
              backgroundColor: AppColors.accentPink,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching pincode details: $e'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingPincode = false;
      });
    }
  }

  Future<void> _saveVendor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Collect selected categories from selected products
      final selectedCategories = <String>{};
      for (var productId in _selectedProductIds) {
        final product = _products.firstWhere((p) => p.id == productId);
        if (product.categoryId != null) {
          selectedCategories.add(product.categoryId!);
        }
      }

      // Build product variant prices map with name and MRP
      final Map<String, Map<String, dynamic>> productVariantPrices = {};
      for (var productId in _selectedProductIds) {
        final variantControllers = _variantPriceControllers[productId];
        final product = _products.firstWhere((p) => p.id == productId);

        if (variantControllers != null) {
          for (var entry in variantControllers.entries) {
            final variantId = entry.key;
            final priceText = entry.value.text.trim();

            if (priceText.isNotEmpty) {
              final price = double.tryParse(priceText);
              if (price != null && price > 0) {
                // Find the variant to get its name and MRP
                final variant = product.sizes.firstWhere(
                  (v) => v.id == variantId,
                );

                // Find category to get minimum discount
                final category = _categories.firstWhere(
                  (cat) => cat.id == product.categoryId,
                  orElse: () => _categories.first,
                );
                final minimumDiscount = category.minimumDiscount ?? 0.0;
                final minimumRetailPrice =
                    variant.mrp * (1 - (minimumDiscount / 100));

                if (!productVariantPrices.containsKey(productId)) {
                  productVariantPrices[productId] = {};
                }
                productVariantPrices[productId]![variantId] = {
                  'price': price,
                  'mrp': variant.mrp,
                  'name': variant.sizeName,
                  'minimumRetailPrice': minimumRetailPrice,
                  'minimumDiscount': minimumDiscount,
                };
              }
            }
          }
        }
      }

      final vendor = VendorModel(
        id: _editingVendor?.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        pincode: _pincodeController.text.trim(),
        district: _districtController.text.trim(),
        state: _stateController.text.trim(),
        gstNo: _gstNoController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        salesPersonName: _salesPersonNameController.text.trim(),
        salesPersonContact: _salesPersonContactController.text.trim(),
        productIds: _selectedProductIds.toList(),
        categoryIds: selectedCategories.toList(),
        productVariantPrices: productVariantPrices,
        createdAt: _editingVendor?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await _repository.updateVendor(_editingVendor!.id!, vendor);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vendor updated successfully'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      } else {
        await _repository.createVendor(vendor);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vendor created successfully'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving vendor: $e'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vendor' : 'Add Vendor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.3),
                    AppColors.secondaryBlue.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.systemGray6,
              AppColors.white,
              AppColors.primaryBlue.withOpacity(0.02),
              AppColors.white,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              children: [
                _buildBasicInformation(),
                const SizedBox(height: 20),
                _buildSalesPersonSection(),
                const SizedBox(height: 20),
                _buildProductsSection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInformation() {
    return Glassmorphism.card(
      blur: 15,
      opacity: 0.7,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vendor Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _nameController,
            label: 'Vendor Name',
            icon: Icons.business_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter vendor name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _pincodeController,
            label: 'Pincode',
            icon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            suffix: _isLoadingPincode
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onChanged: (value) {
              if (value.length == 6) {
                _fetchPincodeDetails(value);
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter pincode';
              }
              if (value.length != 6) {
                return 'Pincode must be 6 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _districtController,
            label: 'District',
            icon: Icons.maps_home_work_outlined,
            readOnly: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'District will be auto-filled from pincode';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _stateController,
            label: 'State',
            icon: Icons.location_city_outlined,
            readOnly: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'State will be auto-filled from pincode';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _gstNoController,
            label: 'GST Number',
            icon: Icons.receipt_long_outlined,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [LengthLimitingTextInputFormatter(15)],
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (value.length != 15) {
                  return 'GST number must be 15 characters';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _mobileController,
            label: 'Mobile Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter mobile number';
              }
              if (value.length != 10) {
                return 'Mobile number must be 10 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSalesPersonSection() {
    return Glassmorphism.card(
      blur: 15,
      opacity: 0.7,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Person',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _salesPersonNameController,
            label: 'Sales Person Name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _salesPersonContactController,
            label: 'Contact Number',
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (value.length != 10) {
                  return 'Contact number must be 10 digits';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Glassmorphism.card(
      blur: 15,
      opacity: 0.7,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Products with Variants & Prices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoadingProducts)
            const Center(child: CircularProgressIndicator())
          else if (_products.isEmpty)
            Text(
              'No products available',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            )
          else
            ..._categories.map((category) => _buildCategorySection(category)),
        ],
      ),
    );
  }

  Widget _buildCategorySection(CategoryModel category) {
    // Filter products for this category
    final categoryProducts = _products
        .where((product) => product.categoryId == category.id)
        .toList();

    if (categoryProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    final isExpanded = _expandedCategoryIds.contains(category.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header - Tappable to expand/collapse
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedCategoryIds.remove(category.id);
              } else {
                _expandedCategoryIds.add(category.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isExpanded
                  ? AppColors.primaryBlue.withOpacity(0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: AppColors.primaryBlue,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${categoryProducts.length} products',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable products list
        if (isExpanded) ...[
          const SizedBox(height: 8),
          ...categoryProducts.map(
            (product) => _buildExpandableProductCard(product),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExpandableProductCard(ProductModel product) {
    final isSelected = _selectedProductIds.contains(product.id);

    // Ensure controllers exist for all variants
    if (!_variantPriceControllers.containsKey(product.id)) {
      _variantPriceControllers[product.id!] = {};
    }
    for (var variant in product.sizes) {
      if (!_variantPriceControllers[product.id]!.containsKey(variant.id)) {
        _variantPriceControllers[product.id]![variant.id!] =
            TextEditingController();
      }
    }

    // Count prices entered
    int pricesEntered = 0;
    if (_variantPriceControllers.containsKey(product.id)) {
      for (var controller in _variantPriceControllers[product.id]!.values) {
        if (controller.text.trim().isNotEmpty) {
          pricesEntered++;
        }
      }
    }
    final totalVariants = product.sizes.length;

    return InkWell(
      onTap: () {
        _showProductVariantsDialog(product);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.05)
              : AppColors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue.withOpacity(0.3)
                : AppColors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedProductIds.add(product.id!);
                  } else {
                    _selectedProductIds.remove(product.id);
                  }
                });
              },
              activeColor: AppColors.primaryBlue,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HSN: ${product.hsnCode} | ${product.sizes.length} variants',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if ((_isEditing || isSelected) && pricesEntered > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: pricesEntered == totalVariants
                      ? AppColors.accentGreen.withOpacity(0.15)
                      : AppColors.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pricesEntered == totalVariants
                        ? AppColors.accentGreen.withOpacity(0.4)
                        : AppColors.primaryBlue.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$pricesEntered/$totalVariants',
                  style: TextStyle(
                    color: pricesEntered == totalVariants
                        ? AppColors.accentGreen
                        : AppColors.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Icon(
              Icons.edit_outlined,
              color: AppColors.primaryBlue.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showProductVariantsDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'HSN: ${product.hsnCode}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Variants List
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  shrinkWrap: true,
                  itemCount: product.sizes.length,
                  itemBuilder: (context, index) {
                    final variant = product.sizes[index];
                    final controller =
                        _variantPriceControllers[product.id]![variant.id]!;
                    final isPrefilled =
                        _isEditing &&
                        _editingVendor!.productVariantPrices[product.id]
                                ?.containsKey(variant.id) ==
                            true;

                    return _buildVariantCard(
                      product,
                      variant,
                      controller,
                      isPrefilled,
                    );
                  },
                ),
              ),
              // Done Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {}); // Refresh to update progress
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariantCard(
    ProductModel product,
    ProductSize variant,
    TextEditingController controller,
    bool isPrefilled,
  ) {
    // Find category to get minimum discount
    final category = _categories.firstWhere(
      (cat) => cat.id == product.categoryId,
      orElse: () => _categories.first,
    );
    final minimumDiscount = category.minimumDiscount ?? 0.0;
    final minimumRetailPrice = variant.mrp * (1 - (minimumDiscount / 100));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrefilled
            ? AppColors.accentGreen.withOpacity(0.05)
            : AppColors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPrefilled
              ? AppColors.accentGreen.withOpacity(0.3)
              : AppColors.primaryBlue.withOpacity(0.15),
          width: isPrefilled ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Variant info
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: isPrefilled
                    ? AppColors.accentGreen
                    : AppColors.primaryBlue.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  variant.sizeName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isPrefilled)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: AppColors.accentGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Saved',
                        style: TextStyle(
                          color: AppColors.accentGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // MRP and Minimum Retail Price Display
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maximum Retail Price',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${variant.mrp.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accentGreen.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minimum Retail (${minimumDiscount.toStringAsFixed(0)}% off)',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${minimumRetailPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.accentGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price input with profit display inside
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final purchasePrice =
                  double.tryParse(controller.text.trim()) ?? 0.0;
              final profit = minimumRetailPrice - purchasePrice;
              final hasValue =
                  controller.text.trim().isNotEmpty && purchasePrice > 0;

              return TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Your Purchase Price',
                  labelStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.currency_rupee,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                  suffixIcon: hasValue
                      ? Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${profit > 0 ? '+' : '-'}₹${profit.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: profit > 0
                                      ? AppColors.accentGreen
                                      : Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.white.withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _saveVendor,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? 'Update Vendor' : 'Save Vendor',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    bool readOnly = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      readOnly: readOnly,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.systemGray4.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.systemGray4.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentPink),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentPink, width: 2),
        ),
      ),
    );
  }
}
