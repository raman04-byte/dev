import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class AllVouchersPage extends StatelessWidget {
  const AllVouchersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Vouchers'),
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select State',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildStateCard(context, stateName: 'RAJASTHAN', stateCode: 'RAJ'),
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
    );
  }

  Widget _buildStateCard(
    BuildContext context, {
    required String stateName,
    required String stateCode,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.stateVouchers,
          arguments: {'stateName': stateName, 'stateCode': stateCode},
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryCyan, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryCyan.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_city,
                size: 32,
                color: AppColors.primaryCyan,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                stateName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
