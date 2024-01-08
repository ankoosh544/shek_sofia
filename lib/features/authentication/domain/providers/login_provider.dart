import 'package:sofia_app/features/authentication/data/datasource/auth_remote_data_source.dart';
import 'package:sofia_app/features/authentication/data/repositories/authentication_repository_impl.dart';
import 'package:sofia_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:sofia_app/shared/data/remote/remote.dart';
import 'package:sofia_app/shared/domain/providers/dio_network_service_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authDataSourceProvider =
    Provider.family<LoginUserDataSource, NetworkService>(
  (_, networkService) => LoginUserRemoteDataSource(networkService),
);

final authRepositoryProvider = Provider<AuthenticationRepository>(
  (ref) {
    final NetworkService networkService = ref.watch(networkServiceProvider);
    final LoginUserDataSource dataSource =
        ref.watch(authDataSourceProvider(networkService));
    return AuthenticationRepositoryImpl(dataSource);
  },
);