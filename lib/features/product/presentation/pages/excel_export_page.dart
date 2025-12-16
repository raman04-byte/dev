import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../../../core/theme/app_colors.dart';
import '../../../category/data/repositories/category_repository_impl.dart';
import '../../../category/domain/models/category_model.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/models/product_model.dart';

class ExcelExportPage extends StatefulWidget {
  final Map<String, bool> selectedFields;

  const ExcelExportPage({super.key, required this.selectedFields});

  @override
  State<ExcelExportPage> createState() => _ExcelExportPageState();
}

class _ExcelExportPageState extends State<ExcelExportPage> {
  final _productRepository = ProductRepositoryImpl();
  final _categoryRepository = CategoryRepositoryImpl();
  List<ProductModel> _products = [];
  Map<String, CategoryModel> _categoriesMap = {};
  bool _isLoading = true;
  bool _isExporting = false;
  xlsio.Workbook? _workbook;
  xlsio.Worksheet? _worksheet;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _workbook?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final products = await _productRepository.getProducts();
      final categories = await _categoryRepository.getCategories();

      // Create a map for quick category lookup
      final categoryMap = <String, CategoryModel>{};
      for (final category in categories) {
        categoryMap[category.id] = category;
      }

      if (mounted) {
        setState(() {
          _products = products;
          _categoriesMap = categoryMap;
          _isLoading = false;
        });
        _generateExcel();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _generateExcel() {
    try {
      // Create a new Excel document
      _workbook = xlsio.Workbook();
      _worksheet = _workbook!.worksheets[0];
      _worksheet!.name = 'Products';

      // Style the header
      final xlsio.Style headerStyle = _workbook!.styles.add('HeaderStyle');
      headerStyle.bold = true;
      headerStyle.fontSize = 12;
      headerStyle.fontColor = '#FFFFFF';
      headerStyle.backColor = '#1565C0';
      headerStyle.hAlign = xlsio.HAlignType.center;
      headerStyle.vAlign = xlsio.VAlignType.center;

      // Add headers
      int colIndex = 1;
      final headers = <String>[];

      widget.selectedFields.forEach((field, isSelected) {
        if (isSelected) {
          headers.add(field);
          _worksheet!.getRangeByIndex(1, colIndex).setText(field);
          _worksheet!.getRangeByIndex(1, colIndex).cellStyle = headerStyle;
          colIndex++;
        }
      });

      // Add data rows
      int rowIndex = 2;
      for (final product in _products) {
        // If product has variants, create a row for each variant
        if (product.sizes.isNotEmpty) {
          for (final variant in product.sizes) {
            _addDataRow(rowIndex, product, variant, headers);
            rowIndex++;
          }
        } else {
          // Product without variants
          _addDataRow(rowIndex, product, null, headers);
          rowIndex++;
        }
      }

      // Auto-fit columns
      for (int i = 1; i <= headers.length; i++) {
        _worksheet!.autoFitColumn(i);
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating Excel: $e')));
    }
  }

  void _addDataRow(
    int rowIndex,
    ProductModel product,
    ProductSize? variant,
    List<String> headers,
  ) {
    int colIndex = 1;

    for (final header in headers) {
      String value = '';

      switch (header) {
        case 'Product Name':
          value = product.name;
          break;
        case 'HSN Code':
          value = product.hsnCode;
          break;
        case 'Unit':
          value = product.unit;
          break;
        case 'Description':
          value = product.description;
          break;
        case 'Sale GST':
          value = '${product.saleGst}%';
          break;
        case 'Purchase GST':
          value = '${product.purchaseGst}%';
          break;
        case 'Category':
          if (product.categoryId != null) {
            final category = _categoriesMap[product.categoryId];
            value = category?.name ?? 'N/A';
          } else {
            value = 'N/A';
          }
          break;
        case 'Created At':
          value = DateFormat('dd/MM/yyyy HH:mm').format(product.createdAt);
          break;
        case 'Updated At':
          value = DateFormat('dd/MM/yyyy HH:mm').format(product.updatedAt);
          break;
        case 'Variant Name':
          value = variant?.sizeName ?? 'N/A';
          break;
        case 'Product Code':
          value = variant?.productCode ?? 'N/A';
          break;
        case 'Barcode':
          value = variant?.barcode ?? 'N/A';
          break;
        case 'MRP':
          value = variant != null
              ? '₹${variant.mrp.toStringAsFixed(2)}'
              : 'N/A';
          break;
        case 'Stock Quantity':
          value = variant?.stockQuantity.toString() ?? 'N/A';
          break;
        case 'Reorder Point':
          value = variant?.reorderPoint.toString() ?? 'N/A';
          break;
        case 'Packaging Size':
          value = variant?.packagingSize.toString() ?? 'N/A';
          break;
        case 'Weight':
          value = variant != null ? '${variant.weight} kg' : 'N/A';
          break;
      }

      _worksheet!.getRangeByIndex(rowIndex, colIndex).setText(value);
      colIndex++;
    }
  }

  Future<void> _exportExcel() async {
    if (_workbook == null) return;

    setState(() => _isExporting = true);

    try {
      // Save the workbook
      final List<int> bytes = _workbook!.saveAsStream();

      // Get the directory to save
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/Products_Export_$timestamp.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (mounted) {
        setState(() => _isExporting = false);

        // Show success and share options
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel file saved: $filePath'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Share the file
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Products Export',
          text: 'Products data exported on $timestamp',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting Excel: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Excel Export Preview'),
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
        actions: [
          if (!_isLoading && _worksheet != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _isExporting ? null : _exportExcel,
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download, color: Colors.white),
                label: Text(
                  _isExporting ? 'Exporting...' : 'Export',
                  style: const TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
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
              AppColors.white,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading products and generating Excel...'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Info Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Icons.info_outline,
                                  color: AppColors.primaryBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Export Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Total Products',
                            _products.length.toString(),
                          ),
                          _buildInfoRow(
                            'Total Rows',
                            _getTotalRows().toString(),
                          ),
                          _buildInfoRow(
                            'Selected Fields',
                            widget.selectedFields.values
                                .where((v) => v)
                                .length
                                .toString(),
                          ),
                        ],
                      ),
                    ),
                    // Excel Preview
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryBlue.withOpacity(0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: _buildExcelPreview(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalRows() {
    int total = 0;
    for (final product in _products) {
      if (product.sizes.isNotEmpty) {
        total += product.sizes.length;
      } else {
        total += 1;
      }
    }
    return total;
  }

  Widget _buildExcelPreview() {
    if (_worksheet == null) {
      return const Center(child: Text('No data to preview'));
    }

    // Get the used range
    final lastRow = _worksheet!.getLastRow();
    final lastColumn = _worksheet!.getLastColumn();

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        AppColors.primaryBlue.withOpacity(0.1),
      ),
      border: TableBorder.all(
        color: AppColors.primaryBlue.withOpacity(0.2),
        width: 1,
      ),
      columnSpacing: 20,
      horizontalMargin: 12,
      columns: List.generate(lastColumn, (colIndex) {
        final cellValue =
            _worksheet!.getRangeByIndex(1, colIndex + 1).text ?? '';
        return DataColumn(
          label: Text(
            cellValue,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        );
      }),
      rows: List.generate(
        lastRow - 1 > 50 ? 50 : lastRow - 1, // Show max 50 rows in preview
        (rowIndex) {
          return DataRow(
            cells: List.generate(lastColumn, (colIndex) {
              final cellValue =
                  _worksheet!
                      .getRangeByIndex(rowIndex + 2, colIndex + 1)
                      .text ??
                  '';
              return DataCell(
                Text(cellValue, style: const TextStyle(fontSize: 13)),
              );
            }),
          );
        },
      ),
    );
  }
}
