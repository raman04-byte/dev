import 'dart:ui';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../category/data/repositories/category_repository_impl.dart';
import '../../../category/domain/models/category_model.dart';
import 'all_products_page.dart';

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

  Future<void> _refreshData() async {
    await Future.wait([_loadCurrentUser(), _loadCategories()]);
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
      extendBodyBehindAppBar: true,
      appBar: Glassmorphism.appBar(
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        actions: _isAdmin()
            ? [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'manage_categories') {
                        Navigator.of(context).pushNamed(AppRoutes.category);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'manage_categories',
                        child: Row(
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 20,
                              color: AppColors.primaryBlue,
                            ),
                            SizedBox(width: 12),
                            Text('Manage Categories'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            : null,
      ),
      floatingActionButton: _isAdmin()
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.addProduct);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: AppColors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Add Product',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.systemGray6,
              AppColors.white,
              AppColors.primaryBlue.withOpacity(0.02),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: _buildCategoriesView(context),
              ),
      ),
    );
  }

  Widget _buildCategoriesView(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
          sliver: SliverToBoxAdapter(
            child: Glassmorphism.card(
              blur: 15,
              opacity: 0.7,
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Categories',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
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
                    icon: _getCategoryIcon(category.image ?? 'category'),
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
    return Glassmorphism.card(
      blur: 15,
      opacity: 0.5,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        if (isViewAll) {
          Navigator.of(context).pushNamed(AppRoutes.allProducts);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AllProductsPage(categoryId: categoryId, categoryName: title),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Background circle pattern
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.white.withOpacity(0.2),
                            AppColors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 36, color: AppColors.white),
                        ),
                        const Spacer(),
                        // Title
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 8),
                        // Item count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            itemCount,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
