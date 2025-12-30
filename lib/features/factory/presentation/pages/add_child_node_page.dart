import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../domain/models/maintenance_nodes.dart';
import '../widgets/maintenance_forms.dart';

class AddChildNodePage extends StatefulWidget {
  final Type nodeType;
  final MaintenanceNode? node; // For editing

  const AddChildNodePage({super.key, required this.nodeType, this.node});

  @override
  State<AddChildNodePage> createState() => _AddChildNodePageState();
}

class _AddChildNodePageState extends State<AddChildNodePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  MajorAssemblyFormControllers? _majorControllers;
  SubAssemblyFormControllers? _subControllers;
  ComponentFormControllers? _compControllers;

  @override
  void initState() {
    super.initState();
    if (widget.nodeType == MajorAssemblyNode) {
      _majorControllers = MajorAssemblyFormControllers();
      if (widget.node != null && widget.node is MajorAssemblyNode) {
        _majorControllers!.name.text = widget.node!.name;
      }
    } else if (widget.nodeType == SubAssemblyNode) {
      _subControllers = SubAssemblyFormControllers();
      if (widget.node != null && widget.node is SubAssemblyNode) {
        _subControllers!.name.text = widget.node!.name;
      }
    } else if (widget.nodeType == ComponentNode) {
      _compControllers = ComponentFormControllers();
      if (widget.node != null && widget.node is ComponentNode) {
        final c = widget.node as ComponentNode;
        _compControllers!.name.text = c.name;
        _compControllers!.model.text = c.modelNumber;
        _compControllers!.brand.text = c.manufacturerOrBrand;
        _compControllers!.spec.text = c.specification;
        _compControllers!.maintenanceCycle.text = c.maintenanceCycleDays
            .toString();
        _compControllers!.stock.text = c.currentStockQuantity.toString();
        _compControllers!.reorder.text = c.reorderLevel.toString();
        _compControllers!.location.text = c.location;
        _compControllers!.shelfLife.text = c.shelfLifeDays?.toString() ?? '';

        _compControllers!.criticality = c.criticality;
        _compControllers!.lastMaintenanceDate = c.lastMaintenanceDate;
        _compControllers!.suppliers = List.from(c.suppliers); // Mutable copy
      }
    }
  }

  @override
  void dispose() {
    _majorControllers?.dispose();
    _subControllers?.dispose();
    _compControllers?.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    MaintenanceNode? newNode;
    final id = widget.node?.id ?? const Uuid().v4();
    final children = widget.node?.children ?? [];

    if (widget.nodeType == MajorAssemblyNode) {
      newNode = MajorAssemblyNode(
        id: id,
        name: _majorControllers!.name.text,
        children: children,
      );
    } else if (widget.nodeType == SubAssemblyNode) {
      newNode = SubAssemblyNode(
        id: id,
        name: _subControllers!.name.text,
        children: children,
      );
    } else if (widget.nodeType == ComponentNode) {
      // Validate dates
      if (_compControllers!.lastMaintenanceDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select maintenance date')),
        );
        return;
      }

      final cycle = int.parse(_compControllers!.maintenanceCycle.text);
      final lastDate = _compControllers!.lastMaintenanceDate!;

      newNode = ComponentNode(
        id: id,
        name: _compControllers!.name.text,
        modelNumber: _compControllers!.model.text,
        manufacturerOrBrand: _compControllers!.brand.text,
        specification: _compControllers!.spec.text,
        criticality: _compControllers!.criticality,
        lastMaintenanceDate: lastDate,
        maintenanceCycleDays: cycle,
        nextMaintenanceDate: lastDate.add(Duration(days: cycle)),
        suppliers: _compControllers!.suppliers,
        currentStockQuantity: int.tryParse(_compControllers!.stock.text) ?? 0,
        reorderLevel: int.tryParse(_compControllers!.reorder.text) ?? 0,
        location: _compControllers!.location.text,
        shelfLifeDays: int.tryParse(_compControllers!.shelfLife.text),
        children: children,
      );
    }

    if (newNode != null) {
      Navigator.pop(context, newNode);
    }
  }

  String _getTitle() {
    final prefix = widget.node == null ? 'Add' : 'Edit';
    if (widget.nodeType == MajorAssemblyNode) return '$prefix Major Assembly';
    if (widget.nodeType == SubAssemblyNode) return '$prefix Sub Assembly';
    if (widget.nodeType == ComponentNode) return '$prefix Component';
    return '$prefix Item';
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
                  children: [
                    if (widget.nodeType == MajorAssemblyNode)
                      MajorAssemblyForm(controllers: _majorControllers!),
                    if (widget.nodeType == SubAssemblyNode)
                      SubAssemblyForm(controllers: _subControllers!),
                    if (widget.nodeType == ComponentNode)
                      ComponentForm(
                        controllers: _compControllers!,
                        onUpdate: () => setState(() {}),
                      ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.node == null ? 'Save' : 'Update',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
