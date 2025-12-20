import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/theme/app_colors.dart';

class PdfViewerPage extends StatelessWidget {
  final File pdfFile;

  const PdfViewerPage({super.key, required this.pdfFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher PDF'),
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.white),
            onPressed: () async {
              try {
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(pdfFile.path)],
                    text: 'Voucher PDF',
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error sharing PDF: $e')),
                  );
                }
              }
            },
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body: SfPdfViewer.file(pdfFile),
    );
  }
}
