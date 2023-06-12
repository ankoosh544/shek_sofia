import 'package:sk_login_sofia/models/BLESample.dart';

abstract class IDataLoggerService {
  bool get isStarted;

  void start();

  void stop();

  void addSample(BLESample sample);

  String toCsv();
}
