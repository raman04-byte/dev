import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/models/category_model.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _categoryRepository = CategoryRepositoryImpl();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && !_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final categories = await _categoryRepository.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
      }
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    final minimumDiscountController = TextEditingController();
    String? selectedIcon = 'category';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'Enter category name',
                    prefixIcon: Icon(Icons.label),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minimumDiscountController,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Discount (%)',
                    hintText: 'Enter minimum discount',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedIcon,
                  decoration: const InputDecoration(
                    labelText: 'Icon',
                    prefixIcon: Icon(Icons.palette),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'category',
                      child: Row(
                        children: [
                          Icon(Icons.category),
                          SizedBox(width: 8),
                          Text('Category'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'precision_manufacturing',
                      child: Row(
                        children: [
                          Icon(Icons.precision_manufacturing),
                          SizedBox(width: 8),
                          Text('Manufacturing'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'layers',
                      child: Row(
                        children: [
                          Icon(Icons.layers),
                          SizedBox(width: 8),
                          Text('Layers'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'construction',
                      child: Row(
                        children: [
                          Icon(Icons.construction),
                          SizedBox(width: 8),
                          Text('Construction'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'build',
                      child: Row(
                        children: [
                          Icon(Icons.build),
                          SizedBox(width: 8),
                          Text('Tools'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'inventory',
                      child: Row(
                        children: [
                          Icon(Icons.inventory),
                          SizedBox(width: 8),
                          Text('Inventory'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedIcon = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter category name')),
                  );
                  return;
                }

                final now = DateTime.now();
                final minimumDiscount =
                    minimumDiscountController.text.trim().isNotEmpty
                    ? double.tryParse(minimumDiscountController.text.trim())
                    : null;

                final category = CategoryModel(
                  id: '',
                  name: nameController.text.trim(),
                  image: selectedIcon,
                  createdAt: now,
                  updatedAt: now,
                  minimumDiscount: minimumDiscount,
                );

                try {
                  await _categoryRepository.createCategory(category);
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating category: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadCategories(forceRefresh: true);
    }
  }

  Future<void> _showEditCategoryDialog(CategoryModel category) async {
    final nameController = TextEditingController(text: category.name);
    final minimumDiscountController = TextEditingController(
      text: category.minimumDiscount?.toString() ?? '',
    );
    String? selectedIcon = category.image ?? 'category';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'Enter category name',
                    prefixIcon: Icon(Icons.label),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minimumDiscountController,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Discount (%)',
                    hintText: 'Enter minimum discount',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedIcon,
                  decoration: const InputDecoration(
                    labelText: 'Icon',
                    prefixIcon: Icon(Icons.palette),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'category',
                      child: Row(
                        children: [
                          Icon(Icons.category),
                          SizedBox(width: 8),
                          Text('Category'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'precision_manufacturing',
                      child: Row(
                        children: [
                          Icon(Icons.precision_manufacturing),
                          SizedBox(width: 8),
                          Text('Manufacturing'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'layers',
                      child: Row(
                        children: [
                          Icon(Icons.layers),
                          SizedBox(width: 8),
                          Text('Layers'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'construction',
                      child: Row(
                        children: [
                          Icon(Icons.construction),
                          SizedBox(width: 8),
                          Text('Construction'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'build',
                      child: Row(
                        children: [
                          Icon(Icons.build),
                          SizedBox(width: 8),
                          Text('Tools'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'inventory',
                      child: Row(
                        children: [
                          Icon(Icons.inventory),
                          SizedBox(width: 8),
                          Text('Inventory'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedIcon = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter category name')),
                  );
                  return;
                }

                final minimumDiscount =
                    minimumDiscountController.text.trim().isNotEmpty
                    ? double.tryParse(minimumDiscountController.text.trim())
                    : null;

                final updatedCategory = category.copyWith(
                  name: nameController.text.trim(),
                  image: selectedIcon,
                  updatedAt: DateTime.now(),
                  minimumDiscount: minimumDiscount,
                );

                try {
                  await _categoryRepository.updateCategory(
                    category.id,
                    updatedCategory,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating category: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadCategories(forceRefresh: true);
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _categoryRepository.deleteCategory(category.id);
        _loadCategories(forceRefresh: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting category: $e')),
          );
        }
      }
    }
  }

  IconData _getIconData(String? image) {
    switch (image) {
      case 'precision_manufacturing':
        return Icons.precision_manufacturing;
      case 'layers':
        return Icons.layers;
      case 'construction':
        return Icons.construction;
      case 'build':
        return Icons.build;
      case 'inventory':
        return Icons.inventory;
      default:
        return Icons.category;
    }
  }

  List<CategoryModel> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return _categories;
    }
    return _categories
        .where(
          (category) =>
              category.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddCategoryDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Category',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryBlue.withOpacity(0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search categories...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.primaryBlue,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: AppColors.primaryBlue,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                    ),
                    // Categories List
                    Expanded(
                      child: _filteredCategories.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 64,
                                    color: AppColors.grey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No categories yet'
                                        : 'No categories found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_searchQuery.isEmpty)
                                    Text(
                                      'Tap the + button to add your first category',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = _filteredCategories[index];
                                return _buildCategoryCard(category);
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditCategoryDialog(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(category.image),
                  size: 32,
                  color: AppColors.primaryCyan,
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Updated: ${DateFormat('dd MMM yyyy').format(category.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditCategoryDialog(category);
                  } else if (value == 'delete') {
                    _deleteCategory(category);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: 18,
                          color: AppColors.primaryCyan,
                        ),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
