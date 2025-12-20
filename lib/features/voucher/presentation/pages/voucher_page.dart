import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';

class VoucherPage extends StatefulWidget {
  const VoucherPage({super.key});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
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
                'Voucher',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'import') {
                      _importFromExcel();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.file_upload_outlined),
                          SizedBox(width: 12),
                          Text('Import from Excel'),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Glassmorphism.card(
                  blur: 15,
                  opacity: 0.7,
                  padding: const EdgeInsets.all(24),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlue.withOpacity(0.15),
                                  AppColors.secondaryBlue.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.primaryBlue,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Voucher Management',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Create and manage vouchers',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
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
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildActionCard(
                        context,
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Create Voucher',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.secondaryBlue,
                          ],
                        ),
                        onTap: () {
                          _showStateSelectionDialog();
                        },
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.list_alt_rounded,
                        label: 'All Vouchers',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                        ),
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.allVouchers);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importFromExcel() async {
    try {
      // Step 1: Pick Excel file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        return; // User cancelled
      }

      final file = File(result.files.single.path!);

      // Step 2: Show state selection dialog
      if (!mounted) return;
      final selectedState = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Select State',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select the state for these vouchers:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStateOption(name: 'Rajasthan', code: 'RAJ'),
                    const SizedBox(height: 12),
                    _buildStateOption(name: 'Uttar Pradesh', code: 'UP'),
                    const SizedBox(height: 12),
                    _buildStateOption(name: 'Jharkhand', code: 'JH'),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      if (selectedState == null) {
        return; // User cancelled state selection
      }

      // Step 3: Navigate to import page with file and state
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        AppRoutes.voucherExcelImport,
        arguments: {
          'stateName': selectedState['name']!,
          'stateCode': selectedState['code']!,
          'filePath': file.path,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
    }
  }

  Future<void> _showStateSelectionDialog() async {
    final selectedState = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Select State',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select the state for the voucher:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStateOption(name: 'Rajasthan', code: 'RAJ'),
                  const SizedBox(height: 12),
                  _buildStateOption(name: 'Uttar Pradesh', code: 'UP'),
                  const SizedBox(height: 12),
                  _buildStateOption(name: 'Jharkhand', code: 'JH'),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (selectedState != null && mounted) {
      Navigator.of(
        context,
      ).pushNamed(AppRoutes.addVoucher, arguments: selectedState['code']!);
    }
  }

  Widget _buildStateOption({required String name, required String code}) {
    return InkWell(
      onTap: () {
        Navigator.pop(context, {'name': name, 'code': code});
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Glassmorphism.card(
      blur: 15,
      opacity: 0.5,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
