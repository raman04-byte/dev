import 'package:appwrite/models.dart' as appwrite_models;
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../category/data/repositories/category_repository_impl.dart';
import '../../../category/domain/models/category_model.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  appwrite_models.User? _currentUser;
  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  final _categoryRepository = CategoryRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadCategories();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthRepositoryImpl().getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      // Silently fail - will show empty state or View All only
    }
  }

  bool _isAdmin() {
    if (_currentUser?.labels == null || _currentUser!.labels.isEmpty) {
      return false;
    }
    return _currentUser!.labels.first.toLowerCase() == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: _isAdmin()
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.addProduct);
                  },
                  tooltip: 'Add Product',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'manage_categories') {
                      Navigator.of(context).pushNamed(AppRoutes.category);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'manage_categories',
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings,
                            size: 20,
                            color: AppColors.primaryCyan,
                          ),
                          SizedBox(width: 8),
                          Text('Manage Categories'),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCategoriesView(context),
    );
  }

  Widget _buildCategoriesView(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Categories',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse our product range',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Show actual categories first, then View All
                if (index < _categories.length) {
                  final category = _categories[index];
                  final colors = _getCategoryColors(index);
                  return _buildCategoryCard(
                    context,
                    icon: _getCategoryIcon(category.iconName ?? 'category'),
                    title: category.name,
                    itemCount: '', // Can add product count later
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    categoryId: category.id,
                  );
                } else {
                  // View All card at the end
                  return _buildCategoryCard(
                    context,
                    icon: Icons.category,
                    title: 'View All',
                    itemCount: '',
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.grey.withOpacity(0.6), AppColors.grey],
                    ),
                    isViewAll: true,
                  );
                }
              },
              childCount: _categories.length + 1, // categories + View All
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String itemCount,
    required Gradient gradient,
    bool isViewAll = false,
    String? categoryId,
  }) {
    return InkWell(
      onTap: () {
        if (isViewAll) {
          Navigator.of(context).pushNamed(AppRoutes.allProducts);
        } else {
          // TODO: Navigate to category-specific products page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title category coming soon'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryCyan.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                icon,
                size: 120,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 32, color: AppColors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemCount,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Map icon name string to IconData
  IconData _getCategoryIcon(String iconName) {
    final iconMap = {
      'precision_manufacturing': Icons.precision_manufacturing,
      'layers': Icons.layers,
      'construction': Icons.construction,
      'category': Icons.category,
      'inventory': Icons.inventory,
      'shopping_bag': Icons.shopping_bag,
      'local_shipping': Icons.local_shipping,
      'build': Icons.build,
      'hardware': Icons.hardware,
      'widgets': Icons.widgets,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  // Generate gradient colors based on index
  List<Color> _getCategoryColors(int index) {
    final colorPalette = [
      [AppColors.primaryCyan.withOpacity(0.8), AppColors.primaryCyan],
      [AppColors.primaryNavy.withOpacity(0.7), AppColors.primaryNavy],
      [const Color(0xFF8E24AA).withOpacity(0.8), const Color(0xFF8E24AA)],
      [const Color(0xFFE91E63).withOpacity(0.8), const Color(0xFFE91E63)],
      [const Color(0xFFFF5722).withOpacity(0.8), const Color(0xFFFF5722)],
      [const Color(0xFF4CAF50).withOpacity(0.8), const Color(0xFF4CAF50)],
      [const Color(0xFFFF9800).withOpacity(0.8), const Color(0xFFFF9800)],
      [const Color(0xFF2196F3).withOpacity(0.8), const Color(0xFF2196F3)],
    ];
    return colorPalette[index % colorPalette.length];
  }
}
