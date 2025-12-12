import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';

class AllVouchersPage extends StatelessWidget {
  const AllVouchersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: Glassmorphism.appBar(
        title: const Text(
          'All Vouchers',
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
            children: [
              Glassmorphism.card(
                blur: 15,
                opacity: 0.7,
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(20),
                child: Text(
                  'Select State',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildStateCard(
                context,
                stateName: 'RAJASTHAN',
                stateCode: 'RAJ',
              ),
              const SizedBox(height: 16),
              _buildStateCard(
                context,
                stateName: 'UTTAR PRADESH',
                stateCode: 'UP',
              ),
              const SizedBox(height: 16),
              _buildStateCard(context, stateName: 'JHARKHAND', stateCode: 'JH'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateCard(
    BuildContext context, {
    required String stateName,
    required String stateCode,
  }) {
    return Glassmorphism.card(
      blur: 15,
      opacity: 0.7,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.stateVouchers,
          arguments: {'stateName': stateName, 'stateCode': stateCode},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
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
              child: const Icon(
                Icons.location_city_rounded,
                size: 28,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                stateName,
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
