import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/pdf_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
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

  String _paymentMode = 'Cash'; // Default to Cash

  late String _selectedState;

  DateTime? _selectedDate;
  int? _selectedExpenseType;
  int? _selectedPaymentExpense;
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
      _selectedExpenseType = 1; // Field Visit
      _selectedPaymentExpense = 1; // Vehicle Rent
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
          _selectedExpenseType != null ||
          _selectedPaymentExpense != null;

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

      if (_selectedExpenseType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select nature of expense')),
        );
        return;
      }

      if (_selectedPaymentExpense == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select payment expense')),
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
          'expenseType': _selectedExpenseType,
          'paymentExpense': _selectedPaymentExpense,
          'signature': _signature,
          'receiverSignature': _receiverSignature,
          'paymentMode': _paymentMode,
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
          'expenseType': _selectedExpenseType,
          'paymentExpense': _selectedPaymentExpense,
          'signature': _signature,
          'receiverSignature': _receiverSignature,
          'paymentMode': _paymentMode,
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
        natureOfExpenses: voucher1['expenseType'] != null
            ? [_getExpenseTypeName(voucher1['expenseType'] as int)]
            : [],
        amountToBePaid: voucher1['paymentExpense'] != null
            ? [_getPaymentExpenseName(voucher1['paymentExpense'] as int)]
            : [],
        state: _selectedState,
        receiverSignature: receiverSig1Id,
        payorSignature: payorSig1Id,
        paymentMode: voucher1['paymentMode'],
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
          natureOfExpenses: voucher2['expenseType'] != null
              ? [_getExpenseTypeName(voucher2['expenseType'] as int)]
              : [],
          amountToBePaid: voucher2['paymentExpense'] != null
              ? [_getPaymentExpenseName(voucher2['paymentExpense'] as int)]
              : [],
          state: _selectedState,
          receiverSignature: receiverSig2Id,
          payorSignature: payorSig2Id,
          paymentMode: voucher2['paymentMode'],
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
    _selectedExpenseType = null;
    _selectedPaymentExpense = null;
    _signature = null;
    _receiverSignature = null;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: Glassmorphism.appBar(
        title: Text(
          'Add Voucher ($_currentPage of $_totalPages)',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.systemGray6,
              AppColors.white,
              AppColors.primaryBlue.withOpacity(0.02),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
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
                        _selectedDate != null
                            ? _formatDate(_selectedDate!)
                            : '',
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
                        'Expense Recipient Name :-',
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

                  // Payment Mode Section
                  Text(
                    'Mode of Payment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Cash'),
                          value: 'Cash',
                          groupValue: _paymentMode,
                          onChanged: (value) {
                            setState(() {
                              _paymentMode = value!;
                            });
                          },
                          activeColor: AppColors.primaryCyan,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Credit'),
                          value: 'Credit',
                          groupValue: _paymentMode,
                          onChanged: (value) {
                            setState(() {
                              _paymentMode = value!;
                            });
                          },
                          activeColor: AppColors.primaryCyan,
                        ),
                      ),
                    ],
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

                  // Expense Type Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryCyan),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedExpenseType,
                        isExpanded: true,
                        hint: const Text(
                          'Select Nature of Expense',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('1. Field Visit Expenses'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('2. Fright Expenses'),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text('3. Installation Expenses'),
                          ),
                          DropdownMenuItem(
                            value: 4,
                            child: Text('4. Physical Verification'),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text('5. Service Expenses'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedExpenseType = value;
                          });
                        },
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
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

                  // Payment Expense Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryCyan),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedPaymentExpense,
                        isExpanded: true,
                        hint: const Text(
                          'Select Payment Expenditure',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('1. Vehicle Rent'),
                          ),
                          DropdownMenuItem(value: 2, child: Text('2. Hotel')),
                          DropdownMenuItem(value: 3, child: Text('3. Food')),
                          DropdownMenuItem(
                            value: 4,
                            child: Text('4. Local Cartage'),
                          ),
                          DropdownMenuItem(value: 5, child: Text('5. Labour')),
                          DropdownMenuItem(value: 6, child: Text('6. Other')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentExpense = value;
                          });
                        },
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
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
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
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
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
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
      ),
    );
  }
}
