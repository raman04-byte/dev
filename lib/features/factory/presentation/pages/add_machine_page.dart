import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../data/repositories/machine_repository_impl.dart';
import '../../domain/models/machine_model.dart';

class AddMachinePage extends StatefulWidget {
  final String? parentId;
  final String? parentName;
  final int parentLevel;

  const AddMachinePage({
    super.key,
    this.parentId,
    this.parentName,
    this.parentLevel = 0,
  });

  @override
  State<AddMachinePage> createState() => _AddMachinePageState();
}

class _AddMachinePageState extends State<AddMachinePage> {
  final _machineRepository = MachineRepositoryImpl();
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  // Machine-specific
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _powerConsumptionController = TextEditingController();
  final _locationController = TextEditingController();

  // Maintenance
  final _maintenancePeriodController = TextEditingController();
  DateTime? _lastMaintenanceDate;
  DateTime? _nextMaintenanceDate;
  DateTime? _purchaseDate;

  // Child component fields
  final _partManufacturerController = TextEditingController();
  final _partModelController = TextEditingController();
  final _specificationController = TextEditingController();
  String _criticality = 'Critical';
  final _expectedLifespanController = TextEditingController();

  // Component in spare
  final _currentStockController = TextEditingController();
  final _reorderPointController = TextEditingController();
  final _storageLocationController = TextEditingController();
  final _shelfLifeController = TextEditingController();

  // Suppliers
  final List<Map<String, String>> _suppliers = [];
  final _supplierNameController = TextEditingController();
  final _supplierContactController = TextEditingController();
  final _supplierAddressController = TextEditingController();

  // Status and loading
  String _status = 'Running';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    CacheService.init();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _contactNameController.dispose();
    _contactNumberController.dispose();
    _capacityController.dispose();
    _powerConsumptionController.dispose();
    _locationController.dispose();
    _maintenancePeriodController.dispose();
    _partManufacturerController.dispose();
    _partModelController.dispose();
    _specificationController.dispose();
    _expectedLifespanController.dispose();
    _currentStockController.dispose();
    _reorderPointController.dispose();
    _storageLocationController.dispose();
    _shelfLifeController.dispose();
    _supplierNameController.dispose();
    _supplierContactController.dispose();
    _supplierAddressController.dispose();
    super.dispose();
  }

  void _addSupplier() {
    final name = _supplierNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _suppliers.add({
        'name': name,
        'contact': _supplierContactController.text.trim(),
        'address': _supplierAddressController.text.trim(),
      });
      _supplierNameController.clear();
      _supplierContactController.clear();
      _supplierAddressController.clear();
    });
  }

  void _removeSupplier(int index) {
    setState(() => _suppliers.removeAt(index));
  }

  Future<void> _saveMachine() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final period = int.tryParse(_maintenancePeriodController.text) ?? 0;
      final nextDate = _lastMaintenanceDate != null && period > 0
          ? _lastMaintenanceDate!.add(Duration(days: period))
          : null;

      // runningHours is required by MachineModel; use power consumption for machine, 0 for child
      final runningHours = widget.parentId == null
          ? double.tryParse(_powerConsumptionController.text) ?? 0.0
          : 0.0;

      final manufacturerName = widget.parentId == null
          ? _manufacturerController.text.trim()
          : _partManufacturerController.text.trim();

      final manufacturerModel = widget.parentId == null
          ? _modelController.text.trim()
          : _partModelController.text.trim();

      final contactName = widget.parentId == null
          ? _contactNameController.text.trim()
          : null;

      final contactNumber = widget.parentId == null
          ? _contactNumberController.text.trim()
          : null;

      final capacity = widget.parentId == null
          ? double.tryParse(_capacityController.text)
          : null;

      final powerConsumption = widget.parentId == null
          ? double.tryParse(_powerConsumptionController.text)
          : null;

      final location = widget.parentId == null
          ? _locationController.text.trim()
          : null;

      final specification = widget.parentId != null
          ? _specificationController.text.trim()
          : null;

      final expectedLifespanDays = widget.parentId != null
          ? int.tryParse(_expectedLifespanController.text)
          : null;

      final currentStock = widget.parentId != null
          ? int.tryParse(_currentStockController.text)
          : null;
      final reorderPoint = widget.parentId != null
          ? int.tryParse(_reorderPointController.text)
          : null;
      final storageLocation = widget.parentId != null
          ? _storageLocationController.text.trim()
          : null;
      final shelfLifeDays = widget.parentId != null
          ? int.tryParse(_shelfLifeController.text)
          : null;

      final machine = MachineModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        level: widget.parentId == null ? 0 : widget.parentLevel + 1,
        isChild: widget.parentId != null,
        maintenancePeriodDays: period,
        lastMaintenanceDate: _lastMaintenanceDate,
        nextMaintenanceDate: nextDate,
        status: _status,
        parentId: widget.parentId,
        manufacturerName: manufacturerName,
        runningHours: runningHours,
        manufacturerModel: manufacturerModel.isEmpty ? null : manufacturerModel,
        contactName: contactName == '' ? null : contactName,
        contactNumber: contactNumber == '' ? null : contactNumber,
        purchaseDate: widget.parentId == null ? _purchaseDate : null,
        capacity: capacity,
        powerConsumption: powerConsumption,
        location: location,
        specification: specification,
        criticality: widget.parentId != null ? _criticality : null,
        expectedLifespanDays: expectedLifespanDays,
        currentStock: currentStock,
        reorderPoint: reorderPoint,
        storageLocation: storageLocation,
        shelfLifeDays: shelfLifeDays,
        suppliers: _suppliers.isEmpty ? null : _suppliers,
      );

      await _machineRepository.addMachine(machine);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChild = widget.parentId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isChild ? 'Add Component' : 'Add Machine'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Glassmorphism.card(
            blur: 15,
            opacity: 0.7,
            padding: const EdgeInsets.all(24),
            borderRadius: BorderRadius.circular(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isChild) ...[
                    // Machine Details
                    const Text(
                      'Machine Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Machine Name',
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Machine Code',
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),

                    // 1. Manufacturer Section
                    const Text(
                      'Manufacturer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _manufacturerController,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer Name',
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(labelText: 'Model'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactNameController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _purchaseDate == null
                            ? 'Select Purchase Date'
                            : 'Purchase Date: ${DateFormat('yyyy-MM-dd').format(_purchaseDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _purchaseDate = date);
                      },
                    ),
                    const SizedBox(height: 24),

                    // 2. Technical Specifications
                    const Text(
                      'Technical Specifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Capacity (kg/hr)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _powerConsumptionController,
                      decoration: const InputDecoration(
                        labelText: 'Power Consumption (kw/hr)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),

                    // 3. Location
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 24),

                    // 4. Maintenance Period
                    const Text(
                      'Maintenance Period',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _lastMaintenanceDate == null
                            ? 'Select Last Maintenance Date'
                            : 'Last Maintenance Date: ${DateFormat('yyyy-MM-dd').format(_lastMaintenanceDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _lastMaintenanceDate = date;
                            // Recalculate next maintenance if period is set
                            final period = int.tryParse(
                              _maintenancePeriodController.text,
                            );
                            if (period != null && period > 0) {
                              _nextMaintenanceDate = date.add(
                                Duration(days: period),
                              );
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _maintenancePeriodController,
                      decoration: const InputDecoration(
                        labelText: 'Maintenance Period (Days)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final days = int.tryParse(v);
                        if (_lastMaintenanceDate != null &&
                            days != null &&
                            days > 0) {
                          setState(() {
                            _nextMaintenanceDate = _lastMaintenanceDate!.add(
                              Duration(days: days),
                            );
                          });
                        }
                      },
                    ),
                    if (_nextMaintenanceDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          'Next Maintenance Date: ${DateFormat('yyyy-MM-dd').format(_nextMaintenanceDate!)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ] else ...[
                    const Text(
                      'Component Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Part Name'),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Part Number',
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _partManufacturerController,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer',
                      ),
                    ),
                    TextFormField(
                      controller: _partModelController,
                      decoration: const InputDecoration(labelText: 'Model'),
                    ),
                    TextFormField(
                      controller: _specificationController,
                      decoration: const InputDecoration(
                        labelText: 'Specification',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: _criticality,
                      decoration: const InputDecoration(
                        labelText: 'Criticality Level',
                      ),
                      items: ['Critical', 'Semi-critical', 'Non-critical']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _criticality = v!),
                    ),
                    TextFormField(
                      controller: _expectedLifespanController,
                      decoration: const InputDecoration(
                        labelText: 'Expected Lifespan',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Component in Spare',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _currentStockController,
                      decoration: const InputDecoration(
                        labelText: 'Current Quantity Stock',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _reorderPointController,
                      decoration: const InputDecoration(
                        labelText: 'Reorder Point',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _storageLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Storage Location',
                      ),
                    ),
                    TextFormField(
                      controller: _shelfLifeController,
                      decoration: const InputDecoration(
                        labelText: 'Shelf Life',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Suppliers',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._suppliers.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final supplier = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(supplier['name'] ?? ''),
                          subtitle: Text(
                            'Contact: ${supplier['contact'] ?? ''}\nAddress: ${supplier['address'] ?? ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeSupplier(idx),
                          ),
                        ),
                      );
                    }),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _supplierNameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _supplierContactController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Info',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _supplierAddressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: _addSupplier,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!isChild) ...[
                    // 5. Status
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Machine Status',
                      ),
                      items: ['Running', 'Standby', 'OnMaintenance']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveMachine,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Add Machine'),
                      ),
                    ),
                  ],
                  if (isChild) ...[
                    const Text(
                      'Maintenance Period',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text(
                        _lastMaintenanceDate == null
                            ? 'Select Last Maintenance Date'
                            : 'Last Maintenance: ${DateFormat('yyyy-MM-dd').format(_lastMaintenanceDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null)
                          setState(() => _lastMaintenanceDate = date);
                      },
                    ),
                    TextFormField(
                      controller: _maintenancePeriodController,
                      decoration: const InputDecoration(
                        labelText: 'Maintenance Period (Days)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      onChanged: (v) {
                        final days = int.tryParse(v);
                        if (_lastMaintenanceDate != null && days != null) {
                          setState(() {
                            _nextMaintenanceDate = _lastMaintenanceDate!.add(
                              Duration(days: days),
                            );
                          });
                        }
                      },
                    ),
                    if (_nextMaintenanceDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Next Maintenance: ${DateFormat('yyyy-MM-dd').format(_nextMaintenanceDate!)}',
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveMachine,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Add'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
