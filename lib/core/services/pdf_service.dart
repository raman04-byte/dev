import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  static Future<File> generateVoucherPdf({
    required Map<String, dynamic> voucher1,
    Map<String, dynamic>? voucher2,
    required String stateCode,
  }) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 0;
    final PdfPage page = document.pages.add();

    // Get page size
    final Size pageSize = page.getClientSize();

    // Load logo
    final ByteData logoData = await rootBundle.load('assets/images/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();

    // Load font
    // Note: The custom font 'Hemi Head Bd It.otf' is causing a crash in the Syncfusion PDF library
    // (TtfReader._readLocaTable null check error). Using standard font as fallback.
    final PdfFont headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      30,
      style: PdfFontStyle.bold,
    );
    /*
    try {
      final ByteData fontData = await rootBundle.load(
        'assets/fonts/Hemi Head Bd It.otf',
      );
      final Uint8List fontBytes = fontData.buffer.asUint8List();
      headerFont = PdfTrueTypeFont(fontBytes, 18);
    } catch (e) {
      headerFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        18,
        style: PdfFontStyle.bold,
      );
    }
    */

    // Draw first voucher
    _drawVoucher(
      page,
      voucher1,
      20,
      pageSize,
      logoBytes,
      headerFont,
      stateCode,
    );

    // Draw second voucher if exists
    if (voucher2 != null) {
      // Draw divider line
      final PdfPen dividerPen = PdfPen(PdfColor(0, 0, 0), width: 1);
      dividerPen.dashStyle = PdfDashStyle.dash;
      page.graphics.drawLine(
        dividerPen,
        Offset(0, pageSize.height / 2),
        Offset(pageSize.width, pageSize.height / 2),
      );

      _drawVoucher(
        page,
        voucher2,
        pageSize.height / 2 + 20,
        pageSize,
        logoBytes,
        headerFont,
        stateCode,
      );
    }

    // Save the document
    final List<int> bytes = await document.save();
    document.dispose();

    // Save to file
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path =
        '${directory.path}/voucher_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File(path);
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Generate a single PDF with multiple vouchers across multiple pages
  static Future<File> generateMultiVoucherPdf({
    required List<Map<String, dynamic>> vouchers,
    required String stateCode,
  }) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 0;

    // Load logo once
    final ByteData logoData = await rootBundle.load('assets/images/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();

    // Load font once
    final PdfFont headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      30,
      style: PdfFontStyle.bold,
    );

    // Process vouchers in pairs (2 per page)
    for (int i = 0; i < vouchers.length; i += 2) {
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();

      // Draw first voucher on this page
      _drawVoucher(
        page,
        vouchers[i],
        20,
        pageSize,
        logoBytes,
        headerFont,
        stateCode,
      );

      // Draw second voucher if exists
      if (i + 1 < vouchers.length) {
        // Draw divider line
        final PdfPen dividerPen = PdfPen(PdfColor(0, 0, 0), width: 1);
        dividerPen.dashStyle = PdfDashStyle.dash;
        page.graphics.drawLine(
          dividerPen,
          Offset(0, pageSize.height / 2),
          Offset(pageSize.width, pageSize.height / 2),
        );

        _drawVoucher(
          page,
          vouchers[i + 1],
          pageSize.height / 2 + 20,
          pageSize,
          logoBytes,
          headerFont,
          stateCode,
        );
      }
    }

    // Save the document
    final List<int> bytes = await document.save();
    document.dispose();

    // Save to file
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path =
        '${directory.path}/vouchers_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File(path);
    await file.writeAsBytes(bytes);

    return file;
  }

  static void _drawVoucher(
    PdfPage page,
    Map<String, dynamic> voucherData,
    double yOffset,
    Size pageSize,
    Uint8List logoBytes,
    PdfFont headerFont,
    String stateCode,
  ) {
    // Extract signatures if exist
    final Uint8List? payorSignature = voucherData['signature'] as Uint8List?;
    final Uint8List? receiverSignature =
        voucherData['receiverSignature'] as Uint8List?;
    final PdfGraphics graphics = page.graphics;

    // Header section with logo and company info
    _drawHeader(graphics, yOffset, logoBytes, headerFont, stateCode);

    double currentY = yOffset + 55;

    // Title and GSTIN
    _drawTitle(graphics, currentY, stateCode);
    currentY += 25;

    // Nature of Expenses table
    final dynamic rawExpenseTypes = voucherData['expenseTypes'];
    final Set<int> expenseTypes = rawExpenseTypes is Iterable
        ? Set<int>.from(rawExpenseTypes)
        : {};

    _drawExpensesTable(graphics, currentY, expenseTypes);
    currentY += 135;

    // Form fields
    _drawFormFields(graphics, currentY, voucherData);
    currentY += 70;

    // Payment expenses checkboxes
    final dynamic rawPaymentExpenses = voucherData['paymentExpenses'];
    final Set<int> paymentExpenses = rawPaymentExpenses is Iterable
        ? Set<int>.from(rawPaymentExpenses)
        : {};

    _drawPaymentExpenses(graphics, currentY, paymentExpenses);
    currentY += 45;

    // Footer signatures
    _drawFooter(graphics, currentY, payorSignature, receiverSignature);
  }

  static void _drawHeader(
    PdfGraphics graphics,
    double yOffset,
    Uint8List logoBytes,
    PdfFont headerFont,
    String stateCode,
  ) {
    // Draw logo
    final PdfBitmap logo = PdfBitmap(logoBytes);
    graphics.drawImage(logo, Rect.fromLTWH(15, yOffset, 40, 40));

    // Company name
    graphics.drawString(
      'Dev Polymers',
      headerFont,
      bounds: Rect.fromLTWH(65, yOffset, 250, 40),
      brush: PdfBrushes.black,
      format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.middle),
    );

    // Company details
    String companyInfo;
    if (stateCode == 'RAJ') {
      companyInfo =
          'H.O. : Dev Complex, N.H.52, Sikar Road, Harota, Chomu, Jaipur (Raj) - 303702\n'
          'Work : F-91&95, RIICO Ind. Area, Manda, Chomu, Jaipur, (Raj) - 303712\n'
          'Email : devpolymers07@gmail.com | Web : www.devpolymers.co.in';
    } else if (stateCode == 'UP') {
      companyInfo =
          'H.O. : Village Akola, Near UCO Bank, Post-Kagarol, Akola, AGRA-283102, Uttar Pradesh\n'
          'Email : devgstbill@gmail.com | Web : www.devpolymers.co.in';
    } else if (stateCode == 'JHR') {
      companyInfo =
          'H.O. : Flat No 101 Situated At, Savitri Apartment, In Vidyapati Nagar,\n'
          'Email : devgstbill@gmail.com | Web : www.devpolymers.co.in';
    } else {
      companyInfo =
          'H.O. : Dev Complex, N.H.52, Sikar Road, Harota, Chomu, Jaipur (Raj) - 303702\n'
          'Work : F-91&95, RIICO Ind. Area, Manda, Chomu, Jaipur, (Raj) - 303712\n'
          'Email : devpolymers07@gmail.com | Web : www.devpolymers.co.in';
    }

    graphics.drawString(
      companyInfo,
      PdfStandardFont(PdfFontFamily.helvetica, 7),
      bounds: Rect.fromLTWH(215, yOffset + 10, 360, 40),
      brush: PdfBrushes.black,
      format: PdfStringFormat(
        alignment: PdfTextAlignment.right,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );
  }

  static void _drawTitle(
    PdfGraphics graphics,
    double yOffset,
    String stateCode,
  ) {
    // EXPENSES VOUCHER title
    final PdfPen bluePen = PdfPen(PdfColor(0, 180, 216), width: 1);
    final PdfBrush bgBrush = PdfSolidBrush(PdfColor(200, 240, 255));

    // EXPENSES VOUCHER box
    final double boxWidth = 140;
    final double boxX = (595 - boxWidth) / 2 - 30;
    final double radius = 5;

    // Draw rounded rectangle for EXPENSES VOUCHER
    final PdfPath expensesPath = PdfPath();
    final Rect expBounds = Rect.fromLTWH(boxX, yOffset, boxWidth, 20);
    expensesPath.addArc(
      Rect.fromLTWH(
        expBounds.right - 2 * radius,
        expBounds.top,
        2 * radius,
        2 * radius,
      ),
      270,
      90,
    );
    expensesPath.addLine(
      Offset(expBounds.right, expBounds.top + radius),
      Offset(expBounds.right, expBounds.bottom - radius),
    );
    expensesPath.addArc(
      Rect.fromLTWH(
        expBounds.right - 2 * radius,
        expBounds.bottom - 2 * radius,
        2 * radius,
        2 * radius,
      ),
      0,
      90,
    );
    expensesPath.addLine(
      Offset(expBounds.right - radius, expBounds.bottom),
      Offset(expBounds.left + radius, expBounds.bottom),
    );
    expensesPath.addArc(
      Rect.fromLTWH(
        expBounds.left,
        expBounds.bottom - 2 * radius,
        2 * radius,
        2 * radius,
      ),
      90,
      90,
    );
    expensesPath.addLine(
      Offset(expBounds.left, expBounds.bottom - radius),
      Offset(expBounds.left, expBounds.top + radius),
    );
    expensesPath.addArc(
      Rect.fromLTWH(expBounds.left, expBounds.top, 2 * radius, 2 * radius),
      180,
      90,
    );
    expensesPath.addLine(
      Offset(expBounds.left + radius, expBounds.top),
      Offset(expBounds.right - radius, expBounds.top),
    );

    graphics.drawPath(expensesPath, pen: bluePen, brush: bgBrush);

    graphics.drawString(
      'EXPENSES VOUCHER',
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(boxX, yOffset + 3, boxWidth, 20),
      brush: PdfBrushes.black,
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // GSTIN box
    // Right aligned. Page width 595. Right margin ~30.
    // Box width reduced to 150.
    final double gstinBoxWidth = 150;
    final double gstinBoxX = 595 - 25 - gstinBoxWidth;

    // Draw rounded rectangle for GSTIN
    final PdfPath gstinPath = PdfPath();
    final Rect gstinBounds = Rect.fromLTWH(
      gstinBoxX,
      yOffset,
      gstinBoxWidth,
      20,
    );
    gstinPath.addArc(
      Rect.fromLTWH(
        gstinBounds.right - 2 * radius,
        gstinBounds.top,
        2 * radius,
        2 * radius,
      ),
      270,
      90,
    );
    gstinPath.addLine(
      Offset(gstinBounds.right, gstinBounds.top + radius),
      Offset(gstinBounds.right, gstinBounds.bottom - radius),
    );
    gstinPath.addArc(
      Rect.fromLTWH(
        gstinBounds.right - 2 * radius,
        gstinBounds.bottom - 2 * radius,
        2 * radius,
        2 * radius,
      ),
      0,
      90,
    );
    gstinPath.addLine(
      Offset(gstinBounds.right - radius, gstinBounds.bottom),
      Offset(gstinBounds.left + radius, gstinBounds.bottom),
    );
    gstinPath.addArc(
      Rect.fromLTWH(
        gstinBounds.left,
        gstinBounds.bottom - 2 * radius,
        2 * radius,
        2 * radius,
      ),
      90,
      90,
    );
    gstinPath.addLine(
      Offset(gstinBounds.left, gstinBounds.bottom - radius),
      Offset(gstinBounds.left, gstinBounds.top + radius),
    );
    gstinPath.addArc(
      Rect.fromLTWH(gstinBounds.left, gstinBounds.top, 2 * radius, 2 * radius),
      180,
      90,
    );
    gstinPath.addLine(
      Offset(gstinBounds.left + radius, gstinBounds.top),
      Offset(gstinBounds.right - radius, gstinBounds.top),
    );

    graphics.drawPath(gstinPath, pen: bluePen, brush: bgBrush);

    String gstinText;
    if (stateCode == 'RAJ') {
      gstinText = 'GSTIN : 08AEGPL8921D1ZI';
    } else if (stateCode == 'UP') {
      gstinText = 'GSTIN : 09AEGPL8921D1ZG';
    } else if (stateCode == 'JHR') {
      gstinText = 'GSTIN : 20AEGPL8921D1ZW';
    } else {
      gstinText = 'GSTIN : 08AEGPL8921D1ZI';
    }

    graphics.drawString(
      gstinText,
      PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(gstinBoxX, yOffset + 5, gstinBoxWidth - 5, 20),
      brush: PdfBrushes.black,
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
  }

  static void _drawExpensesTable(
    PdfGraphics graphics,
    double yOffset,
    Set<int> selectedTypes,
  ) {
    final PdfPen tablePen = PdfPen(PdfColor(0, 180, 216), width: 1);
    final PdfBrush headerBrush = PdfSolidBrush(PdfColor(200, 240, 255));

    // Table header
    graphics.drawRectangle(
      pen: tablePen,
      brush: headerBrush,
      bounds: Rect.fromLTWH(15, yOffset, 560, 18),
    );

    graphics.drawString(
      'Nature of Expenses [According to Govt. Guidelines]',
      PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(15, yOffset + 3, 560, 18),
      brush: PdfBrushes.black,
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Column headers
    yOffset += 18;
    graphics.drawRectangle(
      pen: tablePen,
      brush: headerBrush,
      bounds: Rect.fromLTWH(15, yOffset, 50, 18),
    );
    graphics.drawString(
      'S.N.',
      PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(20, yOffset + 3, 40, 18),
    );

    graphics.drawRectangle(
      pen: tablePen,
      brush: headerBrush,
      bounds: Rect.fromLTWH(65, yOffset, 165, 18),
    );
    graphics.drawString(
      'Type Of Expenses',
      PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(70, yOffset + 3, 155, 18),
    );

    graphics.drawRectangle(
      pen: tablePen,
      brush: headerBrush,
      bounds: Rect.fromLTWH(230, yOffset, 325, 18),
    );
    graphics.drawString(
      'Description of Expenses',
      PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(235, yOffset + 3, 315, 18),
    );

    graphics.drawRectangle(
      pen: tablePen,
      brush: headerBrush,
      bounds: Rect.fromLTWH(555, yOffset, 20, 18),
    );

    // Table rows
    final List<Map<String, String>> expenses = [
      {
        'sn': '1',
        'type': 'Field Visit Expenses',
        'desc':
            'Farmer Field Physical Verification, Soil & Water Testing, Map Designing, Geo-Tagging, KML File & Documents Collection for Subsidy File',
      },
      {
        'sn': '2',
        'type': 'Fright Expenses',
        'desc':
            'Material Supply from Company Warehouse to Farmer field + Loading/Unloading Charges',
      },
      {
        'sn': '3',
        'type': 'Installation Expenses',
        'desc':
            'Trenching Expenses + Drip System / Mini Sprinkler System / Portable Sprinkler Installation in field by labour (under the Guidance with Agronomist)',
      },
      {
        'sn': '4',
        'type': 'Physical Verification',
        'desc':
            'Field Physical Verification by Company Engineer & Govt. Agriculture Supervisor person (Appointed by Govt.)',
      },
      {
        'sn': '5',
        'type': 'Service Expenses',
        'desc':
            'Service Charge for any Issues in System & Expenses for providing separate guidance to farmer regarding product operation and maintenance of system as per guideline',
      },
    ];

    yOffset += 18;
    for (int i = 0; i < expenses.length; i++) {
      final bool isSelected = selectedTypes.contains(i + 1);

      // S.N.
      graphics.drawRectangle(
        pen: tablePen,
        bounds: Rect.fromLTWH(15, yOffset, 50, 18),
      );
      graphics.drawString(
        expenses[i]['sn'] ?? '',
        PdfStandardFont(PdfFontFamily.helvetica, 8),
        bounds: Rect.fromLTWH(20, yOffset + 5, 40, 18),
      );

      // Type
      graphics.drawRectangle(
        pen: tablePen,
        bounds: Rect.fromLTWH(65, yOffset, 165, 18),
      );
      graphics.drawString(
        expenses[i]['type'] ?? '',
        PdfStandardFont(PdfFontFamily.helvetica, 7, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(70, yOffset + 5, 155, 18),
      );

      // Description
      graphics.drawRectangle(
        pen: tablePen,
        bounds: Rect.fromLTWH(230, yOffset, 325, 18),
      );
      graphics.drawString(
        expenses[i]['desc'] ?? '',
        PdfStandardFont(PdfFontFamily.helvetica, 6),
        bounds: Rect.fromLTWH(235, yOffset + 2, 315, 18),
        format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.top),
      );

      // Checkbox column with small checkbox inside
      graphics.drawRectangle(
        pen: tablePen,
        bounds: Rect.fromLTWH(555, yOffset, 20, 18),
      );

      // Draw small checkbox square inside the cell
      final double checkboxSize = 10;
      final double checkboxX = 555 + (20 - checkboxSize) / 2;
      final double checkboxY = yOffset + (18 - checkboxSize) / 2;

      if (isSelected) {
        graphics.drawRectangle(
          pen: PdfPen(PdfColor(0, 0, 0), width: 0.5),
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
          bounds: Rect.fromLTWH(
            checkboxX,
            checkboxY,
            checkboxSize,
            checkboxSize,
          ),
        );

        // Draw checkmark inside the checkbox
        final PdfPen tickPen = PdfPen(PdfColor(255, 255, 255), width: 1);
        graphics.drawLine(
          tickPen,
          Offset(checkboxX + 2, checkboxY + 5),
          Offset(checkboxX + 4, checkboxY + 8),
        );
        graphics.drawLine(
          tickPen,
          Offset(checkboxX + 4, checkboxY + 8),
          Offset(checkboxX + 8, checkboxY + 2),
        );
      } else {
        graphics.drawRectangle(
          pen: PdfPen(PdfColor(0, 0, 0), width: 0.5),
          bounds: Rect.fromLTWH(
            checkboxX,
            checkboxY,
            checkboxSize,
            checkboxSize,
          ),
        );
      }

      yOffset += 18;
    }
  }

  static void _drawFormFields(
    PdfGraphics graphics,
    double yOffset,
    Map<String, dynamic> voucherData,
  ) {
    final PdfPen fieldPen = PdfPen(PdfColor(0, 180, 216), width: 1);

    // Column widths
    final double col1Width = 380;
    final double col2Width = 180;
    final double x1 = 15;
    final double x2 = 15 + col1Width;

    // Farmer Name and Date row
    graphics.drawRectangle(
      pen: fieldPen,
      bounds: Rect.fromLTWH(x1, yOffset, col1Width, 20),
    );
    graphics.drawString(
      'Farmer Name :-',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(x1 + 5, yOffset + 4, 100, 20),
      brush: PdfBrushes.black,
    );
    graphics.drawString(
      voucherData['farmerName'] ?? '',
      PdfStandardFont(PdfFontFamily.helvetica, 9),
      bounds: Rect.fromLTWH(x1 + 95, yOffset + 4, col1Width - 100, 20),
    );

    graphics.drawRectangle(
      pen: fieldPen,
      bounds: Rect.fromLTWH(x2, yOffset, col2Width, 20),
    );
    graphics.drawString(
      'Date :-',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(x2 + 5, yOffset + 4, 50, 20),
      brush: PdfBrushes.black,
    );

    if (voucherData['date'] != null) {
      DateTime? date;
      if (voucherData['date'] is DateTime) {
        date = voucherData['date'];
      } else if (voucherData['date'] is String) {
        date = DateTime.tryParse(voucherData['date']);
      }

      if (date != null) {
        final String dateStr =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        graphics.drawString(
          dateStr,
          PdfStandardFont(PdfFontFamily.helvetica, 9),
          bounds: Rect.fromLTWH(x2 + 45, yOffset + 4, 70, 20),
        );
      }
    }

    yOffset += 20;

    // Address and File Reg. No. row
    graphics.drawRectangle(
      pen: fieldPen,
      bounds: Rect.fromLTWH(x1, yOffset, col1Width, 20),
    );
    graphics.drawString(
      'Address :-',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(x1 + 5, yOffset + 4, 100, 20),
      brush: PdfBrushes.black,
    );
    graphics.drawString(
      voucherData['address'] ?? '',
      PdfStandardFont(PdfFontFamily.helvetica, 8),
      bounds: Rect.fromLTWH(x1 + 65, yOffset + 4, col1Width - 70, 20),
    );

    graphics.drawRectangle(
      pen: fieldPen,
      bounds: Rect.fromLTWH(x2, yOffset, col2Width, 20),
    );
    graphics.drawString(
      'File Reg. No. :-',
      PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(x2 + 5, yOffset + 4, 80, 20),
      brush: PdfBrushes.black,
    );

    graphics.drawString(
      voucherData['fileRegNo'] ?? '',
      PdfStandardFont(PdfFontFamily.helvetica, 8),
      bounds: Rect.fromLTWH(x2 + 80, yOffset + 4, col2Width - 85, 20),
    );

    yOffset += 20;

    // Amount and Expenses By row
    graphics.drawRectangle(
      pen: fieldPen,
      bounds: Rect.fromLTWH(15, yOffset, 310, 20),
    );
    graphics.drawString(
      'Amount of Expenses :-',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(20, yOffset + 4, 150, 20),
      brush: PdfBrushes.black,
    );
    graphics.drawString(
      "Rs. ${voucherData['amount']}",
      PdfStandardFont(PdfFontFamily.helvetica, 9),
      bounds: Rect.fromLTWH(165, yOffset + 4, 150, 20),
    );

    graphics.drawRectangle(
      pen: fieldPen,
      bounds: Rect.fromLTWH(325, yOffset, 250, 20),
    );
    graphics.drawString(
      'Expenses By :-',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(330, yOffset + 4, 80, 20),
      brush: PdfBrushes.black,
    );

    graphics.drawString(
      voucherData['expensesBy'] ?? '',
      PdfStandardFont(PdfFontFamily.helvetica, 9),
      bounds: Rect.fromLTWH(410, yOffset + 4, 160, 20),
    );
  }

  static void _drawPaymentExpenses(
    PdfGraphics graphics,
    double yOffset,
    Set<int> selectedPayments,
  ) {
    final PdfPen fieldPen = PdfPen(PdfColor(0, 180, 216), width: 1);

    graphics.drawRectangle(
      pen: fieldPen,
      bounds: Rect.fromLTWH(15, yOffset, 560, 20),
    );
    graphics.drawString(
      'Being amount paid/payable towards the following expenditure :-',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(20, yOffset + 4, 400, 20),
      brush: PdfBrushes.black,
    );

    yOffset += 20;

    final List<String> paymentTypes = [
      'Vehicle Rent',
      'Hotel',
      'Food',
      'Local Cartage',
      'Labour',
      'Other',
    ];
    final double boxWidth = 560 / 6;

    for (int i = 0; i < paymentTypes.length; i++) {
      final bool isSelected = selectedPayments.contains(i + 1);
      graphics.drawRectangle(
        pen: fieldPen,
        bounds: Rect.fromLTWH(15 + (i * boxWidth), yOffset, boxWidth, 20),
      );

      graphics.drawString(
        paymentTypes[i],
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(
          20 + (i * boxWidth),
          yOffset + 3,
          boxWidth - 25,
          10,
        ),
        brush: PdfBrushes.black,
      );

      // Small checkbox in bottom right of each cell
      final double checkboxSize = 8;
      final double checkX = 15 + (i * boxWidth) + boxWidth - checkboxSize - 3;
      final double checkY = yOffset + 20 - checkboxSize - 3;

      if (isSelected) {
        graphics.drawRectangle(
          pen: PdfPen(PdfColor(0, 0, 0), width: 0.5),
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
          bounds: Rect.fromLTWH(checkX, checkY, checkboxSize, checkboxSize),
        );

        final PdfPen tickPen = PdfPen(PdfColor(255, 255, 255), width: 1);
        graphics.drawLine(
          tickPen,
          Offset(checkX + 1.5, checkY + 4),
          Offset(checkX + 3, checkY + 6.5),
        );
        graphics.drawLine(
          tickPen,
          Offset(checkX + 3, checkY + 6.5),
          Offset(checkX + 6.5, checkY + 1.5),
        );
      } else {
        graphics.drawRectangle(
          pen: PdfPen(PdfColor(0, 0, 0), width: 0.5),
          bounds: Rect.fromLTWH(checkX, checkY, checkboxSize, checkboxSize),
        );
      }
    }
  }

  static void _drawFooter(
    PdfGraphics graphics,
    double yOffset,
    Uint8List? payorSignature,
    Uint8List? receiverSignature,
  ) {
    final PdfPen fieldPen = PdfPen(PdfColor(0, 180, 216), width: 1);

    // Footer row with signatures - total width 560
    graphics.drawRectangle(
      pen: fieldPen,
      bounds: Rect.fromLTWH(15, yOffset, 180, 30),
    );
    graphics.drawString(
      'Approved By:',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(20, yOffset + 10, 170, 30),
      brush: PdfBrushes.black,
    );

    graphics.drawRectangle(
      pen: fieldPen,
      bounds: Rect.fromLTWH(195, yOffset, 190, 30),
    );

    // Draw receiver signature if exists (draw first so text appears on top)
    if (receiverSignature != null) {
      try {
        final PdfBitmap signatureImage = PdfBitmap(receiverSignature);
        // Draw smaller signature below the text area
        graphics.drawImage(
          signatureImage,
          Rect.fromLTWH(260, yOffset + 15, 80, 12),
        );
      } catch (e) {
        // If signature rendering fails, silently continue
      }
    }

    graphics.drawString(
      'Receiver Sign:',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(200, yOffset + 10, 180, 30),
      brush: PdfBrushes.black,
    );

    graphics.drawRectangle(
      pen: fieldPen,
      bounds: Rect.fromLTWH(385, yOffset, 190, 30),
    );

    // Draw payor signature if exists (draw first so text appears on top)
    if (payorSignature != null) {
      try {
        final PdfBitmap signatureImage = PdfBitmap(payorSignature);
        // Draw smaller signature below the text area
        graphics.drawImage(
          signatureImage,
          Rect.fromLTWH(450, yOffset + 15, 80, 12),
        );
      } catch (e) {
        // If signature rendering fails, silently continue
      }
    }

    graphics.drawString(
      'Company Payor:',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(390, yOffset + 10, 180, 30),
      brush: PdfBrushes.black,
    );
  }
}
