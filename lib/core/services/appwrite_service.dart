import 'package:appwrite/appwrite.dart';
import '../constants/app_constants.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  late Client client;
  late Account account;
  late Databases databases;
  late Storage storage;

  factory AppwriteService() {
    return _instance;
  }

  AppwriteService._internal() {
    client = Client()
        .setEndpoint(AppConstants.appwriteEndpoint)
        .setProject(AppConstants.appwriteProjectId)
        .setDevKey(AppConstants.appwriteDevId)
        .setSelfSigned(
          status: true,
        ); // For self signed certificates, only use for development

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }
}
