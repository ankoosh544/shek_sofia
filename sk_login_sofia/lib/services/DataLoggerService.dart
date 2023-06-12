import 'package:sk_login_sofia/interfaces/IDataLoggerService.dart';
import 'package:sk_login_sofia/models/BLESample.dart';

class DataLoggerService implements IDataLoggerService {
  bool _isStarted = false;
  List<BLESample> _samples = [];

  bool get isStarted => _isStarted;

  void addSample(BLESample sample) {
    if (_isStarted) {
      _samples.add(sample);
    }
  }

  void start() {
    _isStarted = true;
    _samples.clear();
  }

  void stop() {
    _isStarted = false;
  }

  String toCsv() {
    String content = 'Timestamp;Alias;DeviceType;TxPower;RxPower\n';

    for (var sample in _samples) {
      content +=
          '${sample.timestamp.toString()};${sample.alias};${sample.deviceType};${sample.txPower};${sample.rxPower}\n';
    }

    return content;
  }
}
