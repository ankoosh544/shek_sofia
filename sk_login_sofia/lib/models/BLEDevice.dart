import 'dart:core';
import 'package:sk_login_sofia/models/BLEDeviceType.dart';
import 'package:sk_login_sofia/models/BLESample.dart';
import 'package:sk_login_sofia/models/LimitedQueue.dart';

class BLEDevice {
  BLEDeviceType type;
  String id;
  String alias;
  LimitedQueue<BLESample> samples;

  static const int MAX_POWER_LEVEL = 6;
  static const int SAMPLE_QUEUE_CAPACITY = 5;
  static const int IS_ALIVE_TIMEOUT = 2000;

  BLEDevice({
    required this.type,
    required this.id,
    required this.alias,
  }) : samples = LimitedQueue<BLESample>(SAMPLE_QUEUE_CAPACITY);

  DateTime? get lastSampleTimestamp =>
      samples.isNotEmpty ? samples.last!.timestamp : null;

  bool get isAlive =>
      lastSampleTimestamp != null &&
      DateTime.now().difference(lastSampleTimestamp!) <
          Duration(milliseconds: IS_ALIVE_TIMEOUT);

  double? get avgRxPower {
    if (samples.any((s) => s.txPower != null && s.txPower == MAX_POWER_LEVEL)) {
      var sumRxPower = samples
          .where((s) => s.txPower != null && s.txPower == MAX_POWER_LEVEL)
          .map((s) => s.rxPower!)
          .reduce((a, b) => a + b);
      return sumRxPower / samples.length.toDouble();
    } else {
      return null;
    }
  }

  double? get lastRxPower {
    var lastSample = samples
        .where((s) => s.txPower != null && s.txPower == MAX_POWER_LEVEL)
        .lastOrNull;
    return lastSample?.rxPower?.toDouble();
  }

  @override
  String toString() {
    return '${type.toString().split('.').last} - $alias (LST: ${lastRxPower?.toStringAsFixed(0)}) (AVG: ${avgRxPower?.toStringAsFixed(0)})';
  }
}
