import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/category/presentation/pages/category_page.dart';
import 'features/crm/presentation/pages/add_party_page.dart';
import 'features/crm/presentation/pages/add_transporter_page.dart';
import 'features/crm/presentation/pages/add_vendor_page.dart';
import 'features/crm/presentation/pages/all_parties_page.dart';
import 'features/crm/presentation/pages/all_transporters_page.dart';
import 'features/crm/presentation/pages/all_vendors_page.dart';
import 'features/crm/presentation/pages/crm_page.dart';
import 'features/crm/presentation/pages/party_excel_export_page.dart';
import 'features/crm/presentation/pages/vendor_excel_export_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/product/presentation/pages/add_product_page.dart';
import 'features/product/presentation/pages/all_products_page.dart';
import 'features/product/presentation/pages/excel_export_page.dart';
import 'features/product/presentation/pages/product_page.dart';
import 'features/voucher/presentation/pages/add_voucher_page.dart';
import 'features/voucher/presentation/pages/all_vouchers_page.dart';
import 'features/voucher/presentation/pages/state_vouchers_page.dart';
import 'features/voucher/presentation/pages/voucher_excel_import_page.dart';
import 'features/voucher/presentation/pages/voucher_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dev Polymer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(builder: (_) => const SplashPage());
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => const HomePage());
          case AppRoutes.voucher:
            return MaterialPageRoute(builder: (_) => const VoucherPage());
          case AppRoutes.addVoucher:
            final stateCode = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => AddVoucherPage(stateCode: stateCode),
            );
          case AppRoutes.allVouchers:
            return MaterialPageRoute(builder: (_) => const AllVouchersPage());
          case AppRoutes.stateVouchers:
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => StateVouchersPage(
                stateName: args['stateName']!,
                stateCode: args['stateCode']!,
              ),
            );
          case AppRoutes.voucherExcelImport:
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => VoucherExcelImportPage(
                stateName: args['stateName']!,
                stateCode: args['stateCode']!,
                filePath: args['filePath'],
              ),
            );
          case AppRoutes.product:
            return MaterialPageRoute(builder: (_) => const ProductPage());
          case AppRoutes.addProduct:
            return MaterialPageRoute(builder: (_) => const AddProductPage());
          case AppRoutes.allProducts:
            return MaterialPageRoute(builder: (_) => const AllProductsPage());
          case AppRoutes.excelExport:
            final selectedFields = settings.arguments as Map<String, bool>;
            return MaterialPageRoute(
              builder: (_) => ExcelExportPage(selectedFields: selectedFields),
            );
          case AppRoutes.category:
            return MaterialPageRoute(builder: (_) => const CategoryPage());
          case AppRoutes.crm:
            return MaterialPageRoute(builder: (_) => const CrmPage());
          case AppRoutes.addParty:
            return MaterialPageRoute(
              builder: (_) => const AddPartyPage(),
              settings: settings,
            );
          case AppRoutes.allParties:
            return MaterialPageRoute(builder: (_) => const AllPartiesPage());
          case AppRoutes.excelExportParties:
            final selectedFields = settings.arguments as Map<String, bool>;
            return MaterialPageRoute(
              builder: (_) =>
                  PartyExcelExportPage(selectedFields: selectedFields),
            );
          case AppRoutes.addVendor:
            return MaterialPageRoute(
              builder: (_) => const AddVendorPage(),
              settings: settings,
            );
          case AppRoutes.allVendors:
            return MaterialPageRoute(builder: (_) => const AllVendorsPage());
          case AppRoutes.excelExportVendors:
            final selectedFields = settings.arguments as Map<String, bool>;
            return MaterialPageRoute(
              builder: (_) =>
                  VendorExcelExportPage(selectedFields: selectedFields),
            );
          case AppRoutes.addTransporter:
            return MaterialPageRoute(
              builder: (_) => const AddTransporterPage(),
              settings: settings,
            );
          case AppRoutes.allTransporters:
            return MaterialPageRoute(
              builder: (_) => const AllTransportersPage(),
            );
          default:
            return MaterialPageRoute(builder: (_) => const HomePage());
        }
      },
    );
  }
}
