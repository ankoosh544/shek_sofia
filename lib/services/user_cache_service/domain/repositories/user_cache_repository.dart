import 'package:sofia_app/shared/domain/models/either.dart';
import 'package:sofia_app/shared/domain/models/models.dart';
import 'package:sofia_app/shared/exceptions/http_exception.dart';

abstract class UserRepository {
  Future<Either<AppException, User>> fetchUser();
  Future<bool> saveUser({required User user});
  Future<bool> deleteUser();
  Future<bool> hasUser();
}
