import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:sk_login_sofia/interfaces/IBLEService.dart';
import 'package:sk_login_sofia/models/BLECharacteristicEventArgs.dart';
import 'package:sk_login_sofia/models/BLESample.dart';

class BLEService implements IBLEService {
  static const String FLOOR_SERVICE_GUID =
      '6c962546-6011-4e1b-9d8c-05027adb3a01';
  static const String CAR_SERVICE_GUID = '6c962546-6011-4e1b-9d8c-05027adb3a02';

  String _connectedDeviceId = '';
  List<int> _valueFromCharacteristic = [];
  bool timeoutBle = false; // Declare and initialize timeoutBle variable

  StreamController<BLESample> _sampleReceivedStreamController =
      StreamController<BLESample>.broadcast();
  StreamController<void> _scanningEndStreamController =
      StreamController<void>.broadcast();
  StreamController<void> _deviceConnectedStreamController =
      StreamController<void>.broadcast();
  StreamController<void> _deviceDisconnectedStreamController =
      StreamController<void>.broadcast();
  StreamController<BLECharacteristicEventArgs>
      _characteristicUpdatedStreamController =
      StreamController<BLECharacteristicEventArgs>.broadcast();

  Stream<BLESample> get onSampleReceived =>
      _sampleReceivedStreamController.stream;
  Stream<void> get onScanningEnd => _scanningEndStreamController.stream;
  Stream<void> get onDeviceConnected => _deviceConnectedStreamController.stream;
  Stream<void> get onDeviceDisconnected =>
      _deviceDisconnectedStreamController.stream;
  Stream<BLECharacteristicEventArgs> get onCharacteristicUpdated =>
      _characteristicUpdatedStreamController.stream;

  String get connectedDeviceId => _connectedDeviceId;
  List<int> get valueFromCharacteristic => _valueFromCharacteristic;

  FlutterBlue _flutterBlue = FlutterBlue.instance;
  StreamSubscription? _scanSubscription;
  BluetoothDevice? _connectedDevice;

  Future<void> startScanningAsync(int scanTimeout) async {
    _scanSubscription?.cancel();
    _scanSubscription = _flutterBlue
        .scan(timeout: Duration(seconds: scanTimeout))
        .listen((scanResult) {
      // Handle scan results and emit BLESample
      // Example: _sampleReceivedStreamController.add(BLESample.fromScanResult(scanResult));
    }, onDone: () {
      _scanningEndStreamController.add(null);
    });
  }

  Future<void> stopScanningAsync() async {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  Future<void> connectToDeviceAsync(String deviceId) async {
    try {
      final devices = await _flutterBlue.connectedDevices;
      final device = devices.firstWhere((device) => device.id.id == deviceId,
          orElse: () => null);

      if (device != null) {
        await device.connect();
        _connectedDevice = device;
        _connectedDeviceId = deviceId;
        _deviceConnectedStreamController.add(null);

        // Subscribe to characteristic changes, handle notifications/indications
        // Example: await startCharacteristicWatchAsync(FLOOR_SERVICE_GUID, CHARACTERISTIC_GUID);
      }
    } catch (e) {
      print('Failed to connect to device: $e');
    }
  }

  Future<void> disconnectToDeviceAsync() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _connectedDeviceId = '';
    _deviceDisconnectedStreamController.add(null);
  }

  Future<void> startCharacteristicWatchAsync(
      String serviceGuid, String characteristicGuid) async {
    // Start watching for characteristic changes and handle notifications/indications
    // Example: _connectedDevice?.discoverServices().then((services) {
    //   final service = services.firstWhere((s) => s.uuid.toString() == serviceGuid, orElse: () => null);
    //   final characteristic = service?.characteristics.firstWhere((c) => c.uuid.toString() == characteristicGuid, orElse: () => null);
    //   if (characteristic != null) {
    //     characteristic.setNotifyValue(true);
    //     characteristic.value.listen((value) {
    //       _characteristicUpdatedStreamController.add(BLECharacteristicEventArgs(value));
    //     });
    //   }
    // });
  }

  Future<void> stopCharacteristicWatchAsync(
      String serviceGuid, String characteristicGuid) async {
    // Stop watching for characteristic changes
    // Example: _connectedDevice?.discoverServices().then((services) {
    //   final service = services.firstWhere((s) => s.uuid.toString() == serviceGuid, orElse: () => null);
    //   final characteristic = service?.characteristics.firstWhere((c) => c.uuid.toString() == characteristicGuid, orElse: () => null);
    //   if (characteristic != null) {
    //     characteristic.setNotifyValue(false);
    //   }
    // });
  }

  Future<void> sendCommandAsync(
      String serviceGuid, String characteristicGuid, List<int> message) async {
    // Send a command to the specified characteristic
    // Example: _connectedDevice?.discoverServices().then((services) {
    //   final service = services.firstWhere((s) => s.uuid.toString() == serviceGuid, orElse: () => null);
    //   final characteristic = service?.characteristics.firstWhere((c) => c.uuid.toString() == characteristicGuid, orElse: () => null);
    //   if (characteristic != null) {
    //     characteristic.write(message, withoutResponse: true);
    //   }
    // });
  }

  Future<void> getValueFromCharacteristicGuid(
      String serviceGuid, String characteristicGuid) async {
    // Get the value from the specified characteristic
    // Example: _connectedDevice?.discoverServices().then((services) {
    //   final service = services.firstWhere((s) => s.uuid.toString() == serviceGuid, orElse: () => null);
    //   final characteristic = service?.characteristics.firstWhere((c) => c.uuid.toString() == characteristicGuid, orElse: () => null);
    //   if (characteristic != null) {
    //     final value = await characteristic.read();
    //     _valueFromCharacteristic = value;
    //   }
    // });
  }

  void timer1msTickk() {
    Timer.periodic(Duration(milliseconds: 5), (timer) async {
      await Future.delayed(Duration(milliseconds: 1));

      if (timeoutBle) {
        await stopScanningAsync();
        await startScanningAsync(-1);

        // if (Preferences.getBool('DevOptions', false) == true) {
        //   // Vibration.vibrate();
        //   if (Platform.isAndroid) {
        //     // Code for Android platform
        //   }
        // }
      } else {
        timeoutBle = true;
      }
    });
  }
}
