import 'package:get_it/get_it.dart';
import 'package:sk_login_sofia/interfaces/IAudioService.dart';
import 'package:sk_login_sofia/interfaces/IBLEService.dart';
import 'package:sk_login_sofia/interfaces/ICoreController.dart';
import 'package:sk_login_sofia/interfaces/IAuthService.dart';
import 'package:sk_login_sofia/interfaces/IDataLoggerService.dart';
import 'package:sk_login_sofia/interfaces/INearestDeviceResolver.dart';
import 'package:sk_login_sofia/interfaces/INotificationManager.dart';
import 'package:sk_login_sofia/services/AudioService.dart';
import 'package:sk_login_sofia/services/AuthService.dart';
import 'package:sk_login_sofia/services/BLEService.dart';
import 'package:sk_login_sofia/services/CoreController.dart';
import 'package:sk_login_sofia/services/DataLoggerService.dart';
import 'package:sk_login_sofia/services/NearestDeviceResolver.dart';

void setupDependencyInjection() {
  final authService = GetIt.instance.get<AuthService>();
  final bleService = GetIt.instance.get<IBLEService>();
  final resolver = GetIt.instance.get<INearestDeviceResolver>();
  final notificationManager = GetIt.instance.get<INotificationManager>();
  final audioService = GetIt.instance.get<IAudioService>();
  final dataloggerService = GetIt.instance.get<IDataLoggerService>();

  GetIt.instance.registerLazySingleton<IAuthService>(() => AuthService());
  GetIt.instance.registerLazySingleton<ICoreController>(() => CoreController());

  GetIt.instance.registerLazySingleton<INearestDeviceResolver>(
      () => NearestDeviceResolver());
  GetIt.instance.registerLazySingleton<IBLEService>(() => BLEService());
  GetIt.instance.registerLazySingleton<IAudioService>(() => AudioService());
  GetIt.instance
      .registerLazySingleton<IDataLoggerService>(() => DataLoggerService());
}
