import 'dart:io';

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
      appBar: Glassmorphism.appBar(
        title: const Text(
          'Voucher',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
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
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              const SizedBox(height: 24),
              _buildVoucherButton(
                context,
                icon: Icons.file_upload_outlined,
                label: 'IMPORT FROM EXCEL',
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.15),
                    AppColors.primaryCyan.withOpacity(0.1),
                  ],
                ),
                onTap: _importFromExcel,
              ),
              _buildVoucherButton(
                context,
                icon: Icons.add_circle_outline,
                label: 'RAJASTHAN',
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.addVoucher, arguments: 'RAJ');
                },
              ),
              _buildVoucherButton(
                context,
                icon: Icons.add_circle_outline,
                label: 'UTTAR PRADESH',
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.addVoucher, arguments: 'UP');
                },
              ),
              _buildVoucherButton(
                context,
                icon: Icons.add_circle_outline,
                label: 'JHARKHAND',
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.addVoucher, arguments: 'JH');
                },
              ),
              _buildVoucherButton(
                context,
                icon: Icons.all_inbox,
                label: 'All Vouchers',
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.allVouchers);
                },
              ),
            ],
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
      final selectedState = await _showStateSelectionDialog();

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

  Future<Map<String, String>?> _showStateSelectionDialog() async {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
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
            const Text('Select State'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select the state for these vouchers:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildStateOption(name: 'Rajasthan', code: 'RAJ'),
            const SizedBox(height: 12),
            _buildStateOption(name: 'Uttar Pradesh', code: 'UP'),
            const SizedBox(height: 12),
            _buildStateOption(name: 'Jharkhand', code: 'JH'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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

  Widget _buildVoucherButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Gradient? gradient,
  }) {
    return Glassmorphism.card(
      blur: 15,
      opacity: 0.7,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          gradient:
              gradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withOpacity(0.05),
                  AppColors.white.withOpacity(0.02),
                ],
              ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
