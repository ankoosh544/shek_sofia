// import 'dart:async';

// import 'package:flutter_blue/flutter_blue.dart';
// import 'package:sk_login_sofia/interfaces/IBLEService.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/scheduler.dart';

// class BLEService implements IBLEService {
//   FlutterBlue _flutterBlue = FlutterBlue.instance;

//   bool _isScanning = false;
//   BluetoothDevice? _connectedDevice;
//   List<int> _valueFromCharacteristic = [];
//   bool timeoutBle = false; // Declare and initialize timeoutBle variable

//   StreamController<List<int>> _characteristicUpdatedController =
//       StreamController<List<int>>.broadcast();

//   Stream<List<int>> get onCharacteristicUpdated =>
//       _characteristicUpdatedController.stream;

//   Future<void> startScanningAsync(int scanTimeout) async {
//     if (_isScanning) return;

//     _isScanning = true;

//     _flutterBlue.scan(timeout: Duration(seconds: 10)).listen((scanResult) {
//       // Process the scanned device here
//     });
//   }

//   Future<void> stopScanningAsync() async {
//     if (!_isScanning) return;

//     _flutterBlue.stopScan();
//     _isScanning = false;
//   }

//   Future<void> connectToDeviceAsync(String deviceId) async {
//     if (_connectedDevice != null && _connectedDevice.isConnected) return;

//     final devices = await _flutterBlue.connectedDevices;
//     final device =
//         devices.firstWhere((device) => device.id.toString() == deviceId);

//     await device.connect().then((connectedDevice) {
//       _connectedDevice = connectedDevice;

//       // Discover services and characteristics here
//     });
//   }

//   Future<void> disconnectToDeviceAsync() async {
//     if (_connectedDevice == null || !_connectedDevice.isConnected) return;

//     await _connectedDevice.disconnect();
//     _connectedDevice = null;
//   }

//   Future<void> startCharacteristicWatchAsync(
//       String serviceGuid, String characteristicGuid) async {
//     if (_connectedDevice == null || !_connectedDevice.isConnected) return;

//     final services = await _connectedDevice.discoverServices();
//     final service = services.firstWhere(
//         (service) => service.uuid.toString() == serviceGuid,
//         orElse: () => null);

//     if (service == null) return;

//     final characteristic = service.characteristics.firstWhere(
//         (characteristic) =>
//             characteristic.uuid.toString() == characteristicGuid,
//         orElse: () => null);

//     if (characteristic == null) return;

//     characteristic.setNotifyValue(true);
//     characteristic.value.listen((value) {
//       _characteristicUpdatedController.add(value);
//     });
//   }

//   Future<void> stopCharacteristicWatchAsync(
//       String serviceGuid, String characteristicGuid) async {
//     if (_connectedDevice == null || !_connectedDevice.isConnected) return;

//     final services = await _connectedDevice.discoverServices();
//     final service = services.firstWhere(
//         (service) => service.uuid.toString() == serviceGuid,
//         orElse: () => null);

//     if (service == null) return;

//     final characteristic = service.characteristics.firstWhere(
//         (characteristic) =>
//             characteristic.uuid.toString() == characteristicGuid,
//         orElse: () => null);

//     if (characteristic == null) return;

//     characteristic.setNotifyValue(false);
//   }

//   Future<void> sendCommandAsync(
//       String serviceGuid, String characteristicGuid, List<int> message) async {
//     if (_connectedDevice == null || !_connectedDevice.isConnected) return;

//     final services = await _connectedDevice.discoverServices();
//     final service = services.firstWhere(
//         (service) => service.uuid.toString() == serviceGuid,
//         orElse: () => null);

//     if (service == null) return;

//     final characteristic = service.characteristics.firstWhere(
//         (characteristic) =>
//             characteristic.uuid.toString() == characteristicGuid,
//         orElse: () => null);

//     if (characteristic == null) return;

//     characteristic.write(message);
//   }

//   Future<List<int>> getValueFromCharacteristicGuid(
//       String serviceGuid, String characteristicGuid) async {
//     if (_connectedDevice == null || !_connectedDevice.isConnected) return [];

//     final services = await _connectedDevice.discoverServices();
//     final service = services.firstWhere(
//         (service) => service.uuid.toString() == serviceGuid,
//         orElse: () => null);

//     if (service == null) return [];

//     final characteristic = service.characteristics.firstWhere(
//         (characteristic) =>
//             characteristic.uuid.toString() == characteristicGuid,
//         orElse: () => null);

//     if (characteristic == null) return [];

//     final value = await characteristic.read();
//     return value;
//   }

//   void timer1msTick() {
//     Timer.periodic(Duration(milliseconds: 5), (timer) async {
//       await Future.delayed(Duration(milliseconds: 1));

//       if (timeoutBle) {
//         await stopScanningAsync();
//         await startScanningAsync(-1);

//         // if (Preferences.getBool('DevOptions', false) == true) {
//         //   // Vibration.vibrate();
//         //   if (Platform.isAndroid) {
//         //     // Code for Android platform
//         //   }
//         // }
//       } else {
//         timeoutBle = true;
//       }
//     });
//   }

//   String get connectedDeviceId {
//     return _connectedDevice != null ? _connectedDevice!.id.toString() : '';
//   }
// }
