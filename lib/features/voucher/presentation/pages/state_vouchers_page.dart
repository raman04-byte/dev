import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/pdf_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../data/repositories/voucher_repository_impl.dart';
import '../../domain/models/voucher_model.dart';

class StateVouchersPage extends StatefulWidget {
  final String stateName;
  final String stateCode;

  const StateVouchersPage({
    super.key,
    required this.stateName,
    required this.stateCode,
  });

  @override
  State<StateVouchersPage> createState() => _StateVouchersPageState();
}

class _StateVouchersPageState extends State<StateVouchersPage> {
  final _voucherRepository = VoucherRepositoryImpl();
  List<VoucherModel> _vouchers = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedVoucherIds = {};
  String? _selectedYear;
  List<String> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers({bool forceRefresh = false}) async {
    try {
      // Use server-side filtering for better performance
      final vouchers = await _voucherRepository.getVouchersByState(
        widget.stateCode,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _vouchers = vouchers;
          _isLoading = false;

          // Extract available years
          final years = <String>{};
          for (final voucher in vouchers) {
            years.add(voucher.date.year.toString());
          }
          _availableYears = years.toList()..sort((a, b) => b.compareTo(a));

          // Set default year to current year or first available
          if (_selectedYear == null && _availableYears.isNotEmpty) {
            final currentYear = DateTime.now().year.toString();
            _selectedYear = _availableYears.contains(currentYear)
                ? currentYear
                : _availableYears.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading vouchers: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: Glassmorphism.appBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedVoucherIds.length} Selected'
              : '${widget.stateName} Vouchers',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        leading: _isSelectionMode
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.accentPink,
                  ),
                  onPressed: _cancelSelection,
                ),
              )
            : null,
        actions: [
          if (_isSelectionMode)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _selectedVoucherIds.length == _vouchers.length
                          ? Icons.deselect
                          : Icons.select_all_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    onPressed: _toggleSelectAll,
                    tooltip: _selectedVoucherIds.length == _vouchers.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.accentPink,
                    ),
                    onPressed: _selectedVoucherIds.isEmpty
                        ? null
                        : _deleteSelectedVouchers,
                    tooltip: 'Delete',
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    onPressed: _selectedVoucherIds.isEmpty
                        ? null
                        : _exportSelectedToPdf,
                    tooltip: 'Export to PDF',
                  ),
                ),
              ],
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.checklist_rounded,
                  color: AppColors.primaryBlue,
                ),
                onPressed: _enterSelectionMode,
                tooltip: 'Select Vouchers',
              ),
            ),
        ],
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _vouchers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: AppColors.primaryBlue.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No vouchers found',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  const SizedBox(height: 90),
                  // Summary Tile
                  _buildSummaryTile(),
                  // Vouchers List
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _loadVouchers(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _getFilteredVouchers().length,
                        itemBuilder: (context, index) {
                          return _buildVoucherCard(
                            _getFilteredVouchers()[index],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<VoucherModel> _getFilteredVouchers() {
    if (_selectedYear == null) return _vouchers;
    return _vouchers
        .where((v) => v.date.year.toString() == _selectedYear)
        .toList();
  }

  Widget _buildSummaryTile() {
    final filteredVouchers = _getFilteredVouchers();
    final totalAmount = filteredVouchers.fold<int>(
      0,
      (sum, voucher) => sum + voucher.amountOfExpenses,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryCyan,
            AppColors.primaryCyan.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Year dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.white, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedYear,
                    dropdownColor: AppColors.primaryNavy,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.white,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    items: _availableYears.map((year) {
                      return DropdownMenuItem(value: year, child: Text(year));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.receipt_long,
                  label: 'Total Vouchers',
                  value: filteredVouchers.length.toString(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.currency_rupee,
                  label: 'Total Amount',
                  value: NumberFormat('#,##,###').format(totalAmount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(VoucherModel voucher) {
    final isSelected = _selectedVoucherIds.contains(voucher.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primaryNavy : AppColors.primaryCyan,
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected ? AppColors.primaryCyan.withOpacity(0.05) : null,
      child: InkWell(
        onTap: () => _isSelectionMode
            ? _toggleVoucherSelection(voucher.id!)
            : _showVoucherDetails(voucher),
        onLongPress: () {
          if (!_isSelectionMode) {
            _enterSelectionMode();
            _toggleVoucherSelection(voucher.id!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? AppColors.primaryNavy
                            : AppColors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSelected ? 'Selected' : 'Tap to select',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppColors.primaryNavy
                              : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      voucher.farmerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Rs. ${voucher.amountOfExpenses}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today,
                DateFormat('dd MMM yyyy').format(voucher.date),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.folder_outlined, voucher.fileRegNo),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person, voucher.expensesBy),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      voucher.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryCyan),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showVoucherDetails(VoucherModel voucher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Voucher Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Farmer Name', voucher.farmerName),
              _buildDetailRow(
                'Date',
                DateFormat('dd MMM yyyy').format(voucher.date),
              ),
              _buildDetailRow('File Reg No.', voucher.fileRegNo),
              _buildDetailRow('Amount', 'Rs. ${voucher.amountOfExpenses}'),
              _buildDetailRow('Expenses By', voucher.expensesBy),
              _buildDetailRow('Mode of Payment', voucher.paymentMode),
              _buildDetailRow('Address', voucher.address),
              const SizedBox(height: 16),
              Text(
                'Nature of Expenses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...voucher.natureOfExpenses.map(
                (expense) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.primaryCyan,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(expense)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Expenditure',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...voucher.amountToBePaid.map(
                (expense) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.primaryCyan,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(expense)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Signatures section
              if (voucher.receiverSignature != null ||
                  voucher.payorSignature != null) ...[
                Text(
                  'Signatures',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (voucher.receiverSignature != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign. of Expense Recipient',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<Uint8List>(
                              future: _voucherRepository.downloadSignature(
                                voucher.receiverSignature!,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.grey.withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.contain,
                                    ),
                                  );
                                }
                                return const SizedBox(
                                  height: 80,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    if (voucher.receiverSignature != null &&
                        voucher.payorSignature != null)
                      const SizedBox(width: 16),
                    if (voucher.payorSignature != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Company Payor',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<Uint8List>(
                              future: _voucherRepository.downloadSignature(
                                voucher.payorSignature!,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.grey.withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.contain,
                                    ),
                                  );
                                }
                                return const SizedBox(
                                  height: 80,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedVoucherIds.clear();
    });
  }

  void _toggleVoucherSelection(String voucherId) {
    setState(() {
      if (_selectedVoucherIds.contains(voucherId)) {
        _selectedVoucherIds.remove(voucherId);
      } else {
        _selectedVoucherIds.add(voucherId);
      }
    });
  }

  void _toggleSelectAll() {
    final filteredVouchers = _getFilteredVouchers();
    setState(() {
      if (_selectedVoucherIds.length == filteredVouchers.length) {
        // Deselect all
        _selectedVoucherIds.clear();
      } else {
        // Select all filtered vouchers
        _selectedVoucherIds.clear();
        _selectedVoucherIds.addAll(filteredVouchers.map((v) => v.id!));
      }
    });
  }

  Future<void> _deleteSelectedVouchers() async {
    if (_selectedVoucherIds.isEmpty) return;

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vouchers'),
        content: Text(
          'Are you sure you want to delete ${_selectedVoucherIds.length} voucher(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting vouchers...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Delete from Appwrite
      int deletedCount = 0;
      int failedCount = 0;

      for (final voucherId in _selectedVoucherIds) {
        try {
          // Find voucher to get signature IDs before deleting
          final voucher = _vouchers.firstWhere((v) => v.id == voucherId);

          // Delete signatures from storage if they exist
          if (voucher.receiverSignature != null) {
            try {
              await _voucherRepository.deleteSignature(
                voucher.receiverSignature!,
              );
            } catch (e) {
              // Continue if signature deletion fails
            }
          }

          if (voucher.payorSignature != null) {
            try {
              await _voucherRepository.deleteSignature(voucher.payorSignature!);
            } catch (e) {
              // Continue if signature deletion fails
            }
          }

          // Delete voucher from database
          await _voucherRepository.deleteVoucher(voucherId);
          deletedCount++;
        } catch (e) {
          failedCount++;
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Reload vouchers
      await _loadVouchers();

      // Clear selection and exit selection mode
      _selectedVoucherIds.clear();
      setState(() {
        _isSelectionMode = false;
      });

      // Show result message
      if (failedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted $deletedCount voucher(s)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deleted $deletedCount voucher(s). Failed to delete $failedCount.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Try to close loading dialog if it's still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting vouchers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportSelectedToPdf() async {
    if (_selectedVoucherIds.isEmpty) return;

    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Get selected vouchers
      final selectedVouchers = _vouchers
          .where((v) => _selectedVoucherIds.contains(v.id))
          .toList();

      // Helper function to convert expense name back to number
      int? getExpenseTypeNumber(String name) {
        switch (name) {
          case 'Field Visit Expenses':
            return 1;
          case 'Fright Expenses':
            return 2;
          case 'Installation Expenses':
            return 3;
          case 'Physical Verification':
            return 4;
          case 'Service Expenses':
            return 5;
          default:
            return null;
        }
      }

      // Helper function to convert payment expense name back to number
      int? getPaymentExpenseNumber(String name) {
        switch (name) {
          case 'Vehicle Rent':
            return 1;
          case 'Hotel':
            return 2;
          case 'Food':
            return 3;
          case 'Local Cartage':
            return 4;
          case 'Labour':
            return 5;
          case 'Other':
            return 6;
          default:
            return null;
        }
      }

      // Process all vouchers for PDF generation
      final List<Map<String, dynamic>> voucherData = [];

      for (final v in selectedVouchers) {
        // Convert expense names back to numbers
        final expenseTypes = v.natureOfExpenses
            .map((name) => getExpenseTypeNumber(name))
            .where((num) => num != null)
            .cast<int>()
            .toSet();

        final paymentExpenses = v.amountToBePaid
            .map((name) => getPaymentExpenseNumber(name))
            .where((num) => num != null)
            .cast<int>()
            .toSet();

        // Download signatures if they exist
        Uint8List? receiverSig;
        Uint8List? payorSig;

        try {
          if (v.receiverSignature != null) {
            receiverSig = await _voucherRepository.downloadSignature(
              v.receiverSignature!,
            );
          }
        } catch (e) {
          // Silently fail if signature download fails
        }

        try {
          if (v.payorSignature != null) {
            payorSig = await _voucherRepository.downloadSignature(
              v.payorSignature!,
            );
          }
        } catch (e) {
          // Silently fail if signature download fails
        }

        voucherData.add({
          'farmerName': v.farmerName,
          'date': v.date,
          'address': v.address,
          'fileRegNo': v.fileRegNo,
          'amount': v.amountOfExpenses,
          'expensesBy': v.expensesBy,
          'expenseTypes': expenseTypes,
          'paymentExpenses': paymentExpenses,
          'receiverSignature': receiverSig,
          'signature': payorSig,
          'paymentMode': v.paymentMode,
        });
      }

      // Generate single PDF with all vouchers
      final pdfFile = await PdfService.generateMultiVoucherPdf(
        vouchers: voucherData,
        stateCode: widget.stateCode,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate to PDF viewer with share option
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(pdfFile: pdfFile),
        ),
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${selectedVouchers.length} voucher(s) to PDF',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Exit selection mode
      _cancelSelection();
    } catch (e) {
      if (!mounted) return;
      // Try to close loading dialog if it's still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting to PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
