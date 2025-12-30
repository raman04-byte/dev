import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/services/cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../data/repositories/maintenance_repository_impl.dart';
import '../../domain/models/maintenance_nodes.dart';
import '../../domain/models/maintenance_extensions.dart';
import 'add_machine_page.dart';
import 'maintenance_node_details_page.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final _repository = MaintenanceRepositoryImpl();
  List<MachineNode> _machines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    CacheService.init();
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    setState(() => _isLoading = true);
    try {
      final machines = await _repository.getAllMachines();
      setState(() {
        _machines = machines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading machines: $e')));
      }
    }
  }

  Future<void> _addMachine() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMachinePage()),
    );
    if (result == true) _loadMachines();
  }

  void _openMachine(MachineNode machine) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MaintenanceNodeDetailsPage(node: machine, rootNode: machine),
      ),
    );
    _loadMachines();
  }

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.running:
        return Colors.green;
      case MaintenanceStatus.standby:
        return Colors.orange;
      case MaintenanceStatus.underMaintenance:
      case MaintenanceStatus.breakdown:
        return Colors.red;
    }
  }

  String _calculateAge(DateTime? purchaseDate) {
    if (purchaseDate == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(purchaseDate);
    final days = difference.inDays;

    if (days < 30) return '$days days';
    if (days < 365) return '${(days / 30).floor()} months';
    final years = (days / 365).floor();
    final months = ((days % 365) / 30).floor();
    if (months > 0) return '$years yrs $months mos';
    return '$years years';
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
                'Maintenance',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.textPrimary,
                  onPressed: _addMachine,
                  tooltip: 'Add Machine',
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
              const Color(0xFF7B1FA2).withOpacity(0.02),
              AppColors.white,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _machines.isEmpty
              ? Center(
                  child: Glassmorphism.card(
                    blur: 15,
                    opacity: 0.7,
                    padding: const EdgeInsets.all(48),
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.precision_manufacturing,
                          size: 64,
                          color: const Color(0xFF7B1FA2).withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Machines Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your first machine to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _machines.length,
                  itemBuilder: (context, index) {
                    final machine = _machines[index];
                    return _buildMachineCard(machine);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildMachineCard(MachineNode machine) {
    final statusColor = _getStatusColor(machine.currentStatus);
    final majorCount = machine.countTypeInSubtree<MajorAssemblyNode>();
    final subCount = machine.countTypeInSubtree<SubAssemblyNode>();
    final compCount = machine.countTypeInSubtree<ComponentNode>();
    final age = _calculateAge(machine.dateOfPurchase);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Glassmorphism.card(
        blur: 20,
        opacity: 0.6,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _openMachine(machine),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Name, Status, Edit/Delete
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B1FA2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.precision_manufacturing,
                        color: Color(0xFF7B1FA2),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            machine.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Model: ${machine.modelNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        machine.currentStatus.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Info Grid
                Row(
                  children: [
                    _buildInfoItem('Lifespan', age, Icons.history),
                    _buildInfoItem(
                      'Capacity',
                      '${machine.ratedCapacity ?? "-"} kg/hr',
                      Icons.speed,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: 16),

                // Counts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCountBadge('Major', majorCount, Colors.blue),
                    _buildCountBadge('Sub', subCount, Colors.orange),
                    _buildCountBadge('Parts', compCount, Colors.purple),
                  ],
                ),

                // Actions (Edit/Delete) - kept subtle at bottom right or top right?
                // User asked for "Edit/Delete at every level".
                // Let's create a row at the bottom for actions, or use top right.
                // Re-implementing actions at bottom right but smaller.
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddMachinePage(machine: machine),
                          ),
                        );
                        if (result == true) _loadMachines();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Machine'),
                            content: Text(
                              'Are you sure you want to delete ${machine.name} and all its components?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _repository.deleteNode(machine.id);
                          _loadMachines();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.delete, size: 18, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary.withOpacity(0.7)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$count $label',
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
