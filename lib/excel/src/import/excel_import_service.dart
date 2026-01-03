import 'dart:io';
import 'dart:typed_data';
import '../../excel.dart';

/// Service for importing data from Excel files
class ExcelImportService {
  /// Parse an Excel file and return the data as a list of maps
  /// Each map represents a row with column names as keys
  static Future<List<Map<String, dynamic>>> parseExcelFile(
    File file, {
    int headerRow = 0, // Zero-indexed for excel package
    String? sheetName,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      return parseExcelBytes(bytes, headerRow: headerRow, sheetName: sheetName);
    } catch (e) {
      throw Exception('Failed to read Excel file: $e');
    }
  }

  /// Parse Excel data from bytes
  static List<Map<String, dynamic>> parseExcelBytes(
    Uint8List bytes, {
    int headerRow = 0, // Zero-indexed
    String? sheetName,
  }) {
    try {
      // Decode Excel file
      final excel = Excel.decodeBytes(bytes);

      // Get the sheet to work with
      Sheet? sheet;
      if (sheetName != null && excel.tables.containsKey(sheetName)) {
        sheet = excel.tables[sheetName];
      } else {
        // Get first sheet
        if (excel.tables.isNotEmpty) {
          sheet = excel.tables.values.first;
        }
      }

      if (sheet == null) {
        throw Exception('No worksheet found in Excel file');
      }

      final List<Map<String, dynamic>> data = [];

      // Extract headers from header row
      final List<String> headers = [];
      if (sheet.rows.isEmpty || headerRow >= sheet.rows.length) {
        return data;
      }

      final headerRowData = sheet.rows[headerRow];
      for (int col = 0; col < headerRowData.length; col++) {
        final cell = headerRowData[col];
        final cellValue = cell?.value?.toString() ?? 'Column$col';
        headers.add(cellValue);
      }

      // Extract data rows
      for (int row = headerRow + 1; row < sheet.rows.length; row++) {
        final rowData = sheet.rows[row];
        final Map<String, dynamic> dataRow = {};
        bool hasData = false;

        for (int col = 0; col < headers.length && col < rowData.length; col++) {
          final cell = rowData[col];
          final cellValue = cell?.value;

          if (cellValue != null && cellValue.toString().isNotEmpty) {
            hasData = true;
          }

          dataRow[headers[col]] = cellValue?.toString() ?? '';
        }

        // Only add rows that have some data
        if (hasData) {
          data.add(dataRow);
        }
      }

      return data;
    } catch (e) {
      throw Exception('Failed to parse Excel data: $e');
    }
  }

  /// Get sheet names from an Excel file
  static Future<List<String>> getSheetNames(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      return excel.tables.keys.toList();
    } catch (e) {
      throw Exception('Failed to get sheet names: $e');
    }
  }

  /// Validate that required columns exist in the Excel data
  static bool validateColumns(
    List<Map<String, dynamic>> data,
    List<String> requiredColumns,
  ) {
    if (data.isEmpty) return false;

    final firstRow = data.first;
    for (final column in requiredColumns) {
      if (!firstRow.containsKey(column)) {
        return false;
      }
    }
    return true;
  }

  /// Get column names from Excel data
  static List<String> getColumnNames(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];
    return data.first.keys.toList();
  }

  /// Retry an operation multiple times with a delay
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 5,
    Duration delay = const Duration(seconds: 1),
    String opName = 'Operation',
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= maxRetries) {
          rethrow;
        }
        print('$opName failed (attempt $attempts/$maxRetries): $e. Retrying...');
        await Future.delayed(delay);
      }
    }
  }
}
