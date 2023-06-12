import 'package:sk_login_sofia/models/User.dart';

abstract class IAuthService {
  Future<bool> isLoggedAsync();
  Future<bool> loginAsync(String username, String password);
  Future<bool> logoutAsync();
  Future<User> detailsAsync();
}
