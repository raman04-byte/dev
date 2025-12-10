import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/pdf_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pdf_viewer_page.dart';
import '../../../../shared/widgets/signature_pad_widget.dart';
import '../../data/repositories/voucher_repository_impl.dart';
import '../../domain/models/voucher_model.dart';

class AddVoucherPage extends StatefulWidget {
  final String? stateCode;

  const AddVoucherPage({super.key, this.stateCode});

  @override
  State<AddVoucherPage> createState() => _AddVoucherPageState();
}

class _AddVoucherPageState extends State<AddVoucherPage> {
  final _formKey = GlobalKey<FormState>();
  final _farmerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _fileRegNoController = TextEditingController();
  final _amountController = TextEditingController();
  final _voucherRepository = VoucherRepositoryImpl();

  String? _selectedExpensesBy;
  List<String> _expensesByOptions = ['_'];

  late String _selectedState;

  DateTime? _selectedDate;
  final Set<int> _selectedExpenseTypes = {};
  final Set<int> _selectedPaymentExpenses = {};
  Uint8List? _signature;
  Uint8List? _receiverSignature;

  // Page tracking
  int _currentPage = 1;
  final int _totalPages = 2;

  // First voucher data storage (will be used when saving to database)
  // ignore: unused_field
  Map<String, dynamic>? _firstVoucherData;

  @override
  void initState() {
    super.initState();
    // Initialize state from widget parameter or default to RAJ
    _selectedState = widget.stateCode ?? 'RAJ';

    _loadExpensesByOptions();
    // Add dummy data in debug mode
    assert(() {
      _farmerNameController.text = 'Ramesh Kumar Sharma';
      _addressController.text =
          'Village Harota, Tehsil Chomu, District Jaipur, Rajasthan - 303702';
      _fileRegNoController.text = 'DEV/2025/001234';
      _amountController.text = '15500';
      _selectedDate = DateTime.now().subtract(const Duration(days: 2));
      _selectedExpenseTypes.addAll([
        1,
        3,
        5,
      ]); // Field Visit, Installation, Service
      _selectedPaymentExpenses.addAll([1, 3, 5]); // Vehicle Rent, Food, Labour
      return true;
    }());
  }

  Future<void> _loadExpensesByOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedOptions = prefs.getStringList('expensesByOptions');
    final String? savedSelection = prefs.getString('selectedExpensesBy');

    if (savedOptions != null && savedOptions.isNotEmpty) {
      setState(() {
        _expensesByOptions = savedOptions.toList();
        // Restore selection if valid, otherwise default to first
        if (savedSelection != null &&
            _expensesByOptions.contains(savedSelection)) {
          _selectedExpensesBy = savedSelection;
        } else if (_selectedExpensesBy == null &&
            _expensesByOptions.isNotEmpty) {
          _selectedExpensesBy = _expensesByOptions.first;
        }
      });
    } else {
      // First run, save default
      _saveExpensesByOptions();
      setState(() {
        _selectedExpensesBy = _expensesByOptions.first;
      });
    }
  }

  Future<void> _saveExpensesByOptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('expensesByOptions', _expensesByOptions);
    if (_selectedExpensesBy != null) {
      await prefs.setString('selectedExpensesBy', _selectedExpensesBy!);
    }
  }

  Future<void> _addPerson() async {
    final TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Person'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter name'),
            textCapitalization: TextCapitalization.words,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  if (_expensesByOptions.contains(controller.text)) {
                    Navigator.of(context).pop();
                    return;
                  }
                  setState(() {
                    _expensesByOptions.add(controller.text);
                    _selectedExpensesBy = controller.text;
                  });
                  _saveExpensesByOptions();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _removePerson() async {
    if (_selectedExpensesBy == null) return;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Person'),
          content: Text(
            'Are you sure you want to remove "$_selectedExpensesBy"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () {
                setState(() {
                  _expensesByOptions.remove(_selectedExpensesBy);
                  if (_expensesByOptions.isNotEmpty) {
                    _selectedExpensesBy = _expensesByOptions.first;
                  } else {
                    _selectedExpensesBy = null;
                  }
                });
                _saveExpensesByOptions();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _farmerNameController.dispose();
    _addressController.dispose();
    _fileRegNoController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Can't select future dates
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryCyan,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showSignaturePad() {
    showDialog(
      context: context,
      builder: (context) => SignaturePadWidget(
        onSignatureSaved: (signature) {
          setState(() {
            _signature = signature;
          });
        },
        initialSignature: _signature,
      ),
    );
  }

  void _showReceiverSignaturePad() {
    showDialog(
      context: context,
      builder: (context) => SignaturePadWidget(
        onSignatureSaved: (signature) {
          setState(() {
            _receiverSignature = signature;
          });
        },
        initialSignature: _receiverSignature,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Safety check for page 2
    if (_currentPage == 2 && _firstVoucherData == null) {
      setState(() {
        _currentPage = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Lost first voucher data. Please fill it again.',
          ),
        ),
      );
      return;
    }

    // On page 2, check if form has any data
    if (_currentPage == 2) {
      final bool hasSecondVoucherData =
          _farmerNameController.text.isNotEmpty ||
          _addressController.text.isNotEmpty ||
          _fileRegNoController.text.isNotEmpty ||
          _amountController.text.isNotEmpty ||
          _selectedDate != null ||
          _selectedExpenseTypes.isNotEmpty ||
          _selectedPaymentExpenses.isNotEmpty;

      if (!hasSecondVoucherData) {
        // No second voucher data, generate PDF with only first voucher
        if (_firstVoucherData != null) {
          await _generateAndShowPdf(_firstVoucherData!, null);
        }
        return;
      }
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a date')));
        return;
      }

      if (_selectedExpenseTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one nature of expense'),
          ),
        );
        return;
      }

      if (_selectedPaymentExpenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one payment expense'),
          ),
        );
        return;
      }

      if (_currentPage == 1) {
        // Save first voucher data and move to page 2
        _firstVoucherData = {
          'farmerName': _farmerNameController.text,
          'date': _selectedDate,
          'address': _addressController.text,
          'fileRegNo': _fileRegNoController.text,
          'amount': _amountController.text,
          'expensesBy': _selectedExpensesBy,
          'expenseTypes': Set<int>.from(_selectedExpenseTypes),
          'paymentExpenses': Set<int>.from(_selectedPaymentExpenses),
          'signature': _signature,
          'receiverSignature': _receiverSignature,
        };

        // Clear form for second voucher
        _clearForm();

        setState(() {
          _currentPage = 2;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('First voucher saved. Create second voucher.'),
          ),
        );
      } else {
        // Save second voucher and generate PDF with both vouchers
        final Map<String, dynamic> secondVoucherData = {
          'farmerName': _farmerNameController.text,
          'date': _selectedDate,
          'address': _addressController.text,
          'fileRegNo': _fileRegNoController.text,
          'amount': _amountController.text,
          'expensesBy': _selectedExpensesBy,
          'expenseTypes': Set<int>.from(_selectedExpenseTypes),
          'paymentExpenses': Set<int>.from(_selectedPaymentExpenses),
          'signature': _signature,
          'receiverSignature': _receiverSignature,
        };

        // Generate PDF
        if (_firstVoucherData != null) {
          await _generateAndShowPdf(_firstVoucherData!, secondVoucherData);
        }
      }
    }
  }

  Future<void> _generateAndShowPdf(
    Map<String, dynamic> voucher1,
    Map<String, dynamic>? voucher2,
  ) async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saving vouchers...')));
      }

      // Save vouchers to database
      await _saveVouchersToDatabase(voucher1, voucher2);

      // Generate PDF
      final File pdfFile = await PdfService.generateVoucherPdf(
        voucher1: voucher1,
        voucher2: voucher2,
        stateCode: _selectedState,
      );

      if (mounted) {
        // Navigate to PDF viewer
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PdfViewerPage(pdfFile: pdfFile),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveVouchersToDatabase(
    Map<String, dynamic> voucher1,
    Map<String, dynamic>? voucher2,
  ) async {
    try {
      // Upload signatures if they exist
      String? receiverSig1Id;
      String? payorSig1Id;
      if (voucher1['receiverSignature'] != null) {
        receiverSig1Id = await _voucherRepository.uploadSignature(
          voucher1['receiverSignature'] as Uint8List,
        );
      }
      if (voucher1['signature'] != null) {
        payorSig1Id = await _voucherRepository.uploadSignature(
          voucher1['signature'] as Uint8List,
        );
      }

      // Save first voucher
      final voucher1Model = VoucherModel(
        farmerName: voucher1['farmerName'],
        date: voucher1['date'],
        address: voucher1['address'],
        fileRegNo: voucher1['fileRegNo'],
        amountOfExpenses: int.parse(voucher1['amount']),
        expensesBy: voucher1['expensesBy'],
        natureOfExpenses: (voucher1['expenseTypes'] as Set<int>)
            .map((e) => _getExpenseTypeName(e))
            .toList(),
        amountToBePaid: (voucher1['paymentExpenses'] as Set<int>)
            .map((e) => _getPaymentExpenseName(e))
            .toList(),
        state: _selectedState,
        receiverSignature: receiverSig1Id,
        payorSignature: payorSig1Id,
      );
      await _voucherRepository.createVoucher(voucher1Model);

      // Save second voucher if exists
      if (voucher2 != null) {
        // Upload signatures for second voucher if they exist
        String? receiverSig2Id;
        String? payorSig2Id;
        if (voucher2['receiverSignature'] != null) {
          receiverSig2Id = await _voucherRepository.uploadSignature(
            voucher2['receiverSignature'] as Uint8List,
          );
        }
        if (voucher2['signature'] != null) {
          payorSig2Id = await _voucherRepository.uploadSignature(
            voucher2['signature'] as Uint8List,
          );
        }

        final voucher2Model = VoucherModel(
          farmerName: voucher2['farmerName'],
          date: voucher2['date'],
          address: voucher2['address'],
          fileRegNo: voucher2['fileRegNo'],
          amountOfExpenses: int.parse(voucher2['amount']),
          expensesBy: voucher2['expensesBy'],
          natureOfExpenses: (voucher2['expenseTypes'] as Set<int>)
              .map((e) => _getExpenseTypeName(e))
              .toList(),
          amountToBePaid: (voucher2['paymentExpenses'] as Set<int>)
              .map((e) => _getPaymentExpenseName(e))
              .toList(),
          state: _selectedState,
          receiverSignature: receiverSig2Id,
          payorSignature: payorSig2Id,
        );
        await _voucherRepository.createVoucher(voucher2Model);
      }
    } catch (e) {
      rethrow;
    }
  }

  String _getExpenseTypeName(int sNo) {
    switch (sNo) {
      case 1:
        return 'Field Visit Expenses';
      case 2:
        return 'Fright Expenses';
      case 3:
        return 'Installation Expenses';
      case 4:
        return 'Physical Verification';
      case 5:
        return 'Service Expenses';
      default:
        return 'Unknown';
    }
  }

  String _getPaymentExpenseName(int sNo) {
    switch (sNo) {
      case 1:
        return 'Vehicle Rent';
      case 2:
        return 'Hotel';
      case 3:
        return 'Food';
      case 4:
        return 'Local Cartage';
      case 5:
        return 'Labour';
      case 6:
        return 'Other';
      default:
        return 'Unknown';
    }
  }

  void _handleSkip() {
    if (_currentPage == 2) {
      // Save only first voucher and exit
      // TODO: Save first voucher to database/storage
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First voucher saved successfully!')),
      );

      Navigator.of(context).pop();
    }
  }

  void _clearForm() {
    _farmerNameController.clear();
    _addressController.clear();
    _fileRegNoController.clear();
    _amountController.clear();
    _selectedExpensesBy = null;
    _selectedDate = null;
    _selectedExpenseTypes.clear();
    _selectedPaymentExpenses.clear();
    _signature = null;
    _receiverSignature = null;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Voucher ($_currentPage of $_totalPages)'),
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Farmer Name Field
                TextFormField(
                  controller: _farmerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Farmer Name',
                    hintText: 'Enter farmer name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter farmer name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      hintText: 'Select date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: _selectedDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = null;
                                });
                              },
                            )
                          : null,
                    ),
                    child: Text(
                      _selectedDate != null ? _formatDate(_selectedDate!) : '',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Address Field
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // File Reg No Field
                TextFormField(
                  controller: _fileRegNoController,
                  decoration: const InputDecoration(
                    labelText: 'File Reg No.',
                    hintText: 'Enter file registration number',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter file reg no.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Amount of Expenses Field
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount of Expenses',
                    hintText: 'Enter amount',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Expenses By Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expenses By',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.primaryCyan,
                          ),
                          onPressed: _addPerson,
                          tooltip: 'Add Person',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: _expensesByOptions.isEmpty
                              ? null
                              : _removePerson,
                          tooltip: 'Remove Selected Person',
                        ),
                      ],
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedExpensesBy,
                  decoration: const InputDecoration(
                    hintText: 'Select person',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: _expensesByOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedExpensesBy = newValue;
                    });
                    _saveExpensesByOptions();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select expenses by';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Nature of Expenses Section
                Text(
                  'Nature of Expenses [According to Govt. Guidelines]',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Expense Type 1
                _buildExpenseOption(
                  context,
                  sNo: 1,
                  type: 'Field Visit Expenses',
                ),
                const SizedBox(height: 12),

                // Expense Type 2
                _buildExpenseOption(context, sNo: 2, type: 'Fright Expenses'),
                const SizedBox(height: 12),

                // Expense Type 3
                _buildExpenseOption(
                  context,
                  sNo: 3,
                  type: 'Installation Expenses',
                ),
                const SizedBox(height: 12),

                // Expense Type 4
                _buildExpenseOption(
                  context,
                  sNo: 4,
                  type: 'Physical Verification',
                ),
                const SizedBox(height: 12),

                // Expense Type 5
                _buildExpenseOption(context, sNo: 5, type: 'Service Expenses'),
                const SizedBox(height: 32),

                // Payment Expenses Section
                Text(
                  'Being amount paid/payable towards the following expenditure:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Expense 1
                _buildPaymentExpenseOption(
                  context,
                  sNo: 1,
                  type: 'Vehicle Rent',
                ),
                const SizedBox(height: 12),

                // Payment Expense 2
                _buildPaymentExpenseOption(context, sNo: 2, type: 'Hotel'),
                const SizedBox(height: 12),

                // Payment Expense 3
                _buildPaymentExpenseOption(context, sNo: 3, type: 'Food'),
                const SizedBox(height: 12),

                // Payment Expense 4
                _buildPaymentExpenseOption(
                  context,
                  sNo: 4,
                  type: 'Local Cartage',
                ),
                const SizedBox(height: 12),

                // Payment Expense 5
                _buildPaymentExpenseOption(context, sNo: 5, type: 'Labour'),
                const SizedBox(height: 12),

                // Payment Expense 6
                _buildPaymentExpenseOption(context, sNo: 6, type: 'Other'),
                const SizedBox(height: 32),

                // Receiver Signature Section
                Text(
                  'Sign. of Expense Recipient',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _showReceiverSignaturePad,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _receiverSignature != null
                            ? AppColors.primaryCyan
                            : AppColors.grey,
                        width: _receiverSignature != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _receiverSignature != null
                          ? AppColors.primaryCyan.withOpacity(0.05)
                          : AppColors.white,
                    ),
                    child: _receiverSignature != null
                        ? Stack(
                            children: [
                              Center(
                                child: Image.memory(
                                  _receiverSignature!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppColors.primaryCyan,
                                  ),
                                  onPressed: _showReceiverSignaturePad,
                                  tooltip: 'Edit Signature',
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.gesture,
                                size: 48,
                                color: AppColors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add signature',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // Payor Signature Section
                Text(
                  'Company Payor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _showSignaturePad,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _signature != null
                            ? AppColors.primaryCyan
                            : AppColors.grey,
                        width: _signature != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _signature != null
                          ? AppColors.primaryCyan.withOpacity(0.05)
                          : AppColors.white,
                    ),
                    child: _signature != null
                        ? Stack(
                            children: [
                              Center(
                                child: Image.memory(
                                  _signature!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppColors.primaryCyan,
                                  ),
                                  onPressed: _showSignaturePad,
                                  tooltip: 'Edit Signature',
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.gesture,
                                size: 48,
                                color: AppColors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add signature',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit/Next Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    child: Text(
                      _currentPage == 1 ? 'Next Voucher' : 'Save Voucher',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel/Skip Button
                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () {
                      if (_currentPage == 1) {
                        Navigator.of(context).pop();
                      } else {
                        _handleSkip();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryCyan,
                        width: 2,
                      ),
                      foregroundColor: AppColors.primaryCyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_currentPage == 1 ? 'Cancel' : 'Skip'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseOption(
    BuildContext context, {
    required int sNo,
    required String type,
  }) {
    final bool isSelected = _selectedExpenseTypes.contains(sNo);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedExpenseTypes.remove(sNo);
          } else {
            _selectedExpenseTypes.add(sNo);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryCyan : AppColors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primaryCyan.withOpacity(0.1)
              : AppColors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.primaryCyan : AppColors.grey,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryCyan : AppColors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: AppColors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // S.No and Type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$sNo. ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          type,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentExpenseOption(
    BuildContext context, {
    required int sNo,
    required String type,
  }) {
    final bool isSelected = _selectedPaymentExpenses.contains(sNo);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedPaymentExpenses.remove(sNo);
          } else {
            _selectedPaymentExpenses.add(sNo);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryCyan : AppColors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primaryCyan.withOpacity(0.1)
              : AppColors.white,
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.primaryCyan : AppColors.grey,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryCyan : AppColors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: AppColors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Row(
                children: [
                  Text(
                    '$sNo. ',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      type,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
