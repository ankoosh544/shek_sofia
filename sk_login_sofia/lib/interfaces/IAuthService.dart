import 'package:sk_login_sofia/models/User.dart';

abstract class IAuthService {
  Future<bool> isLoggedAsync();
  Future<bool> loginAsync(String username, String password);
  Future<bool> logoutAsync();
  Future<User> detailsAsync();
}

// class AuthService implements IAuthService {
//   @override
//   Future<bool> isLoggedAsync() async {
//     // Implementation of IsLoggedAsync in Flutter
//     // Add your code here
//     return false;
//   }

//   @override
//   Future<bool> loginAsync(String username, String password) async {
//     // Implementation of LoginAsync in Flutter
//     // Add your code here
//     return false;
//   }

//   @override
//   Future<bool> logoutAsync() async {
//     // Implementation of LogoutAsync in Flutter
//     // Add your code here
//     return false;
//   }

//   @override
//   Future<User> detailsAsync() async {
//     // Implementation of DetailsAsync in Flutter
//     // Add your code here
//     return User(); // Return an instance of User
//   }
//}
