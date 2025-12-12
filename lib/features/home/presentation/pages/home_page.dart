import 'dart:ui';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  appwrite_models.User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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

  String _getUserRole() {
    if (_currentUser?.labels == null || _currentUser!.labels.isEmpty) {
      return 'employee';
    }
    return _currentUser!.labels.first.toLowerCase();
  }

  bool _canAccessModule(String module) {
    // Products is available to everyone
    if (module.toLowerCase() == 'products') {
      return true;
    }

    // Other modules require login
    if (_currentUser == null) {
      return false;
    }

    final role = _getUserRole();
    if (role == 'admin') {
      return true;
    }
    // Employee can only access Voucher and Employee modules
    return ['voucher', 'employee'].contains(module.toLowerCase());
  }

  Future<void> _handleLogin(BuildContext context) async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.login);
    if (result == true && mounted) {
      // Reload user after successful login
      _loadCurrentUser();
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthRepositoryImpl().logout();
      if (context.mounted) {
        setState(() {
          _currentUser = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Dev Polymer',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.white.withOpacity(0.7),
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              shape: const Border(
                bottom: BorderSide(color: AppColors.systemGray5, width: 0.5),
              ),
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.primaryBlue,
                  ),
                  onPressed: () {},
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      _handleLogout(context);
                    } else if (value == 'login') {
                      _handleLogin(context);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  icon: Container(
                    // margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  itemBuilder: (BuildContext context) {
                    return [
                      if (_currentUser == null)
                        const PopupMenuItem<String>(
                          value: 'login',
                          child: Row(
                            children: [
                              Icon(
                                Icons.login_rounded,
                                color: AppColors.primaryBlue,
                              ),
                              SizedBox(width: 12),
                              Text('Login'),
                            ],
                          ),
                        )
                      else
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: AppColors.accentPink,
                              ),
                              SizedBox(width: 12),
                              Text('Logout'),
                            ],
                          ),
                        ),
                    ];
                  },
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
              AppColors.primaryBlue.withOpacity(0.03),
              AppColors.white,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                    sliver: SliverToBoxAdapter(
                      child: Glassmorphism.card(
                        blur: 15,
                        opacity: 0.7,
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentUser != null
                                  ? 'Welcome back, ${_currentUser!.name}'
                                  : 'Welcome to Dev Polymer',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryBlue.withOpacity(0.15),
                                        AppColors.secondaryBlue.withOpacity(
                                          0.1,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.business_center_rounded,
                                        size: 16,
                                        color: AppColors.primaryBlue,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Manage your business efficiently',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      delegate: SliverChildListDelegate([
                        if (_canAccessModule('Products'))
                          _buildMenuButton(
                            context,
                            icon: Icons.inventory,
                            label: 'Products',
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryCyan.withOpacity(0.8),
                                AppColors.primaryCyan,
                              ],
                            ),
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.product);
                            },
                          ),
                        if (_canAccessModule('Voucher'))
                          _buildMenuButton(
                            context,
                            icon: Icons.receipt_long,
                            label: 'Voucher',
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryNavy.withOpacity(0.7),
                                AppColors.primaryNavy,
                              ],
                            ),
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.voucher);
                            },
                          ),
                        if (_canAccessModule('Order'))
                          _buildMenuButton(
                            context,
                            icon: Icons.shopping_cart,
                            label: 'Order',
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF8E24AA).withOpacity(0.8),
                                const Color(0xFF8E24AA),
                              ],
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Order - In Development'),
                                ),
                              );
                            },
                          ),
                        if (_canAccessModule('Factory'))
                          _buildMenuButton(
                            context,
                            icon: Icons.factory,
                            label: 'Factory',
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFE65100).withOpacity(0.8),
                                const Color(0xFFE65100),
                              ],
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Factory - In Development'),
                                ),
                              );
                            },
                          ),

                        if (_canAccessModule('Employee'))
                          _buildMenuButton(
                            context,
                            icon: Icons.people,
                            label: 'Employee',
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF00897B).withOpacity(0.8),
                                const Color(0xFF00897B),
                              ],
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Employee - In Development'),
                                ),
                              );
                            },
                          ),
                        if (_canAccessModule('CRM'))
                          _buildMenuButton(
                            context,
                            icon: Icons.business_center,
                            label: 'CRM',
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF5E35B1).withOpacity(0.8),
                                const Color(0xFF5E35B1),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRoutes.crm);
                            },
                          ),
                      ]),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
              ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Glassmorphism.card(
      blur: 15,
      opacity: 0.6,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Animated background pattern
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.white.withOpacity(0.15),
                            AppColors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          size: 80,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Glass icon container
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 32, color: AppColors.white),
                        ),
                        const SizedBox(height: 16),
                        // Label
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
}
