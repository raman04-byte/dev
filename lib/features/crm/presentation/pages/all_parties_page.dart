import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../category/data/repositories/category_repository_impl.dart';
import '../../../category/domain/models/category_model.dart';
import '../../data/repositories/party_repository_impl.dart';
import '../../domain/models/party_model.dart';

class AllPartiesPage extends StatefulWidget {
  const AllPartiesPage({super.key});

  @override
  State<AllPartiesPage> createState() => _AllPartiesPageState();
}

class _AllPartiesPageState extends State<AllPartiesPage> {
  final _repository = PartyRepositoryImpl();
  final _categoryRepository = CategoryRepositoryImpl();
  final _searchController = TextEditingController();
  List<PartyModel> _parties = [];
  List<PartyModel> _filteredParties = [];
  Map<String, List<PartyModel>> _partiesByState = {};
  List<CategoryModel> _categories = [];
  final Set<String> _expandedStates = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParties();
    _loadCategories();
    _searchController.addListener(_filterParties);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterParties() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredParties = _parties;
        _updatePartiesByState(_parties);
      });
      return;
    }

    final filtered = _parties.where((party) {
      return party.name.toLowerCase().contains(query) ||
          party.address.toLowerCase().contains(query) ||
          party.pincode.toLowerCase().contains(query) ||
          party.district.toLowerCase().contains(query) ||
          party.state.toLowerCase().contains(query) ||
          party.gstNo.toLowerCase().contains(query) ||
          party.mobileNumber.toLowerCase().contains(query) ||
          party.email.toLowerCase().contains(query) ||
          party.salesPerson.toLowerCase().contains(query) ||
          party.status.toLowerCase().contains(query) ||
          party.paymentTerms.toLowerCase().contains(query);
    }).toList();

    setState(() {
      _filteredParties = filtered;
      _updatePartiesByState(filtered);
    });
  }

  void _updatePartiesByState(List<PartyModel> parties) {
    final Map<String, List<PartyModel>> partiesByState = {};
    for (var party in parties) {
      if (!partiesByState.containsKey(party.state)) {
        partiesByState[party.state] = [];
      }
      partiesByState[party.state]!.add(party);
    }

    final sortedKeys = partiesByState.keys.toList()..sort();
    _partiesByState = {for (var key in sortedKeys) key: partiesByState[key]!};
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // Silently fail for categories
    }
  }

  Future<void> _loadParties() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final parties = await _repository.getAllParties();

      // Group parties by state
      final Map<String, List<PartyModel>> partiesByState = {};
      for (var party in parties) {
        if (!partiesByState.containsKey(party.state)) {
          partiesByState[party.state] = [];
        }
        partiesByState[party.state]!.add(party);
      }

      // Sort states alphabetically
      final sortedKeys = partiesByState.keys.toList()..sort();
      final sortedMap = {for (var key in sortedKeys) key: partiesByState[key]!};

      setState(() {
        _parties = parties;
        _filteredParties = parties;
        _partiesByState = sortedMap;
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
                'All Parties',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.primaryBlue,
                  onPressed: _loadParties,
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
                          'Error loading parties',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadParties,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _parties.isEmpty
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
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryBlue.withOpacity(0.2),
                                AppColors.secondaryBlue.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.group_off_outlined,
                            size: 64,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Parties Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your first party to get started',
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
                                hintText:
                                    'Search by name, address, pincode, etc...',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                              Icons.groups_rounded,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Parties',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_filteredParties.length}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryBlue,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'States',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_partiesByState.length}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondaryBlue,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ..._partiesByState.entries.map((entry) {
                      return _buildStateSection(entry.key, entry.value);
                    }),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStateSection(String state, List<PartyModel> parties) {
    final isExpanded = _expandedStates.contains(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Glassmorphism.card(
          blur: 10,
          opacity: 0.6,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedStates.remove(state);
                } else {
                  _expandedStates.add(state);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue.withOpacity(0.2),
                          AppColors.secondaryBlue.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${parties.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: 12),
              ...parties.map((party) => _buildPartyCard(party)),
            ],
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPartyCard(PartyModel party) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Glassmorphism.card(
        blur: 15,
        opacity: 0.5,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            _showPartyDetails(party);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
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
                        Icons.business_rounded,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            party.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            party.district,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
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
                      label: party.mobileNumber,
                    ),
                    if (party.email.isNotEmpty)
                      _buildInfoChip(icon: Icons.email, label: party.email),
                    if (party.gstNo.isNotEmpty)
                      _buildInfoChip(
                        icon: Icons.receipt_long,
                        label: party.gstNo,
                      ),
                  ],
                ),
                if (party.productDiscounts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.discount_rounded,
                        color: AppColors.primaryBlue,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Discounts',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: party.productDiscounts.entries.map((entry) {
                      final category = _categories.firstWhere(
                        (c) => c.id == entry.key,
                        orElse: () => CategoryModel(
                          id: entry.key,
                          name: 'Category',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue.withOpacity(0.15),
                              AppColors.secondaryBlue.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${category.name}: ${entry.value.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.systemGray6,
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

  Future<void> _navigateToEdit(PartyModel party) async {
    final result = await Navigator.pushNamed(
      context,
      '/crm/add-party',
      arguments: party,
    );

    if (result == true) {
      _loadParties();
    }
  }

  Future<void> _confirmDelete(PartyModel party) async {
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
              Text('Delete Party?'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${party.name}"? This action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && party.id != null) {
      await _deleteParty(party.id!);
    }
  }

  Future<void> _deleteParty(String id) async {
    try {
      await _repository.deleteParty(id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Party deleted successfully'),
            ],
          ),
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      _loadParties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to delete party: ${e.toString()}')),
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

  void _showPartyDetails(PartyModel party) {
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: AppColors.primaryBlue,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            party.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryBlue,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _navigateToEdit(party);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.accentPink,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDelete(party);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      Icons.location_on,
                      'Address',
                      party.address,
                    ),
                    _buildDetailRow(Icons.pin_drop, 'Pincode', party.pincode),
                    _buildDetailRow(
                      Icons.maps_home_work,
                      'District',
                      party.district,
                    ),
                    _buildDetailRow(Icons.location_city, 'State', party.state),
                    _buildDetailRow(Icons.phone, 'Mobile', party.mobileNumber),
                    if (party.email.isNotEmpty)
                      _buildDetailRow(Icons.email, 'Email', party.email),
                    if (party.gstNo.isNotEmpty)
                      _buildDetailRow(
                        Icons.receipt_long,
                        'GST No',
                        party.gstNo,
                      ),
                    if (party.salesPerson.isNotEmpty)
                      _buildDetailRow(
                        Icons.person,
                        'Sales Person',
                        party.salesPerson,
                      ),
                    _buildDetailRow(Icons.toggle_on, 'Status', party.status),
                    _buildDetailRow(
                      Icons.payment,
                      'Payment Terms',
                      party.paymentTerms,
                    ),
                    if (party.productDiscounts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(
                            Icons.discount,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Product Discounts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._buildDiscountList(party.productDiscounts),
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

  List<Widget> _buildDiscountList(Map<String, double> discounts) {
    if (_categories.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Loading categories...',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ];
    }

    return discounts.entries.map((entry) {
      final category = _categories.firstWhere(
        (c) {
          return c.id == entry.key;
        },
        orElse: () {
          return CategoryModel(
            id: entry.key,
            name: 'Unknown (${entry.key})',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        },
      );

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.2),
                      AppColors.secondaryBlue.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${entry.value.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryBlue),
          ),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
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
