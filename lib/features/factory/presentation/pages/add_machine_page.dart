import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../data/repositories/maintenance_repository_impl.dart';
import '../../domain/models/maintenance_nodes.dart';
import '../widgets/maintenance_forms.dart';

class AddMachinePage extends StatefulWidget {
  final MachineNode? machine;
  const AddMachinePage({super.key, this.machine});

  @override
  State<AddMachinePage> createState() => _AddMachinePageState();
}

class _AddMachinePageState extends State<AddMachinePage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = MaintenanceRepositoryImpl();
  final _controllers = MachineFormControllers();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.machine != null) {
      _populateForm();
    }
  }

  void _populateForm() {
    final m = widget.machine!;
    _controllers.name.text = m.name;
    _controllers.code.text = m.code;
    _controllers.manufacturer.text = m.manufacturer;
    _controllers.model.text = m.modelNumber;
    _controllers.serial.text = m.serialNumber;
    _controllers.location.text = m.location;
    _controllers.ratedCapacity.text = m.ratedCapacity?.toString() ?? '';
    _controllers.powerConsumption.text = m.powerConsumption?.toString() ?? '';
    _controllers.maintenanceCycle.text = m.maintenanceCycleDays.toString();

    _controllers.status = m.currentStatus;
    _controllers.criticality = m.criticality;
    _controllers.dateOfPurchase = m.dateOfPurchase;
    _controllers.lastMaintenanceDate = m.lastMaintenanceDate;
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _saveMachine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_controllers.dateOfPurchase == null ||
        _controllers.lastMaintenanceDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required dates')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final id = widget.machine?.id ?? const Uuid().v4();
      final children = widget.machine?.children ?? [];

      // Auto-calc next maintenance date
      final nextDate = _controllers.lastMaintenanceDate!.add(
        Duration(days: int.parse(_controllers.maintenanceCycle.text)),
      );

      final machine = MachineNode(
        id: id,
        name: _controllers.name.text,
        code: _controllers.code.text,
        manufacturer: _controllers.manufacturer.text,
        modelNumber: _controllers.model.text,
        serialNumber: _controllers.serial.text,
        location: _controllers.location.text,
        ratedCapacity: double.tryParse(_controllers.ratedCapacity.text),
        powerConsumption: double.tryParse(_controllers.powerConsumption.text),
        dateOfPurchase: _controllers.dateOfPurchase,
        currentStatus: _controllers.status,
        criticality: _controllers.criticality,
        lastMaintenanceDate: _controllers.lastMaintenanceDate,
        nextMaintenanceDate: nextDate,
        maintenanceCycleDays: int.parse(_controllers.maintenanceCycle.text),
        children: children,
      );

      await _repository.saveNode(machine);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving machine: $e')));
      }
    }
  }

  String _getTitle() {
    return widget.machine == null ? 'Add New Machine' : 'Edit Machine';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.systemGray6,
              AppColors.white,
              const Color(0xFF7B1FA2).withOpacity(0.05),
              AppColors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Glassmorphism.card(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MachineForm(
                      controllers: _controllers,
                      onUpdate: () => setState(() {}),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveMachine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.machine == null
                                  ? 'Save Machine'
                                  : 'Update Machine',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
