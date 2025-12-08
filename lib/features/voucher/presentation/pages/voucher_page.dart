import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class VoucherPage extends StatelessWidget {
  const VoucherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher'),
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            const SizedBox(height: 24),
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
    );
  }

  Widget _buildVoucherButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryCyan, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppColors.primaryCyan),
            const SizedBox(width: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: AppColors.primaryCyan,
            ),
          ],
        ),
      ),
    );
  }
}
