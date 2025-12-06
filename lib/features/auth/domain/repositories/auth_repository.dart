import 'package:appwrite/models.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User?> getCurrentUser();
  Future<void> logout();
}
