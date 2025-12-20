import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../data/repositories/transporter_repository_impl.dart';
import '../../domain/models/transporter_model.dart';

class AllTransportersPage extends StatefulWidget {
  const AllTransportersPage({super.key});

  @override
  State<AllTransportersPage> createState() => _AllTransportersPageState();
}

class _AllTransportersPageState extends State<AllTransportersPage> {
  final _repository = TransporterRepositoryImpl();
  final _searchController = TextEditingController();
  List<TransporterModel> _transporters = [];
  List<TransporterModel> _filteredTransporters = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _pincodeData = {};

  @override
  void initState() {
    super.initState();
    _loadPincodeData();
    _loadTransporters();
    _searchController.addListener(_filterTransporters);
  }

  Future<void> _loadPincodeData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/pincode/pincode.json',
      );
      setState(() {
        _pincodeData = json.decode(jsonString);
      });
    } catch (e) {
      // Handle error silently
    }
  }

  String? _getDistrictForPin(String pin) {
    for (var state in _pincodeData.values) {
      final stateData = state as Map<String, dynamic>;
      for (var entry in stateData.entries) {
        if (entry.value.toString() == pin) {
          return entry.key;
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTransporters() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredTransporters = _transporters;
      });
      return;
    }

    final filtered = _transporters.where((transporter) {
      // Check basic fields
      if (transporter.transportName.toLowerCase().contains(query) ||
          transporter.address.toLowerCase().contains(query) ||
          transporter.gstNumber.toLowerCase().contains(query) ||
          transporter.contactName.toLowerCase().contains(query) ||
          transporter.contactNumber.contains(query) ||
          transporter.remarks.toLowerCase().contains(query) ||
          transporter.rsPerCarton.toString().contains(query) ||
          transporter.rsPerKg.toString().contains(query)) {
        return true;
      }

      // Check PIN codes
      if (transporter.deliveryPinCodes.any((pin) => pin.contains(query))) {
        return true;
      }

      // Check states
      if (transporter.deliveryStates.any(
        (state) => state.toLowerCase().contains(query),
      )) {
        return true;
      }

      // Check districts from PIN codes
      for (var pin in transporter.deliveryPinCodes) {
        final district = _getDistrictForPin(pin);
        if (district != null && district.toLowerCase().contains(query)) {
          return true;
        }
      }

      return false;
    }).toList();

    setState(() {
      _filteredTransporters = filtered;
    });
  }

  Future<void> _loadTransporters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transporters = await _repository.getAllTransporters();

      setState(() {
        _transporters = transporters;
        _filteredTransporters = transporters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
                'All Transporters',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Glassmorphism.card(
                    blur: 15,
                    opacity: 0.7,
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.accentPink,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading transporters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadTransporters,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _transporters.isEmpty
              ? Center(
                  child: Glassmorphism.card(
                    blur: 15,
                    opacity: 0.7,
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Transporters Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your first transporter to get started',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  children: [
                    // Search Bar
                    Glassmorphism.card(
                      blur: 15,
                      opacity: 0.7,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search transporters...',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Stats Card
                    Glassmorphism.card(
                      blur: 15,
                      opacity: 0.7,
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(20),
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
                              Icons.local_shipping_rounded,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Transporters',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_filteredTransporters.length}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryBlue,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Transporters List
                    ..._filteredTransporters.map(_buildTransporterCard),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTransporterCard(TransporterModel transporter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Glassmorphism.card(
        blur: 15,
        opacity: 0.7,
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showTransporterDetails(transporter),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue.withOpacity(0.15),
                          AppColors.secondaryBlue.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transporter.transportName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transporter.contactName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToEdit(transporter);
                      } else if (value == 'delete') {
                        _confirmDelete(transporter);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 20,
                              color: AppColors.accentPink,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.accentPink),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.phone,
                    label: transporter.contactNumber,
                  ),
                  if (transporter.rsPerCarton > 0)
                    _buildInfoChip(
                      icon: Icons.inventory_2,
                      label: '₹${transporter.rsPerCarton}/carton',
                    ),
                  if (transporter.rsPerKg > 0)
                    _buildInfoChip(
                      icon: Icons.scale,
                      label: '₹${transporter.rsPerKg}/kg',
                    ),
                  if (transporter.deliveryPinCodes.isNotEmpty)
                    _buildInfoChip(
                      icon: Icons.push_pin,
                      label: '${transporter.deliveryPinCodes.length} PINs',
                    ),
                  if (transporter.deliveryStates.isNotEmpty)
                    _buildInfoChip(
                      icon: Icons.map,
                      label: '${transporter.deliveryStates.length} States',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit(TransporterModel transporter) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.addTransporter,
      arguments: transporter,
    );

    if (result == true) {
      _loadTransporters();
    }
  }

  Future<void> _confirmDelete(TransporterModel transporter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: AppColors.accentPink),
              SizedBox(width: 12),
              Text('Delete Transporter'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${transporter.transportName}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPink,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && transporter.id != null) {
      _deleteTransporter(transporter.id!);
    }
  }

  Future<void> _deleteTransporter(String id) async {
    try {
      await _repository.deleteTransporter(id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Transporter deleted successfully'),
            ],
          ),
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      _loadTransporters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Failed to delete transporter: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: AppColors.accentPink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showTransporterDetails(TransporterModel transporter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: AppColors.primaryBlue,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transporter.transportName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      Icons.location_on,
                      'Address',
                      transporter.address,
                    ),
                    if (transporter.gstNumber.isNotEmpty)
                      _buildDetailRow(
                        Icons.receipt_long,
                        'GST Number',
                        transporter.gstNumber,
                      ),
                    _buildDetailRow(
                      Icons.person,
                      'Contact Name',
                      transporter.contactName,
                    ),
                    _buildDetailRow(
                      Icons.phone,
                      'Contact Number',
                      transporter.contactNumber,
                    ),
                    _buildDetailRow(Icons.note, 'Remarks', transporter.remarks),
                    if (transporter.rsPerCarton > 0)
                      _buildDetailRow(
                        Icons.inventory_2,
                        'Rs Per Carton',
                        '₹${transporter.rsPerCarton}',
                      ),
                    if (transporter.rsPerKg > 0)
                      _buildDetailRow(
                        Icons.scale,
                        'Rs Per Kg',
                        '₹${transporter.rsPerKg}',
                      ),
                    if (transporter.deliveryPinCodes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Delivery PIN Codes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: transporter.deliveryPinCodes.map((pin) {
                          final district = _getDistrictForPin(pin);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryBlue.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.push_pin,
                                      size: 12,
                                      color: AppColors.primaryBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pin,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                if (district != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    district,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (transporter.deliveryStates.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Delivery States',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: transporter.deliveryStates
                            .map(
                              (state) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.accentGreen.withOpacity(
                                      0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.map,
                                      size: 12,
                                      color: AppColors.accentGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      state,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accentGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
