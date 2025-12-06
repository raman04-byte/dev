import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Account _account = AppwriteService().account;

  @override
  Future<User> login(String email, String password) async {
    try {
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return await _account.get();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      return await _account.get();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      rethrow;
    }
  }
}
