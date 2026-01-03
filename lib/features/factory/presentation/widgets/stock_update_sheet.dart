import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../domain/models/maintenance_nodes.dart';

class StockUpdateSheet extends StatefulWidget {
  final ComponentNode component;
  final Function(int qty, Supplier? newSupplier, bool isStockIn) onSave;

  const StockUpdateSheet({
    super.key,
    required this.component,
    required this.onSave,
  });

  @override
  State<StockUpdateSheet> createState() => _StockUpdateSheetState();
}

class _StockUpdateSheetState extends State<StockUpdateSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _qtyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Supplier logic
  Supplier? _selectedSupplier;
  bool _isAddingSupplier = false;

  // New Supplier Form
  final _supNameCtrl = TextEditingController();
  final _supContactCtrl = TextEditingController();
  final _supPhoneCtrl = TextEditingController();
  final _supAddressCtrl = TextEditingController();
  final _supPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qtyController.dispose();
    _supNameCtrl.dispose();
    _supContactCtrl.dispose();
    _supPhoneCtrl.dispose();
    _supAddressCtrl.dispose();
    _supPriceCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final qty = int.parse(_qtyController.text);
    final isStockIn = _tabController.index == 0;

    Supplier? newSupplier;
    if (isStockIn && _isAddingSupplier) {
      if (_supNameCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier Name is required')),
        );
        return;
      }
      newSupplier = Supplier(
        name: _supNameCtrl.text,
        address: _supAddressCtrl.text,
        contactName: _supContactCtrl.text,
        contactNumber: _supPhoneCtrl.text,
        lastPurchasedRate: double.tryParse(_supPriceCtrl.text),
      );
    }

    widget.onSave(qty, newSupplier, isStockIn);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Determine height based on state to avoid overflow or too much space
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.extension,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.component.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Current Stock: ${widget.component.currentStockQuantity}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tabs
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.systemGray6,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      onTap: (_) => setState(() {}),
                      tabs: const [
                        Tab(text: 'Stock IN'),
                        Tab(text: 'Stock OUT'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Qty Input
                  TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final n = int.tryParse(value);
                      if (n == null || n <= 0) return 'Invalid Number';
                      if (_tabController.index == 1 &&
                          n > widget.component.currentStockQuantity) {
                        return 'Not enough stock';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Supplier Section (Only for Stock IN)
                  if (_tabController.index == 0) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    // Toggle: Existing vs New
                    Row(
                      children: [
                        const Text(
                          'Supplier:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: Icon(
                            _isAddingSupplier ? Icons.list : Icons.add,
                          ),
                          label: Text(
                            _isAddingSupplier ? 'Select Existing' : 'Add New',
                          ),
                          onPressed: () {
                            setState(() {
                              _isAddingSupplier = !_isAddingSupplier;
                            });
                          },
                        ),
                      ],
                    ),

                    if (_isAddingSupplier)
                      _buildNewSupplierForm()
                    else
                      _buildExistingSupplierDropdown(),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _tabController.index == 0
                            ? 'Add to Stock'
                            : 'Deduct Stock',
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
    );
  }

  Widget _buildExistingSupplierDropdown() {
    if (widget.component.suppliers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No suppliers linked yet. Click "Add New" to create one.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return DropdownButtonFormField<Supplier>(
      value: _selectedSupplier,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      hint: const Text('Select Supplier'),
      items: widget.component.suppliers.map((s) {
        return DropdownMenuItem(value: s, child: Text(s.name));
      }).toList(),
      onChanged: (val) => setState(() => _selectedSupplier = val),
    );
  }

  Widget _buildNewSupplierForm() {
    return Column(
      children: [
        TextFormField(
          controller: _supNameCtrl,
          decoration: const InputDecoration(labelText: 'Company Name'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _supContactCtrl,
                decoration: const InputDecoration(labelText: 'Contact Person'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _supPhoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _supAddressCtrl,
          decoration: const InputDecoration(labelText: 'Address'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _supPriceCtrl,
          decoration: const InputDecoration(
            labelText: 'Purchase Rate (Optional)',
            prefixText: '₹ ',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}
