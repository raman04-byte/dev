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
                final category = CategoryModel(
                  id: '',
                  name: nameController.text.trim(),
                  image: selectedIcon,
                  createdAt: now,
                  updatedAt: now,
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

                final updatedCategory = category.copyWith(
                  name: nameController.text.trim(),
                  image: selectedIcon,
                  updatedAt: DateTime.now(),
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
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        backgroundColor: AppColors.primaryCyan,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              if (_searchQuery.isEmpty)
                                Text(
                                  'Tap the + button to add your first category',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = _filteredCategories[index];
                            return _buildCategoryCard(category);
                          },
                        ),
                ),
              ],
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
