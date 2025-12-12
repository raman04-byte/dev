import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';

class VoucherPage extends StatelessWidget {
  const VoucherPage({super.key});

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

  Widget _buildVoucherButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
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
          gradient: LinearGradient(
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
