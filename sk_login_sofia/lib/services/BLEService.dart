import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:sk_login_sofia/interfaces/IBLEService.dart';
import 'package:sk_login_sofia/models/BLECharacteristicEventArgs.dart';
import 'package:sk_login_sofia/models/BLESample.dart';

class BLEService implements IBLEService {
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];
  List<int> _valueFromCharacteristic = [];
  bool timeoutBle = false;

  String get connectedDeviceId => _connectedDevice?.id.id ?? '';

  List<int> get valueFromCharacteristic => _valueFromCharacteristic;

  @override
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

  @override
  Stream<BLESample> get onSampleReceived {
    // Implement your stream for sample received here
    // For example:
    // return _sampleReceivedController.stream;
    throw UnimplementedError();
  }

  @override
  Stream<void> get onScanningEnd {
    // Implement your stream for scanning end here
    // For example:
    // return _scanningEndController.stream;
    throw UnimplementedError();
  }

  @override
  Stream<void> get onDeviceConnected {
    // Implement your stream for device connected here
    // For example:
    // return _deviceConnectedController.stream;
    throw UnimplementedError();
  }

  @override
  Stream<void> get onDeviceDisconnected {
    // Implement your stream for device disconnected here
    // For example:
    // return _deviceDisconnectedController.stream;
    throw UnimplementedError();
  }

  @override
  Stream<BLECharacteristicEventArgs> get onCharacteristicUpdated {
    // Implement your stream for characteristic updated here
    // For example:
    // return _characteristicUpdatedController.stream;
    throw UnimplementedError();
  }

  @override
  Future<void> startScanningAsync(int scanTimeout) async {
    try {
      await FlutterBlue.instance
          .startScan(timeout: Duration(seconds: scanTimeout));
    } catch (e) {
      print('Failed to start scanning: $e');
    }
  }

  @override
  Future<void> stopScanningAsync() async {
    try {
      await FlutterBlue.instance.stopScan();
    } catch (e) {
      print('Failed to stop scanning: $e');
    }
  }

  @override
  Future<void> connectToDeviceAsync(String deviceId) async {
    try {
      final devices = await FlutterBlue.instance.connectedDevices;
      final device = devices.firstWhere((d) => d.id.id == deviceId, orElse: () {
        throw Exception('No device found with ID $deviceId');
      });
      await connectToDevice(device);
    } catch (e) {
      print('Failed to connect to device: $e');
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: true);
      _connectedDevice = device;
      await discoverServices();
      // Emit device connected event
      // _deviceConnectedController.add(null);
    } catch (e) {
      print('Failed to connect to device: $e');
    }
  }

  @override
  Future<void> disconnectToDeviceAsync() async {
    try {
      await disconnectFromDevice();
    } catch (e) {
      print('Failed to disconnect from device: $e');
    }
  }

  Future<void> disconnectFromDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _services.clear();
      _valueFromCharacteristic.clear();
      // Emit device disconnected event
      // _deviceDisconnectedController.add(null);
    }
  }

  @override
  Future<void> startCharacteristicWatchAsync(
      String serviceGuid, String characteristicGuid) async {
    final service = _services.firstWhere(
        (s) => s.uuid.toString() == serviceGuid,
        orElse: () => throw Exception('Service not found'));
    if (service != null) {
      await subscribeToCharacteristic(service, characteristicGuid);
    }
  }

  Future<void> subscribeToCharacteristic(
      BluetoothService service, String characteristicGuid) async {
    final characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString() == characteristicGuid,
        orElse: () => throw Exception('Characteristic not found'));

    if (characteristic != null) {
      await characteristic.setNotifyValue(true);
      characteristic.value.listen((value) {
        // Handle characteristic updated event
        // final args = BLECharacteristicEventArgs(characteristic, value);
        // _characteristicUpdatedController.add(args);
      });
    }
  }

  @override
  Future<void> stopCharacteristicWatchAsync(
      String serviceGuid, String characteristicGuid) async {
    final service = _services.firstWhere(
        (s) => s.uuid.toString() == serviceGuid,
        orElse: () => throw Exception('Service not found'));
    if (service != null) {
      await unsubscribeFromCharacteristic(service, characteristicGuid);
    }
  }

  Future<void> unsubscribeFromCharacteristic(
      BluetoothService service, String characteristicGuid) async {
    final characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString() == characteristicGuid,
        orElse: () => throw Exception('Characteristic not found'));

    if (characteristic != null) {
      await characteristic.setNotifyValue(false);
    }
  }

  @override
  Future<void> sendCommandAsync(
      String serviceGuid, String characteristicGuid, List<int> message) async {
    final service = _services.firstWhere(
        (s) => s.uuid.toString() == serviceGuid,
        orElse: () => throw Exception('Service not found'));
    if (service != null) {
      await writeCharacteristic(service, characteristicGuid, message);
    }
  }

  Future<void> writeCharacteristic(BluetoothService service,
      String characteristicUuid, List<int> value) async {
    final characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString() == characteristicUuid,
        orElse: () => throw Exception('Characteristic not found'));

    if (characteristic != null) {
      await characteristic.write(value, withoutResponse: true);
    }
  }

  @override
  Future<void> getValueFromCharacteristicGuid(
      String serviceGuid, String characteristicGuid) async {
    final service = _services.firstWhere(
        (s) => s.uuid.toString() == serviceGuid,
        orElse: () => throw Exception('Service not found'));
    if (service != null) {
      await readCharacteristic(service, characteristicGuid);
    }
  }

  Future<void> readCharacteristic(
      BluetoothService service, String characteristicUuid) async {
    final characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString() == characteristicUuid,
        orElse: () => throw Exception('Characteristic not found'));

    if (characteristic != null) {
      final value = await characteristic.read();
      _valueFromCharacteristic = value;
    }
  }

  Stream<BluetoothDevice> getDeviceStream() {
    return FlutterBlue.instance.scanResults
        .map((results) => results.map((r) => r.device).toList())
        .expand((devices) => devices);
  }

  Future<void> discoverServices() async {
    if (_connectedDevice != null) {
      try {
        _services = await _connectedDevice!.discoverServices();
      } catch (e) {
        print('Failed to discover services: $e');
      }
    }
  }
}
