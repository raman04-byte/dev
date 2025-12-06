import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive cache
  await CacheService.init();

  runApp(const MyApp());
}
