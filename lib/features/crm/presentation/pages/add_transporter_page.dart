import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../data/repositories/transporter_repository_impl.dart';
import '../../domain/models/transporter_model.dart';

class AddTransporterPage extends StatefulWidget {
  const AddTransporterPage({super.key});

  @override
  State<AddTransporterPage> createState() => _AddTransporterPageState();
}

class _AddTransporterPageState extends State<AddTransporterPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = TransporterRepositoryImpl();

  final _transportNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _remarksController = TextEditingController();
  final _rsPerCartonController = TextEditingController();
  final _rsPerKgController = TextEditingController();

  bool _isSaving = false;
  List<String> _deliveryPinCodes = [];
  List<String> _deliveryStates = [];

  TransporterModel? _editingTransporter;
  bool get _isEditing => _editingTransporter != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get transporter from route arguments if editing
    final transporter =
        ModalRoute.of(context)?.settings.arguments as TransporterModel?;
    if (transporter != null && _editingTransporter == null) {
      _editingTransporter = transporter;
      _populateFields(transporter);
    }
  }

  void _populateFields(TransporterModel transporter) {
    _transportNameController.text = transporter.transportName;
    _addressController.text = transporter.address;
    _gstNumberController.text = transporter.gstNumber;
    _contactNameController.text = transporter.contactName;
    _contactNumberController.text = transporter.contactNumber;
    _remarksController.text = transporter.remarks;
    _rsPerCartonController.text = transporter.rsPerCarton.toString();
    _rsPerKgController.text = transporter.rsPerKg.toString();
    _deliveryPinCodes = List.from(transporter.deliveryPinCodes);
    _deliveryStates = List.from(transporter.deliveryStates);
  }

  @override
  void dispose() {
    _transportNameController.dispose();
    _addressController.dispose();
    _gstNumberController.dispose();
    _contactNameController.dispose();
    _contactNumberController.dispose();
    _remarksController.dispose();
    _rsPerCartonController.dispose();
    _rsPerKgController.dispose();
    super.dispose();
  }

  Future<void> _saveTransporter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final transporter = TransporterModel(
        id: _editingTransporter?.id,
        transportName: _transportNameController.text.trim(),
        address: _addressController.text.trim(),
        gstNumber: _gstNumberController.text.trim(),
        contactName: _contactNameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        remarks: _remarksController.text.trim(),
        deliveryPinCodes: _deliveryPinCodes,
        deliveryStates: _deliveryStates,
        rsPerCarton: double.tryParse(_rsPerCartonController.text.trim()) ?? 0.0,
        rsPerKg: double.tryParse(_rsPerKgController.text.trim()) ?? 0.0,
        createdAt: _editingTransporter?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (_isEditing && _editingTransporter!.id != null) {
        await _repository.updateTransporter(
          _editingTransporter!.id!,
          transporter,
        );
      } else {
        await _repository.createTransporter(transporter);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Transporter updated successfully'
                  : 'Transporter added successfully',
            ),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transporter: $e'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
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
              title: Text(
                _isEditing ? 'Edit Transporter' : 'Add Transporter',
                style: const TextStyle(
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
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              children: [
                Glassmorphism.card(
                  blur: 15,
                  opacity: 0.7,
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transporter Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _transportNameController,
                        label: 'Transport Name',
                        icon: Icons.local_shipping_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter transport name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _gstNumberController,
                        label: 'GST Number',
                        icon: Icons.receipt_long_outlined,
                        inputFormatters: [LengthLimitingTextInputFormatter(15)],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _contactNameController,
                        label: 'Contact Name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter contact name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _contactNumberController,
                        label: 'Contact Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter contact number';
                          }
                          if (value.trim().length != 10) {
                            return 'Contact number must be 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _remarksController,
                        label: 'Remarks',
                        icon: Icons.note_outlined,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter remarks';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDeliveryToField(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Glassmorphism.card(
                  blur: 15,
                  opacity: 0.7,
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pricing Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _rsPerCartonController,
                        label: 'Rs Per Carton',
                        icon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _rsPerKgController,
                        label: 'Rs Per Kg',
                        icon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Glassmorphism.card(
                  blur: 15,
                  opacity: 0.5,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSaving ? null : _saveTransporter,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isSaving
                                ? [
                                    AppColors.textSecondary.withOpacity(0.5),
                                    AppColors.textSecondary.withOpacity(0.3),
                                  ]
                                : [
                                    AppColors.primaryBlue,
                                    AppColors.secondaryBlue,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isSaving
                            ? const Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isEditing ? Icons.update : Icons.add,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isEditing
                                        ? 'Update Transporter'
                                        : 'Add Transporter',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 22),
        filled: true,
        fillColor: AppColors.white.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryBlue.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryBlue.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentPink),
        ),
      ),
    );
  }

  Widget _buildDeliveryToField() {
    String getDisplayText() {
      if (_deliveryPinCodes.isEmpty && _deliveryStates.isEmpty) {
        return 'Select delivery locations';
      }

      List<String> parts = [];
      if (_deliveryPinCodes.isNotEmpty) {
        parts.add(
          '${_deliveryPinCodes.length} PIN${_deliveryPinCodes.length > 1 ? 's' : ''}',
        );
      }
      if (_deliveryStates.isNotEmpty) {
        parts.add(
          '${_deliveryStates.length} State${_deliveryStates.length > 1 ? 's' : ''}',
        );
      }

      return parts.join(', ');
    }

    return InkWell(
      onTap: () => _showDeliveryDialog(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.primaryBlue,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery To',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getDisplayText(),
                    style: TextStyle(
                      color:
                          _deliveryPinCodes.isEmpty && _deliveryStates.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryBlue,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeliveryDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _DeliveryDialog(
        initialPinCodes: List.from(_deliveryPinCodes),
        initialStates: List.from(_deliveryStates),
        onSave: (pinCodes, states) {
          setState(() {
            _deliveryPinCodes = pinCodes;
            _deliveryStates = states;
          });
        },
      ),
    );
  }
}

class _DeliveryDialog extends StatefulWidget {
  final List<String> initialPinCodes;
  final List<String> initialStates;
  final Function(List<String>, List<String>) onSave;

  const _DeliveryDialog({
    required this.initialPinCodes,
    required this.initialStates,
    required this.onSave,
  });

  @override
  State<_DeliveryDialog> createState() => _DeliveryDialogState();
}

class _DeliveryDialogState extends State<_DeliveryDialog> {
  int _selectedSegment = 0; // 0 for PIN, 1 for State
  late List<String> _pinCodes;
  late List<String> _selectedStates;
  final _pinController = TextEditingController();
  final Map<String, Map<String, String>> _pinCodeDetails = {};
  bool _isLoadingPinCode = false;

  // All Indian states
  final List<String> _allStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  @override
  void initState() {
    super.initState();
    _pinCodes = List.from(widget.initialPinCodes);
    _selectedStates = List.from(widget.initialStates);
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _addPinCode() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty || pin.length != 6 || _pinCodes.contains(pin)) {
      return;
    }

    setState(() {
      _isLoadingPinCode = true;
    });

    try {
      final details = await _getPincodeDetails(pin);
      if (details != null && mounted) {
        setState(() {
          _pinCodes.add(pin);
          _pinCodeDetails[pin] = details;
          _pinController.clear();
          _isLoadingPinCode = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingPinCode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid PIN code or details not found'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPinCode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching PIN code details: $e'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    }
  }

  Future<Map<String, String>?> _getPincodeDetails(String pincode) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.postalpincode.in/pincode/$pincode'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[0]['Status'] == 'Success' && data[0]['PostOffice'] != null) {
          final postOffice = data[0]['PostOffice'][0];
          return {
            'district': postOffice['District'] ?? '',
            'state': postOffice['State'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _removePinCode(String pin) {
    setState(() {
      _pinCodes.remove(pin);
      _pinCodeDetails.remove(pin);
    });
  }

  void _toggleState(String state) {
    setState(() {
      if (_selectedStates.contains(state)) {
        _selectedStates.remove(state);
      } else {
        _selectedStates.add(state);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Delivery Locations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Segmented Button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedSegment = 0),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedSegment == 0
                                  ? AppColors.primaryBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'By PIN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedSegment == 0
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedSegment = 1),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedSegment == 1
                                  ? AppColors.primaryBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'By State',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedSegment == 1
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _selectedSegment == 0
                      ? _buildPinCodeSection()
                      : _buildStateSection(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    widget.onSave(_pinCodes, _selectedStates);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinCodeSection() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'Enter PIN code',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) => _addPinCode(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addPinCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingPinCode)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_pinCodes.isEmpty &&
              _selectedStates.isEmpty &&
              !_isLoadingPinCode)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No PIN codes or states added',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else if (!_isLoadingPinCode)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Show selected states as coverage areas
                  if (_selectedStates.isNotEmpty) ...[
                    ...(_selectedStates.map((state) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.map,
                              color: AppColors.accentGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          state,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accentGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'All PINs in this state',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.accentPink,
                                size: 20,
                              ),
                              onPressed: () => _toggleState(state),
                            ),
                          ],
                        ),
                      );
                    })),
                    if (_pinCodes.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(),
                      ),
                  ],
                  // Show specific PIN codes
                  ...(_pinCodes.map((pin) {
                    final details = _pinCodeDetails[pin];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.push_pin,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pin,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                if (details != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_city,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          details['district'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.map,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          details['state'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.accentPink,
                              size: 20,
                            ),
                            onPressed: () => _removePinCode(pin),
                          ),
                        ],
                      ),
                    );
                  })),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_selectedStates.length} state${_selectedStates.length != 1 ? 's' : ''} selected',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _allStates.length,
            itemBuilder: (context, index) {
              final state = _allStates[index];
              final isSelected = _selectedStates.contains(state);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => _toggleState(state),
                  title: Text(state, style: const TextStyle(fontSize: 15)),
                  activeColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isSelected
                      ? AppColors.primaryBlue.withOpacity(0.1)
                      : AppColors.systemGray6,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
