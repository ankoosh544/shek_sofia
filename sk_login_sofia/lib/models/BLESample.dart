import 'dart:core';
import 'package:sk_login_sofia/models/BLEDeviceType.dart';

class BLESample {
  String deviceId;
  BLEDeviceType deviceType;
  String alias;
  DateTime timestamp;
  int? txPower;
  int? rxPower;

  BLESample({
    required this.deviceId,
    required this.deviceType,
    required this.alias,
    required this.timestamp,
    this.txPower,
    this.rxPower,
  });
}
