import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../category/data/repositories/category_repository_impl.dart';
import '../../../category/domain/models/category_model.dart';
import '../../../product/data/repositories/product_repository_impl.dart';
import '../../../product/domain/models/product_model.dart';
import '../../data/repositories/vendor_repository_impl.dart';
import '../../domain/models/vendor_model.dart';

class AllVendorsPage extends StatefulWidget {
  const AllVendorsPage({super.key});

  @override
  State<AllVendorsPage> createState() => _AllVendorsPageState();
}

class _AllVendorsPageState extends State<AllVendorsPage> {
  final _repository = VendorRepositoryImpl();
  final _categoryRepository = CategoryRepositoryImpl();
  final _productRepository = ProductRepositoryImpl();
  final _searchController = TextEditingController();
  List<VendorModel> _vendors = [];
  List<VendorModel> _filteredVendors = [];
  Map<String, List<VendorModel>> _vendorsByState = {};
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  final Set<String> _expandedStates = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVendors();
    _loadCategories();
    _loadProducts();
    _searchController.addListener(_filterVendors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterVendors() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredVendors = _vendors;
        _updateVendorsByState(_vendors);
      });
      return;
    }

    final filtered = _vendors.where((vendor) {
      // Basic vendor fields
      if (vendor.name.toLowerCase().contains(query) ||
          vendor.address.toLowerCase().contains(query) ||
          vendor.pincode.toLowerCase().contains(query) ||
          vendor.district.toLowerCase().contains(query) ||
          vendor.state.toLowerCase().contains(query) ||
          vendor.gstNo.toLowerCase().contains(query) ||
          vendor.mobileNumber.toLowerCase().contains(query) ||
          vendor.email.toLowerCase().contains(query) ||
          vendor.salesPersonName.toLowerCase().contains(query) ||
          vendor.salesPersonContact.toLowerCase().contains(query)) {
        return true;
      }

      // Search in product variant prices
      for (var productEntry in vendor.productVariantPrices.entries) {
        final productId = productEntry.key;
        final product = _products.firstWhere(
          (p) => p.id == productId,
          orElse: () => ProductModel(
            id: '',
            name: '',
            photos: [],
            hsnCode: '',
            unit: '',
            description: '',
            saleGst: 0,
            purchaseGst: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Search by product name
        if (product.name.toLowerCase().contains(query)) {
          return true;
        }

        // Search by HSN code
        if (product.hsnCode.toLowerCase().contains(query)) {
          return true;
        }

        // Search in variants and prices
        for (var variantEntry in productEntry.value.entries) {
          final variantId = variantEntry.key;
          final variantData = variantEntry.value;

          // Find the variant in product sizes
          final variantIndex = product.sizes.indexWhere(
            (v) => v.id == variantId,
          );

          if (variantIndex != -1) {
            final variant = product.sizes[variantIndex];

            // Search by variant name
            if (variant.sizeName.toLowerCase().contains(query)) {
              return true;
            }

            // Search by variant MRP
            if (variant.mrp.toString().contains(query)) {
              return true;
            }
          }

          // Search by price
          final price = variantData is Map ? variantData['price'] : variantData;
          if (price != null && price.toString().contains(query)) {
            return true;
          }
        }
      }

      return false;
    }).toList();

    setState(() {
      _filteredVendors = filtered;
      _updateVendorsByState(filtered);
    });
  }

  void _updateVendorsByState(List<VendorModel> vendors) {
    final Map<String, List<VendorModel>> vendorsByState = {};
    for (var vendor in vendors) {
      if (!vendorsByState.containsKey(vendor.state)) {
        vendorsByState[vendor.state] = [];
      }
      vendorsByState[vendor.state]!.add(vendor);
    }

    final sortedKeys = vendorsByState.keys.toList()..sort();
    _vendorsByState = {for (var key in sortedKeys) key: vendorsByState[key]!};
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // Silently fail for categories
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productRepository.getProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      // Silently fail for products
    }
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vendors = await _repository.getAllVendors();

      // Group vendors by state
      final Map<String, List<VendorModel>> vendorsByState = {};
      for (var vendor in vendors) {
        if (!vendorsByState.containsKey(vendor.state)) {
          vendorsByState[vendor.state] = [];
        }
        vendorsByState[vendor.state]!.add(vendor);
      }

      // Sort states alphabetically
      final sortedKeys = vendorsByState.keys.toList()..sort();
      final sortedMap = {for (var key in sortedKeys) key: vendorsByState[key]!};

      setState(() {
        _vendors = vendors;
        _filteredVendors = vendors;
        _vendorsByState = sortedMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getCategoryName(String categoryId) {
    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryModel(
        id: categoryId,
        name: 'Unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return category.name;
  }

  String _getProductName(String productId) {
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => ProductModel(
        id: productId,
        name: 'Unknown',
        photos: [],
        hsnCode: '',
        unit: '',
        description: '',
        saleGst: 0,
        purchaseGst: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return product.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: AppColors.white.withOpacity(0.7),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                color: AppColors.textPrimary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'All Vendors',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'extract_to_excel') {
                        _showExcelExportDialog();
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.primaryBlue,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'extract_to_excel',
                        child: Row(
                          children: [
                            Icon(
                              Icons.table_chart,
                              size: 20,
                              color: AppColors.primaryBlue,
                            ),
                            SizedBox(width: 12),
                            Text('Extract to Excel'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.primaryBlue,
                  onPressed: _loadVendors,
                ),
              ],
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Glassmorphism.card(
                    blur: 15,
                    opacity: 0.7,
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.accentPink,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading vendors',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadVendors,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _filteredVendors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No vendors found',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search vendors...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // Vendor List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _vendorsByState.length,
                        itemBuilder: (context, index) {
                          final state = _vendorsByState.keys.elementAt(index);
                          final vendors = _vendorsByState[state]!;
                          final isExpanded = _expandedStates.contains(state);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Glassmorphism.card(
                              blur: 15,
                              opacity: 0.8,
                              padding: const EdgeInsets.all(16),
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (isExpanded) {
                                          _expandedStates.remove(state);
                                        } else {
                                          _expandedStates.add(state);
                                        }
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            state,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBlue
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${vendors.length}',
                                            style: const TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                    .keyboard_arrow_down_rounded,
                                          color: AppColors.textPrimary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Column(
                                      children: [
                                        const SizedBox(height: 12),
                                        const Divider(),
                                        ...vendors.map((vendor) {
                                          return _buildVendorCard(vendor);
                                        }),
                                      ],
                                    ),
                                    crossFadeState: isExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 300),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildVendorCard(VendorModel vendor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showVendorDetails(vendor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vendor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: AppColors.primaryBlue,
                        onPressed: () => _navigateToEdit(vendor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: AppColors.accentPink,
                        onPressed: () => _confirmDelete(vendor),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    vendor.mobileNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (vendor.email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.email,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        vendor.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (vendor.salesPersonName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sales: ${vendor.salesPersonName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              if (vendor.productDiscounts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: vendor.productDiscounts.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_getCategoryName(entry.key)}: ${entry.value}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showVendorDetails(VendorModel vendor) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vendor.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.location_on, 'Address', vendor.address),
                _buildDetailRow(Icons.pin_drop, 'Pincode', vendor.pincode),
                _buildDetailRow(
                  Icons.location_city,
                  'District',
                  vendor.district,
                ),
                _buildDetailRow(Icons.map, 'State', vendor.state),
                if (vendor.gstNo.isNotEmpty)
                  _buildDetailRow(Icons.receipt_long, 'GST No', vendor.gstNo),
                _buildDetailRow(Icons.phone, 'Mobile', vendor.mobileNumber),
                if (vendor.email.isNotEmpty)
                  _buildDetailRow(Icons.email, 'Email', vendor.email),
                if (vendor.salesPersonName.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Sales Person',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.person, 'Name', vendor.salesPersonName),
                  if (vendor.salesPersonContact.isNotEmpty)
                    _buildDetailRow(
                      Icons.phone_android,
                      'Contact',
                      vendor.salesPersonContact,
                    ),
                ],
                if (vendor.productDiscounts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Product Discounts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...vendor.productDiscounts.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getCategoryName(entry.key),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${entry.value}%',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.accentGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                if (vendor.productIds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vendor.productIds.map((productId) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getProductName(productId),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit(VendorModel vendor) async {
    final result = await Navigator.pushNamed(
      context,
      '/crm/add-vendor',
      arguments: vendor,
    );

    if (result == true) {
      _loadVendors();
    }
  }

  Future<void> _confirmDelete(VendorModel vendor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: Text('Are you sure you want to delete ${vendor.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentPink),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteVendor(vendor);
    }
  }

  Future<void> _deleteVendor(VendorModel vendor) async {
    try {
      await _repository.deleteVendor(vendor.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendor deleted successfully'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
      _loadVendors();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting vendor: $e'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    }
  }

  Future<void> _showExcelExportDialog() async {
    final Map<String, bool> selectedFields = {
      'Vendor Name': true,
      'Address': true,
      'Pincode': true,
      'District': true,
      'State': true,
      'GST Number': true,
      'Mobile Number': true,
      'Email': true,
      'Sales Person Name': true,
      'Sales Person Contact': true,
      'Created At': true,
      'Updated At': true,
    };

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.table_chart,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Export to Excel'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select fields to include in export:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          selectedFields.updateAll((key, value) => true);
                        });
                      },
                      icon: const Icon(Icons.check_box),
                      label: const Text('Select All'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          selectedFields.updateAll((key, value) => false);
                        });
                      },
                      icon: const Icon(Icons.check_box_outline_blank),
                      label: const Text('Deselect All'),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: selectedFields.keys.map((field) {
                        return CheckboxListTile(
                          title: Text(field),
                          value: selectedFields[field],
                          onChanged: (bool? value) {
                            setDialogState(() {
                              selectedFields[field] = value ?? false;
                            });
                          },
                          activeColor: AppColors.primaryBlue,
                          dense: true,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (selectedFields.values.any((v) => v)) {
                  Navigator.pop(context, true);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.excelExportVendors,
                    arguments: selectedFields,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one field'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
