import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../data/repositories/machine_repository_impl.dart';
import '../../domain/models/machine_model.dart';
import 'add_machine_page.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final _machineRepository = MachineRepositoryImpl();
  List<MachineModel> _machines = [];
  List<MachineModel> _currentView = [];
  final List<MachineModel> _navigationStack = [];
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
      final machines = await _machineRepository.getAllMachines();
      setState(() {
        _machines = machines;
        // Show only top-level machines (level 0, isChild = false)
        _currentView = machines
            .where((m) => !m.isChild && m.level == 0)
            .toList();
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

  void _navigateToMachine(MachineModel machine) {
    setState(() {
      _navigationStack.add(machine);
      // Show all children of this machine
      _currentView = _machines.where((m) => m.parentId == machine.id).toList();
    });
  }

  void _navigateBack() {
    if (_navigationStack.isEmpty) return;
    setState(() {
      _navigationStack.removeLast();
      if (_navigationStack.isEmpty) {
        // Back to top level
        _currentView = _machines
            .where((m) => !m.isChild && m.level == 0)
            .toList();
      } else {
        // Back to previous parent
        final parent = _navigationStack.last;
        _currentView = _machines.where((m) => m.parentId == parent.id).toList();
      }
    });
  }

  Future<void> _addComponent() async {
    final parent = _navigationStack.isEmpty ? null : _navigationStack.last;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMachinePage(
          parentId: parent?.id,
          parentName: parent?.name,
          parentLevel: parent?.level ?? 0,
        ),
      ),
    );
    if (result == true) _loadMachines();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Running':
        return Colors.green;
      case 'Standby':
        return Colors.orange;
      case 'OnMaintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTopLevel = _navigationStack.isEmpty;

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
                icon: Icon(
                  isTopLevel ? Icons.arrow_back_ios_rounded : Icons.arrow_back,
                ),
                color: AppColors.textPrimary,
                onPressed: isTopLevel
                    ? () => Navigator.of(context).pop()
                    : _navigateBack,
              ),
              title: Text(
                isTopLevel ? 'Maintenance' : _navigationStack.last.name,
                style: const TextStyle(
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
                  onPressed: _addComponent,
                  tooltip: isTopLevel ? 'Add Machine' : 'Add Component',
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
          child: Column(
            children: [
              // Breadcrumb navigation
              if (_navigationStack.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.home,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        for (int i = 0; i < _navigationStack.length; i++) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _navigationStack[i].name,
                            style: TextStyle(
                              fontSize: 14,
                              color: i == _navigationStack.length - 1
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: i == _navigationStack.length - 1
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              // Machine/Component List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _currentView.isEmpty
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
                                isTopLevel
                                    ? Icons.precision_manufacturing
                                    : Icons.widgets,
                                size: 64,
                                color: const Color(0xFF7B1FA2).withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isTopLevel
                                    ? 'No Machines Yet'
                                    : 'No Components',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isTopLevel
                                    ? 'Add your first machine to get started'
                                    : 'Add components to this machine',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _currentView.length,
                        itemBuilder: (context, index) {
                          final machine = _currentView[index];
                          final hasChildren = _machines.any(
                            (m) => m.parentId == machine.id,
                          );
                          return _buildMachineCard(machine, hasChildren);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineCard(MachineModel machine, bool hasChildren) {
    final statusColor = _getStatusColor(machine.status);
    final isTopLevel = machine.level == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Glassmorphism.card(
        blur: 15,
        opacity: 0.7,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _navigateToMachine(machine),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                            const Color(0xFF7B1FA2).withOpacity(0.15),
                            const Color(0xFF9C27B0).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isTopLevel
                            ? Icons.precision_manufacturing
                            : Icons.widgets,
                        color: const Color(0xFF7B1FA2),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  machine.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
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
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  machine.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Code: ${machine.code}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasChildren) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                // Key Information
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    if (machine.manufacturerName.isNotEmpty)
                      _buildInfoChip(
                        Icons.factory,
                        'Manufacturer',
                        machine.manufacturerName,
                      ),
                    if (machine.location != null)
                      _buildInfoChip(
                        Icons.location_on,
                        'Location',
                        machine.location!,
                      ),
                    if (machine.capacity != null)
                      _buildInfoChip(
                        Icons.speed,
                        'Capacity',
                        '${machine.capacity} kg/hr',
                      ),
                    if (machine.nextMaintenanceDate != null)
                      _buildInfoChip(
                        Icons.calendar_today,
                        'Next Maintenance',
                        DateFormat(
                          'MMM dd, yyyy',
                        ).format(machine.nextMaintenanceDate!),
                        color: _isMaintenanceDue(machine.nextMaintenanceDate!)
                            ? Colors.red
                            : null,
                      ),
                  ],
                ),
                if (hasChildren) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B1FA2).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.layers,
                          size: 16,
                          color: Color(0xFF7B1FA2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_machines.where((m) => m.parentId == machine.id).length} ${isTopLevel ? "Components" : "Sub-components"}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B1FA2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    final chipColor = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: chipColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: chipColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: chipColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isMaintenanceDue(DateTime nextMaintenance) {
    final now = DateTime.now();
    final daysUntil = nextMaintenance.difference(now).inDays;
    return daysUntil <= 7; // Due in 7 days or less
  }
}
