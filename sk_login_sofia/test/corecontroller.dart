import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sk_login_sofia/enums/direction.dart';
import 'package:sk_login_sofia/enums/operation_mode.dart';
import 'package:sk_login_sofia/interfaces/IAudioService.dart';
import 'package:sk_login_sofia/interfaces/IAuthService.dart';
import 'package:sk_login_sofia/interfaces/IBLEService.dart';
import 'package:sk_login_sofia/interfaces/ICoreController.dart';
import 'package:sk_login_sofia/interfaces/IDataLoggerService.dart';
import 'package:sk_login_sofia/interfaces/INearestDeviceResolver.dart';
import 'package:sk_login_sofia/interfaces/INotificationManager.dart';
import 'package:sk_login_sofia/models/BLEDevice.dart';
import 'package:sk_login_sofia/models/User.dart';
import 'package:sk_login_sofia/services/AudioService.dart';
import 'package:sk_login_sofia/services/DataLoggerService.dart';
import 'package:sk_login_sofia/services/NotificationManager.dart';
import 'package:sk_login_sofia/services/AuthService.dart';
import 'package:sk_login_sofia/services/BLEService.dart';
import 'package:sk_login_sofia/services/NearestDeviceResolver.dart';

class CoreController implements ICoreController {
  static const int SCAN_TIMEOUT = -1;
  static const int REFRESH_TIMEOUT = 500;
  static const double MIN_CAR_RX_POWER = -700;
  static const String FLOOR_REQUEST_CHARACTERISTIC_GUID =
      'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  static const String FLOOR_CHANGE_CHARACTERISTIC_GUID =
      'beb5483e-36e1-4688-b7f5-ea07361b26a9';
  static const String MISSION_STATUS_CHARACTERISTIC_GUID =
      'beb5483e-36e1-4688-b7f5-ea07361b26aa';
  static const String OUT_OF_SERVICE_CHARACTERISTIC_GUID =
      'beb5483e-36e1-4688-b7f5-ea07361b26ab';
  static const String MOVEMENT_DIRECTION_CAR =
      'beb5483e-36e1-4688-b7f5-ea07361b26ac';

  List<String> characteristics = [];

  int intervalloAvvisoVicinoAscensore = 60;
  late int tickAttuali;
  late int secondiPassati;
  bool primaConnessioneDevice = true;
  bool connessioneInCorso = false;

  IAuthService? authService;
  IBLEService? bleService;
  INearestDeviceResolver? resolver;
  INotificationManager? notificationManager;
  IAudioService? audioService;
  IDataLoggerService? dataloggerService;

  bool? isStarted = false;
  bool? isInForeground = false;
  List<BLEDevice>? devices = [];
  BLEDevice? nearestDevice;
  BLEDevice? car;
  User? loggerUser;
  IDataLoggerService? dataLogger;
  OperationMode? operationMode;
  bool? outOfService = false;
  bool? presenceOfLight = true;
  String? carFloor = '--';
  Direction? carDirection = Direction.stopped;
  int? missionStatus = TypeMissionStatus.MISSION_NO_INIT;
  int? eta = -1;

  StreamController<BLEDevice> _onNearestDeviceChangedController =
      StreamController<BLEDevice>.broadcast();
  StreamController<String> _onFloorChangedController =
      StreamController<String>.broadcast();
  StreamController<void> _onMissionStatusChangedController =
      StreamController<void>.broadcast();
  StreamController<void> _onCharacteristicUpdatedController =
      StreamController<void>.broadcast();
  StreamController<void> _onDeviceDisconnectedController =
      StreamController<void>.broadcast();

  CoreController() {
    authService = AuthService();
    bleService = BLEService();
    resolver = NearestDeviceResolver();
    notificationManager = NotificationManager();
    audioService = AudioService();
    dataloggerService = DataLoggerService();

    notificationManager!.notificationReceived.listen((notification) {
      // Handle notification received
    });

    bleService!.sampleReceived.listen((sample) {
      dataloggerService!.addSample(sample);
      resolver!.addSample(sample);
    });

    resolver!.nearestDeviceChanged.listen((device) async {
      if (connessioneInCorso) return;
      connessioneInCorso = true;
      await connectDeviceAndRead(device);

      if (device != null) {
        emitNotifications(device);
      }

      _onNearestDeviceChangedController.add(device);

      if (operationMode == OperationMode.changeFloorMission) {
        if (bleService!.connectedDeviceId.isNotEmpty) {
          await bleService!.disconnectFromDevice();
          await stopCharacteristicNotification(
              bleService!.connectedDeviceId,
              FLOOR_CHANGE_CHARACTERISTIC_GUID);
        }
      }

      connessioneInCorso = false;
    });
  }

  @override
  Stream<BLEDevice> get onNearestDeviceChanged =>
      _onNearestDeviceChangedController.stream;

  @override
  Stream<String> get onFloorChanged => _onFloorChangedController.stream;

  @override
  Stream<void> get onMissionStatusChanged =>
      _onMissionStatusChangedController.stream;

  @override
  Stream<void> get onCharacteristicUpdated =>
      _onCharacteristicUpdatedController.stream;

  @override
  Stream<void> get onDeviceDisconnected =>
      _onDeviceDisconnectedController.stream;

  @override
  Future<void> start() async {
    if (isStarted!) return;

    await authService!.login();
    await bleService!.startScanning();
    await dataloggerService!.start();
    await notificationManager!.init();
    isStarted = true;
  }

  @override
  Future<void> stop() async {
    if (!isStarted!) return;

    await bleService!.stopScanning();
    await dataloggerService!.stop();
    await authService!.logout();
    isStarted = false;
  }

  Future<void> connectDeviceAndRead(BLEDevice? device) async {
    if (device != null && device.id.isNotEmpty) {
      await bleService!.connectToDevice(device.id);
      await startCharacteristicNotification(
          device.id, FLOOR_CHANGE_CHARACTERISTIC_GUID);
      await readFloorAndMissionStatus(device.id);
    }
  }

  Future<void> readFloorAndMissionStatus(String deviceId) async {
    await readCharacteristic(
        deviceId, FLOOR_REQUEST_CHARACTERISTIC_GUID);
    await readCharacteristic(
        deviceId, MISSION_STATUS_CHARACTERISTIC_GUID);
  }

  Future<void> readCharacteristic(String deviceId, String characteristicId) async {
    try {
      final value = await bleService!.readCharacteristic(deviceId, characteristicId);
      if (characteristicId == FLOOR_REQUEST_CHARACTERISTIC_GUID) {
        if (value != null) {
          carFloor = value;
          _onFloorChangedController.add(value);
        }
      } else if (characteristicId == MISSION_STATUS_CHARACTERISTIC_GUID) {
        if (value != null) {
          missionStatus = int.parse(value);
          _onMissionStatusChangedController.add(null);
        }
      }
    } on PlatformException catch (e) {
      // Handle platform exceptions
    }
  }

  Future<void> startCharacteristicNotification(String deviceId, String characteristicId) async {
    try {
      await bleService!.startCharacteristicNotification(deviceId, characteristicId);
    } on PlatformException catch (e) {
      // Handle platform exceptions
    }
  }

  Future<void> stopCharacteristicNotification(String deviceId, String characteristicId) async {
    try {
      await bleService!.stopCharacteristicNotification(deviceId, characteristicId);
    } on PlatformException catch (e) {
      // Handle platform exceptions
    }
  }

  void emitNotifications(BLEDevice device) {
    if (car == null) return;

    final carId = car!.id;
    final deviceId = device.id;

    if (deviceId == carId) {
      final directionCharacteristic = FLOOR_CHANGE_CHARACTERISTIC_GUID;
      final missionCharacteristic = MISSION_STATUS_CHARACTERISTIC_GUID;
      final floorCharacteristic = FLOOR_REQUEST_CHARACTERISTIC_GUID;

      emitNotificationsForCharacteristic(deviceId, directionCharacteristic,
          MOVEMENT_DIRECTION_CAR);
      emitNotificationsForCharacteristic(deviceId, missionCharacteristic,
          missionCharacteristic);
      emitNotificationsForCharacteristic(deviceId, floorCharacteristic,
          floorCharacteristic);
    }
  }

  void emitNotificationsForCharacteristic(
      String deviceId, String characteristicId, String actionType) {
    if (characteristicId.isEmpty || characteristics.contains(characteristicId)) return;

    characteristics.add(characteristicId);

    bleService!.characteristicUpdated
        .where((event) =>
            event.deviceId == deviceId &&
            event.characteristicId == characteristicId)
        .listen((event) {
      _onCharacteristicUpdatedController.add(null);

      if (actionType == MOVEMENT_DIRECTION_CAR) {
        // Handle movement direction car
      } else if (actionType == MISSION_STATUS_CHARACTERISTIC_GUID) {
        // Handle mission status characteristic
      } else if (actionType == FLOOR_REQUEST_CHARACTERISTIC_GUID) {
        // Handle floor request characteristic
      }
    });
  }

  @override
  Future<void> disconnectFromDevice() async {
    await bleService!.disconnectFromDevice();
    _onDeviceDisconnectedController.add(null);
  }
}
