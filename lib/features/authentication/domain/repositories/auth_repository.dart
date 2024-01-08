import 'package:sofia_app/shared/domain/models/either.dart';
import 'package:sofia_app/shared/domain/models/models.dart';
import 'package:sofia_app/shared/exceptions/http_exception.dart';

abstract class AuthenticationRepository {
  Future<Either<AppException, User>> loginUser({required User user});
}
