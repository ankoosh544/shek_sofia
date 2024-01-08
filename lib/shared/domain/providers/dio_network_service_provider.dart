import 'package:dio/dio.dart';
import 'package:sofia_app/shared/data/remote/dio_network_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkServiceProvider = Provider<DioNetworkService>(
  (ref) {
    final Dio dio = Dio();
    return DioNetworkService(dio);
  },
);
