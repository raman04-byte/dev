import 'package:appwrite/models.dart' as appwrite_models;
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
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
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 20, height: 20),
            const SizedBox(width: 8),
            const Text('Dev Polymer'),
          ],
        ),
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context);
              } else if (value == 'login') {
                _handleLogin(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                if (_currentUser == null)
                  const PopupMenuItem<String>(
                    value: 'login',
                    child: Row(
                      children: [
                        Icon(Icons.login, color: AppColors.textPrimary),
                        SizedBox(width: 8),
                        Text('Login'),
                      ],
                    ),
                  )
                else
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.textPrimary),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  if (_canAccessModule('Products'))
                    _buildMenuButton(
                      context,
                      icon: Icons.inventory,
                      label: 'Products',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Products - In Development'),
                          ),
                        );
                      },
                    ),
                  if (_canAccessModule('Voucher'))
                    _buildMenuButton(
                      context,
                      icon: Icons.receipt_long,
                      label: 'Voucher',
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.voucher);
                      },
                    ),
                  if (_canAccessModule('Order'))
                    _buildMenuButton(
                      context,
                      icon: Icons.shopping_cart,
                      label: 'Order',
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
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Factory - In Development'),
                          ),
                        );
                      },
                    ),
                  if (_canAccessModule('Reminders'))
                    _buildMenuButton(
                      context,
                      icon: Icons.notifications_active,
                      label: 'Reminders',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reminders - In Development'),
                          ),
                        );
                      },
                    ),
                  if (_canAccessModule('Employee'))
                    _buildMenuButton(
                      context,
                      icon: Icons.people,
                      label: 'Employee',
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
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CRM - In Development')),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryCyan, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.primaryCyan),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
