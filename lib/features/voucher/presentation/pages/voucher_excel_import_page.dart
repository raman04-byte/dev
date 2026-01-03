import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../excel/src/import/excel_import_service.dart';
import '../../../../shared/widgets/signature_pad_widget.dart';
import '../../data/repositories/voucher_repository_impl.dart';
import '../../domain/models/voucher_model.dart';
import '../../domain/models/voucher_signature_model.dart';
import '../../../../common/common_progress.dart';

class VoucherExcelImportPage extends StatefulWidget {
  final String stateName;
  final String stateCode;
  final String? filePath;

  const VoucherExcelImportPage({
    super.key,
    required this.stateName,
    required this.stateCode,
    this.filePath,
  });

  @override
  State<VoucherExcelImportPage> createState() => _VoucherExcelImportPageState();
}

class _VoucherExcelImportPageState extends State<VoucherExcelImportPage> {
  final _voucherRepository = VoucherRepositoryImpl();

  bool _isLoading = false;
  bool _isImporting = false;
  List<VoucherModel> _parsedVouchers = [];
  File? _selectedFile;
  String? _errorMessage;
  int _importedCount = 0;
  int _failedCount = 0;
  List<String> _errorLogs = [];

  // Signature storage - one pair per voucher
  List<Uint8List?> _recipientSignatures = [];
  List<Uint8List?> _staffSignatures = [];

  // Staff signature caching
  Map<String, String> _cachedSignatureUrls = {}; // name -> URL
  final Map<String, Uint8List> _downloadedSignatures = {}; // URL -> bytes
  bool _signaturesLoaded = false;

  // Required column mappings
  final Map<String, String> _columnMappings = {
    'S.No.': 'serialNo',
    'Farmer Name': 'farmerName',
    'Date': 'date',
    'Address': 'address',
    'File Reg No.': 'fileRegNo',
    'Amount Of Expenses': 'amountOfExpenses', // Note: typo in requirement
    'Staff Name & Designation': 'staffNameDesignation',
    'Mode of Payment': 'modeOfPayment',
    'Recipient Name': 'recipientName',
    'Recipient Address': 'recipientAddress',
    'Nature of Expenses [According to Govt. Guidelines]': 'natureOfExpenses',
    'Being amount paid/payable towards the following expenditure':
        'amountToBePaid',
  };

  @override
  void initState() {
    super.initState();
    // If file path is provided, automatically parse it
    if (widget.filePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final file = File(widget.filePath!);
        setState(() {
          _selectedFile = file;
        });
        _parseExcelFile(file);
      });
    }
  }

  Future<void> _pickExcelFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _selectedFile = file;
        });
        await _parseExcelFile(file);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _parseExcelFile(File file) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _parsedVouchers = [];
      });

      final data = await ExcelImportService.parseExcelFile(file);

      if (data.isEmpty) {
        setState(() {
          _errorMessage = 'No data found in Excel file';
        });
        return;
      }

      // Validate columns
      final columnNames = ExcelImportService.getColumnNames(data);
      final missingColumns = <String>[];

      for (final requiredColumn in _columnMappings.keys) {
        if (!columnNames.contains(requiredColumn)) {
          missingColumns.add(requiredColumn);
        }
      }

      if (missingColumns.isNotEmpty) {
        setState(() {
          _errorMessage =
              'Missing required columns: ${missingColumns.join(', ')}';
        });
        return;
      }

      _parseVouchers(data);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error parsing Excel file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _parseVouchers(List<Map<String, dynamic>> data) {
    final vouchers = <VoucherModel>[];
    final errors = <String>[];

    for (int i = 0; i < data.length; i++) {
      try {
        final row = data[i];
        final rowNumber =
            i + 2; // +2 because Excel rows start at 1 and first is header

        // Parse date
        DateTime? date;
        try {
          final dateStr = row['Date']?.toString().trim() ?? '';
          if (dateStr.isNotEmpty) {
            // Try multiple date formats
            try {
              date = DateFormat('dd/MM/yyyy').parse(dateStr);
            } catch (e) {
              try {
                date = DateFormat('yyyy-MM-dd').parse(dateStr);
              } catch (e) {
                try {
                  date = DateFormat('dd-MM-yyyy').parse(dateStr);
                } catch (e) {
                  date = DateTime.now();
                  errors.add('Row $rowNumber: Invalid date format "$dateStr"');
                }
              }
            }
          } else {
            date = DateTime.now();
          }
        } catch (e) {
          date = DateTime.now();
          errors.add('Row $rowNumber: Error parsing date - $e');
        }

        // Parse amount robustly
        int amount = 0;
        try {
          final dynamic amountCell = row['Amount Of Expenses'];
          if (amountCell == null) {
            amount = 0;
          } else if (amountCell is num) {
            amount = amountCell.toInt();
          } else {
            // Handle strings like "3,894", "3894.00", "3.894E+3", "₹3,894" etc.
            String amountStr = amountCell.toString().trim();
            // Remomal point and exponentve common grouping separators and currency symbols but keep digits, deci
            amountStr = amountStr.replaceAll(RegExp(r'[ ,₹$€£]'), '');
            // Remove any characters except digits, dot, minus, plus and exponent letters
            amountStr = amountStr.replaceAll(RegExp(r'[^0-9eE\.\-\+]'), '');

            if (amountStr.isEmpty) {
              amount = 0;
            } else {
              try {
                final doubleVal = double.parse(amountStr);
                amount = doubleVal.round();
              } catch (e) {
                // Fallback: try parsing integers only
                amount =
                    int.tryParse(amountStr.replaceAll(RegExp('[^0-9-]'), '')) ??
                    0;
              }
            }
          }
        } catch (e) {
          errors.add('Row $rowNumber: Error parsing amount - $e');
        }

        // Get other fields
        final farmerName = row['Farmer Name']?.toString().trim() ?? '';
        final address = row['Address']?.toString().trim() ?? '';
        final fileRegNo = row['File Reg No.']?.toString().trim() ?? '';
        final staffNameDesignation =
            row['Staff Name & Designation']?.toString().trim() ?? '';
        final modeOfPayment =
            row['Mode of Payment']?.toString().trim() ?? 'Cash';
        final recipientName = row['Recipient Name']?.toString().trim();
        final recipientAddress = row['Recipient Address']?.toString().trim();
        final natureOfExpenses =
            row['Nature of Expenses [According to Govt. Guidelines]']
                ?.toString()
                .trim() ??
            '';
        final amountToBePaid =
            row['Being amount paid/payable towards the following expenditure']
                ?.toString()
                .trim() ??
            '';

        // Validate required fields
        if (farmerName.isEmpty) {
          errors.add('Row $rowNumber: Farmer Name is required');
          continue;
        }
        if (fileRegNo.isEmpty) {
          errors.add('Row $rowNumber: File Reg No. is required');
          continue;
        }

        final voucher = VoucherModel(
          farmerName: farmerName,
          date: date,
          address: address,
          fileRegNo: fileRegNo,
          amountOfExpenses: amount,
          expensesBy: staffNameDesignation,
          natureOfExpenses: natureOfExpenses.isEmpty ? [] : [natureOfExpenses],
          amountToBePaid: amountToBePaid.isEmpty ? [] : [amountToBePaid],
          state: widget.stateCode,
          paymentMode: modeOfPayment.toLowerCase().contains('cash')
              ? 'Cash'
              : 'Credit',
          recipientName: recipientName?.isNotEmpty == true
              ? recipientName
              : null,
          recipientAddress: recipientAddress?.isNotEmpty == true
              ? recipientAddress
              : null,
        );

        vouchers.add(voucher);
      } catch (e) {
        errors.add('Row ${i + 2}: Error creating voucher - $e');
      }
    }

    setState(() {
      _parsedVouchers = vouchers;
      _errorLogs = errors;
    });
  }

  /// Load all staff signatures from database and cache them
  Future<void> _loadStaffSignatures() async {
    if (_signaturesLoaded) return; // Already loaded

    try {
      final signatures = await _voucherRepository.getAllStaffSignatures();

      // Build mapping of name -> signature URL
      final Map<String, String> urlMap = {};
      for (final sig in signatures) {
        if (sig.name.isNotEmpty && sig.signatureImageUrl.isNotEmpty) {
          // Normalize name for matching (trim and lowercase)
          final normalizedName = sig.name.trim().toLowerCase();
          urlMap[normalizedName] = sig.signatureImageUrl;
        }
      }

      setState(() {
        _cachedSignatureUrls = urlMap;
        _signaturesLoaded = true;
      });
    } catch (e) {
      // If loading fails, continue with manual signatures
      setState(() {
        _signaturesLoaded = true;
      });
    }
  }

  /// Attempt to get staff signature from cache, returns null if not found
  Future<Uint8List?> _getStaffSignatureFromCache(String staffName) async {
    if (staffName.isEmpty) return null;

    // Normalize staff name for matching
    final normalizedName = staffName.trim().toLowerCase();

    // Check if we have a signature URL for this staff name
    final signatureUrl = _cachedSignatureUrls[normalizedName];
    if (signatureUrl == null) return null;

    // Check if we already downloaded this signature
    if (_downloadedSignatures.containsKey(signatureUrl)) {
      return _downloadedSignatures[signatureUrl];
    }

    // Download the signature
    try {
      final signatureBytes = await _voucherRepository.downloadSignatureFromUrl(
        signatureUrl,
      );

      if (signatureBytes != null) {
        // Cache the downloaded signature
        setState(() {
          _downloadedSignatures[signatureUrl] = signatureBytes;
        });
        return signatureBytes;
      }
    } catch (e) {
      // Download failed, return null to fall back to manual
    }

    return null;
  }

  Future<void> _collectSignatures() async {
    // Load staff signatures from database first
    await _loadStaffSignatures();

    // Reset signature lists
    _recipientSignatures = [];
    _staffSignatures = [];

    final totalVouchers = _parsedVouchers.length;

    // Collect signatures for each voucher
    for (int i = 0; i < totalVouchers; i++) {
      final voucherNumber = i + 1;
      final farmerName = _parsedVouchers[i].farmerName;
      final recipientName = _parsedVouchers[i].recipientName ?? farmerName;
      final staffName = _parsedVouchers[i].expensesBy;

      Uint8List? recipientSig;
      Uint8List? staffSig;

      // Show recipient signature dialog for this voucher
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: SignaturePadWidget(
            title:
                'Recipient Signature ($voucherNumber of $totalVouchers)\n$recipientName',
            onSignatureSaved: (signature) {
              recipientSig = signature;
            },
            initialSignature: null,
          ),
        ),
      );

      // If user cancelled recipient signature, return
      if (recipientSig == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Import cancelled - No recipient signature for voucher $voucherNumber',
              ),
            ),
          );
        }
        return;
      }

      // Try to get staff signature from cache
      staffSig = await _getStaffSignatureFromCache(staffName);

      if (staffSig != null) {
        // Found matching signature! Show informational dialog
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Staff Signature Found'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Signature auto-filled for:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    staffName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Voucher: $voucherNumber of $totalVouchers',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // User wants to sign manually instead
                    Navigator.pop(context);

                    // Show manual signature dialog
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => WillPopScope(
                        onWillPop: () async => false,
                        child: SignaturePadWidget(
                          title:
                              'Staff Signature ($voucherNumber of $totalVouchers)\n$staffName',
                          onSignatureSaved: (signature) {
                            staffSig = signature;
                          },
                          initialSignature: null,
                        ),
                      ),
                    );

                    // Check if manual signature was provided
                    if (staffSig == null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Import cancelled - No staff signature for voucher $voucherNumber',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Sign Manually'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Use Auto-filled'),
                ),
              ],
            ),
          );
        }

        // If staffSig is null here, user chose manual but cancelled
        if (staffSig == null) {
          return;
        }
      } else {
        // No matching signature found, show manual signature dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: SignaturePadWidget(
              title:
                  'Staff Signature ($voucherNumber of $totalVouchers)\n$staffName',
              onSignatureSaved: (signature) {
                staffSig = signature;
              },
              initialSignature: null,
            ),
          ),
        );

        // If user cancelled staff signature, return
        if (staffSig == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Import cancelled - No staff signature for voucher $voucherNumber',
                ),
              ),
            );
          }
          return;
        }
      }

      // Store signatures for this voucher
      _recipientSignatures.add(recipientSig);
      _staffSignatures.add(staffSig);
    }
  }

  Future<void> _importVouchers() async {
    if (_parsedVouchers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No vouchers to import')));
      return;
    }

    // Collect signatures before importing
    await _collectSignatures();

    // If user cancelled signature collection, return
    if (_recipientSignatures.length != _parsedVouchers.length ||
        _staffSignatures.length != _parsedVouchers.length) {
      return;
    }

    setState(() {
      _isImporting = true;
      _importedCount = 0;
      _failedCount = 0;
      _errorLogs.clear();
    });

    // Import vouchers in batches
    final int batchSize = 5;
    for (int i = 0; i < _parsedVouchers.length; i += batchSize) {
      final end = (i + batchSize < _parsedVouchers.length)
          ? i + batchSize
          : _parsedVouchers.length;
      final batch = _parsedVouchers.sublist(i, end);
      
      // Process batch in parallel
      await Future.wait(
        batch.asMap().entries.map((entry) async {
          final index = i + entry.key; // Global index
          
          try {
            // Upload signatures
            String? recipientSigId;
            String? staffSigId;

            if (_recipientSignatures[index] != null) {
              recipientSigId = await ExcelImportService.retryOperation(
                () => _voucherRepository.uploadSignature(
                  _recipientSignatures[index]!,
                ),
                opName: 'Upload recipient signature',
              );
            }
            if (_staffSignatures[index] != null) {
              staffSigId = await ExcelImportService.retryOperation(
                () => _voucherRepository.uploadSignature(
                  _staffSignatures[index]!,
                ),
                opName: 'Upload staff signature',
              );
            }

            // Create voucher
            final voucherWithSignatures = VoucherModel(
              farmerName: _parsedVouchers[index].farmerName,
              date: _parsedVouchers[index].date,
              address: _parsedVouchers[index].address,
              fileRegNo: _parsedVouchers[index].fileRegNo,
              amountOfExpenses: _parsedVouchers[index].amountOfExpenses,
              expensesBy: _parsedVouchers[index].expensesBy,
              natureOfExpenses: _parsedVouchers[index].natureOfExpenses,
              amountToBePaid: _parsedVouchers[index].amountToBePaid,
              state: _parsedVouchers[index].state,
              receiverSignature: recipientSigId,
              payorSignature: staffSigId,
              paymentMode: _parsedVouchers[index].paymentMode,
              recipientName: _parsedVouchers[index].recipientName,
              recipientAddress: _parsedVouchers[index].recipientAddress,
            );

            await ExcelImportService.retryOperation(
              () => _voucherRepository.createVoucher(voucherWithSignatures),
              opName: 'Create voucher',
            );

            if (mounted) {
              setState(() {
                _importedCount++;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _failedCount++;
                _errorLogs.add('Failed to import voucher ${index + 1}: $e');
              });
            }
          }
        }),
      );
    }

    setState(() {
      _isImporting = false;
    });

    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                _failedCount == 0 ? Icons.check_circle : Icons.info,
                color: _failedCount == 0 ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              const Text('Import Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Successfully imported: $_importedCount'),
              if (_failedCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Failed: $_failedCount',
                  style: const TextStyle(color: Colors.red),
                ),
                if (_errorLogs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Error Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 150,
                    child: SingleChildScrollView(
                      child: Text(
                        _errorLogs.join('\n'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, _importedCount > 0);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Import from Excel'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.3),
                    AppColors.secondaryBlue.withOpacity(0.3),
                  ],
                ),
              ),
            ),
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
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CommonProgressIndicator(size: 150),
                      SizedBox(height: 16),
                      Text('Processing Excel file...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // File Selection Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                                      color: AppColors.primaryBlue.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.file_upload,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Select Excel File',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedFile != null
                                              ? _selectedFile!.path
                                                    .split('/')
                                                    .last
                                              : 'No file selected',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _pickExcelFile,
                                icon: const Icon(Icons.folder_open),
                                label: const Text('Choose File'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Required Format Info
                      Card(
                        elevation: 2,
                        color: AppColors.primaryBlue.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primaryBlue,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Required Columns',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._columnMappings.keys.map((column) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: AppColors.primaryBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          column,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                      // Error Message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          color: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Preview and Import
                      if (_parsedVouchers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Preview',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${_parsedVouchers.length} vouchers',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_errorLogs.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_errorLogs.length} warnings',
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          height: 100,
                                          child: SingleChildScrollView(
                                            child: Text(
                                              _errorLogs.join('\n'),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 300,
                                  child: ListView.builder(
                                    itemCount: _parsedVouchers.length,
                                    itemBuilder: (context, index) {
                                      final voucher = _parsedVouchers[index];
                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    backgroundColor: AppColors
                                                        .primaryBlue
                                                        .withOpacity(0.1),
                                                    child: Text(
                                                      '${index + 1}',
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .primaryBlue,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          voucher.farmerName,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 15,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          'File: ${voucher.fileRegNo} | Amount: Rs. ${voucher.amountOfExpenses}',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    DateFormat(
                                                      'dd/MM/yyyy',
                                                    ).format(voucher.date),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              const Divider(height: 1),
                                              const SizedBox(height: 8),
                                              _buildDetailRow(
                                                'Address',
                                                voucher.address,
                                              ),
                                              if (voucher.recipientName !=
                                                      null &&
                                                  voucher
                                                      .recipientName!
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                _buildDetailRow(
                                                  'Recipient Name',
                                                  voucher.recipientName!,
                                                ),
                                              ],
                                              if (voucher.recipientAddress !=
                                                      null &&
                                                  voucher
                                                      .recipientAddress!
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                _buildDetailRow(
                                                  'Recipient Address',
                                                  voucher.recipientAddress!,
                                                ),
                                              ],
                                              if (voucher
                                                  .natureOfExpenses
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                _buildDetailRow(
                                                  'Nature of Expenses',
                                                  voucher.natureOfExpenses.join(
                                                    ', ',
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isImporting
                                        ? null
                                        : _importVouchers,
                                    icon: _isImporting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CommonProgressIndicator(
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.upload_file),
                                    label: Text(
                                      _isImporting
                                          ? 'Importing... ($_importedCount/${_parsedVouchers.length})'
                                          : 'Import Vouchers',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
