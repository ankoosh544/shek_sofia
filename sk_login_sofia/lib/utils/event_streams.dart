// event_streams.dart

import 'dart:async';

import 'package:sk_login_sofia/models/BLEDevice.dart';

class EventStreams {
  static final StreamController<BLEDevice> _nearestDeviceController =
      StreamController<BLEDevice>.broadcast();
  static final StreamController<String> _floorController =
      StreamController<String>.broadcast();
  static final StreamController<void> _missionStatusController =
      StreamController<void>.broadcast();
  static final StreamController<void> _characteristicUpdatedController =
      StreamController<void>.broadcast();
  static final StreamController<void> _deviceDisconnectedController =
      StreamController<void>.broadcast();

  static Stream<BLEDevice> get onNearestDeviceChanged =>
      _nearestDeviceController.stream;

  static Stream<String> get onFloorChanged => _floorController.stream;

  static Stream<void> get onMissionStatusChanged =>
      _missionStatusController.stream;

  static Stream<void> get onCharacteristicUpdated =>
      _characteristicUpdatedController.stream;

  static Stream<void> get onDeviceDisconnected =>
      _deviceDisconnectedController.stream;

  static void emitNearestDeviceChanged(BLEDevice device) {
    _nearestDeviceController.add(device);
  }

  static void emitFloorChanged(String floor) {
    _floorController.add(floor);
  }

  static void emitMissionStatusChanged() {
    _missionStatusController.add(null);
  }

  static void emitCharacteristicUpdated() {
    _characteristicUpdatedController.add(null);
  }

  static void emitDeviceDisconnected() {
    _deviceDisconnectedController.add(null);
  }

  static void dispose() {
    _nearestDeviceController.close();
    _floorController.close();
    _missionStatusController.close();
    _characteristicUpdatedController.close();
    _deviceDisconnectedController.close();
  }
}
