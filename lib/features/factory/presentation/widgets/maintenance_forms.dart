import 'package:flutter/material.dart';
import '../../domain/models/maintenance_nodes.dart';

// Helper to pick date
Future<DateTime?> pickDate(
  BuildContext context, {
  DateTime? initialDate,
}) async {
  return await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
}

// Helper for text fields
Widget buildTextField({
  required TextEditingController controller,
  required String label,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: keyboardType,
      validator: validator,
    ),
  );
}

// Helper for dropdowns
Widget buildDropdown<T>({
  required T value,
  required List<T> items,
  required String Function(T) labelBuilder,
  required void Function(T?) onChanged,
  String? label,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: items
          .map(
            (item) =>
                DropdownMenuItem(value: item, child: Text(labelBuilder(item))),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );
}

// ==================== Machine Form Steps ====================

// Since the machine form is large, we might want to split it or keep it as one big form.
// For simplicity in this "dynamic" requirement, let's make a class that holds controllers.

class MachineFormControllers {
  final name = TextEditingController();
  final code = TextEditingController();
  final manufacturer = TextEditingController();
  final model = TextEditingController();
  final serial = TextEditingController();
  final location = TextEditingController();
  final ratedCapacity = TextEditingController();
  final powerConsumption = TextEditingController();
  final maintenanceCycle = TextEditingController();

  MaintenanceStatus status = MaintenanceStatus.running;
  CriticalityLevel criticality = CriticalityLevel.critical;
  DateTime? dateOfPurchase;
  DateTime? lastMaintenanceDate;

  void dispose() {
    name.dispose();
    code.dispose();
    manufacturer.dispose();
    model.dispose();
    serial.dispose();
    location.dispose();
    ratedCapacity.dispose();
    powerConsumption.dispose();
    maintenanceCycle.dispose();
  }
}

class MachineForm extends StatefulWidget {
  final MachineFormControllers controllers;
  final VoidCallback
  onUpdate; // Call to refresh UI if needed (e.g. date picker)

  const MachineForm({
    super.key,
    required this.controllers,
    required this.onUpdate,
  });

  @override
  State<MachineForm> createState() => _MachineFormState();
}

class _MachineFormState extends State<MachineForm> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controllers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Machine Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        buildTextField(
          controller: c.name,
          label: 'Name of Machine',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        buildTextField(
          controller: c.code,
          label: 'Machine Code',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        buildTextField(controller: c.manufacturer, label: 'Manufacturer'),
        buildTextField(controller: c.model, label: 'Model Number'),
        buildTextField(controller: c.serial, label: 'Serial Number'),
        buildTextField(controller: c.location, label: 'Location'),

        const SizedBox(height: 16),
        const Text(
          'Technical Capability',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        buildTextField(
          controller: c.ratedCapacity,
          label: 'Rated Capacity (kg/hr)',
          keyboardType: TextInputType.number,
        ),
        buildTextField(
          controller: c.powerConsumption,
          label: 'Power Consumption (kW/hr)',
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 16),
        const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            c.dateOfPurchase == null
                ? 'Select Date of Purchase'
                : 'Purchased: ${c.dateOfPurchase.toString().split(' ')[0]}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await pickDate(context, initialDate: c.dateOfPurchase);
            if (d != null) {
              c.dateOfPurchase = d;
              widget.onUpdate();
            }
          },
        ),
        buildDropdown<MaintenanceStatus>(
          value: c.status,
          items: MaintenanceStatus.values,
          labelBuilder: (s) => s.name.toUpperCase(),
          onChanged: (v) {
            if (v != null) {
              c.status = v;
              widget.onUpdate();
            }
          },
          label: 'Current Status',
        ),

        const SizedBox(height: 16),
        const Text(
          'Maintenance Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        buildDropdown<CriticalityLevel>(
          value: c.criticality,
          items: CriticalityLevel.values,
          labelBuilder: (s) => s.name.toUpperCase(),
          onChanged: (v) {
            if (v != null) {
              c.criticality = v;
              widget.onUpdate();
            }
          },
          label: 'Criticality Level',
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            c.lastMaintenanceDate == null
                ? 'Select Last Maintenance Date'
                : 'Last Maint.: ${c.lastMaintenanceDate.toString().split(' ')[0]}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await pickDate(
              context,
              initialDate: c.lastMaintenanceDate,
            );
            if (d != null) {
              c.lastMaintenanceDate = d;
              widget.onUpdate();
            }
          },
        ),
        buildTextField(
          controller: c.maintenanceCycle,
          label: 'Maintenance Cycle (Days)',
          keyboardType: TextInputType.number,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),

        // Auto-calculated next date display
        if (c.lastMaintenanceDate != null &&
            int.tryParse(c.maintenanceCycle.text) != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Next Maintenance Date: ${c.lastMaintenanceDate!.add(Duration(days: int.parse(c.maintenanceCycle.text))).toString().split(' ')[0]}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
      ],
    );
  }
}

// ==================== Major Assembly Form ====================

class MajorAssemblyFormControllers {
  final name = TextEditingController();
  void dispose() {
    name.dispose();
  }
}

class MajorAssemblyForm extends StatelessWidget {
  final MajorAssemblyFormControllers controllers;
  const MajorAssemblyForm({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Major Assembly Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        buildTextField(
          controller: controllers.name,
          label: 'Name of Major Assembly',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}

// ==================== Sub Assembly Form ====================

class SubAssemblyFormControllers {
  final name = TextEditingController();
  void dispose() {
    name.dispose();
  }
}

class SubAssemblyForm extends StatelessWidget {
  final SubAssemblyFormControllers controllers;
  const SubAssemblyForm({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sub Assembly Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        buildTextField(
          controller: controllers.name,
          label: 'Name of Sub Assembly',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}

// ==================== Component Form ====================

class ComponentFormControllers {
  final name = TextEditingController();
  final model = TextEditingController();
  final brand = TextEditingController();
  final spec = TextEditingController();
  final maintenanceCycle = TextEditingController();

  final stock = TextEditingController();
  final reorder = TextEditingController();
  final location = TextEditingController();
  final shelfLife = TextEditingController();

  CriticalityLevel criticality = CriticalityLevel.critical;
  DateTime? lastMaintenanceDate;

  // Suppliers (List of controllers/data)
  List<Supplier> suppliers = [];

  void dispose() {
    name.dispose();
    model.dispose();
    brand.dispose();
    spec.dispose();
    maintenanceCycle.dispose();
    stock.dispose();
    reorder.dispose();
    location.dispose();
    shelfLife.dispose();
  }
}

class ComponentForm extends StatefulWidget {
  final ComponentFormControllers controllers;
  final VoidCallback onUpdate;

  const ComponentForm({
    super.key,
    required this.controllers,
    required this.onUpdate,
  });

  @override
  State<ComponentForm> createState() => _ComponentFormState();
}

class _ComponentFormState extends State<ComponentForm> {
  // Local controllers for adding a supplier
  final _supName = TextEditingController();
  final _supAddr = TextEditingController();
  final _supContact = TextEditingController();
  final _supNumber = TextEditingController();
  final _supRate = TextEditingController();

  void _addSupplier() {
    if (_supName.text.isEmpty) return;
    setState(() {
      widget.controllers.suppliers.add(
        Supplier(
          name: _supName.text,
          address: _supAddr.text,
          contactName: _supContact.text,
          contactNumber: _supNumber.text,
          lastPurchasedRate: double.tryParse(_supRate.text),
        ),
      );
      _supName.clear();
      _supAddr.clear();
      _supContact.clear();
      _supNumber.clear();
      _supRate.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controllers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Component Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        buildTextField(
          controller: c.name,
          label: 'Component Name',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        buildTextField(controller: c.model, label: 'Model Number'),
        buildTextField(controller: c.brand, label: 'Manufacturer / Brand'),
        buildTextField(controller: c.spec, label: 'Specification'),

        const SizedBox(height: 16),
        const Text(
          'Maintenance Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        buildDropdown<CriticalityLevel>(
          value: c.criticality,
          items: CriticalityLevel.values,
          labelBuilder: (s) => s.name.toUpperCase(),
          onChanged: (v) {
            if (v != null) {
              c.criticality = v;
              widget.onUpdate();
            }
          },
          label: 'Criticality Level',
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            c.lastMaintenanceDate == null
                ? 'Select Last Maintenance Date'
                : 'Last Maint.: ${c.lastMaintenanceDate.toString().split(' ')[0]}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await pickDate(
              context,
              initialDate: c.lastMaintenanceDate,
            );
            if (d != null) {
              c.lastMaintenanceDate = d;
              widget.onUpdate();
            }
          },
        ),
        buildTextField(
          controller: c.maintenanceCycle,
          label: 'Maintenance Cycle (Days)',
          keyboardType: TextInputType.number,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),

        if (c.lastMaintenanceDate != null &&
            int.tryParse(c.maintenanceCycle.text) != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Next Maintenance Date: ${c.lastMaintenanceDate!.add(Duration(days: int.parse(c.maintenanceCycle.text))).toString().split(' ')[0]}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),

        const SizedBox(height: 16),
        const Text('Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        buildTextField(
          controller: c.stock,
          label: 'Current Stock',
          keyboardType: TextInputType.number,
        ),
        buildTextField(
          controller: c.reorder,
          label: 'Reorder Level',
          keyboardType: TextInputType.number,
        ),
        buildTextField(controller: c.location, label: 'Location'),
        buildTextField(
          controller: c.shelfLife,
          label: 'Shelf Life (Days)',
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 16),
        const Text('Suppliers', style: TextStyle(fontWeight: FontWeight.bold)),
        ...c.suppliers.map(
          (s) => ListTile(
            title: Text(s.name),
            subtitle: Text('${s.contactName} - ${s.contactNumber}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => setState(() => c.suppliers.remove(s)),
            ),
          ),
        ),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const Text('Add Supplier'),
                buildTextField(controller: _supName, label: 'Name'),
                buildTextField(controller: _supAddr, label: 'Address'),
                buildTextField(controller: _supContact, label: 'Contact Name'),
                buildTextField(controller: _supNumber, label: 'Contact Number'),
                buildTextField(
                  controller: _supRate,
                  label: 'Last Purchased Rate',
                  keyboardType: TextInputType.number,
                ),
                ElevatedButton(
                  onPressed: _addSupplier,
                  child: const Text('Add Supplier'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
