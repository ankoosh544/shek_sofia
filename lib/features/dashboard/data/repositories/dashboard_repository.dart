import 'package:sofia_app/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:sofia_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:sofia_app/shared/domain/models/either.dart';
import 'package:sofia_app/shared/domain/models/paginated_response.dart';
import 'package:sofia_app/shared/exceptions/http_exception.dart';

class DashboardRepositoryImpl extends DashboardRepository {
  final DashboardDatasource dashboardDatasource;
  DashboardRepositoryImpl(this.dashboardDatasource);

  @override
  Future<Either<AppException, PaginatedResponse>> fetchProducts(
      {required int skip}) {
    return dashboardDatasource.fetchPaginatedProducts(skip: skip);
  }

  @override
  Future<Either<AppException, PaginatedResponse>> searchProducts(
      {required int skip, required String query}) {
    return dashboardDatasource.searchPaginatedProducts(
        skip: skip, query: query);
  }
}
