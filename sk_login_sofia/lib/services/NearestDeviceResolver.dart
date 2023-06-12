import 'package:flutter/foundation.dart';
import 'package:sk_login_sofia/interfaces/INearestDeviceResolver.dart';
import 'package:sk_login_sofia/models/BLEDevice.dart';
import 'package:sk_login_sofia/models/BLEDeviceType.dart';
import 'package:sk_login_sofia/models/BLESample.dart';

class NearestDeviceResolver implements INearestDeviceResolver {
  static const double NEAREST_DEVICE_TIMEOUT = 3000;
  static const double UNREACHABLE_DEVICE_TIMEOUT = 5000;

  DateTime? nearestDeviceAssignTimestamp;
  bool isRaised = false;
  BLEDevice? tmpNearestDevice;
  bool? _monitoraggioSoloPiano = true;
  List<BLEDevice> devices = [];
  late BLEDevice nearestDevice;
  ValueNotifier<BLEDevice?> onNearestDeviceChangedNotifier =
      ValueNotifier<BLEDevice?>(null);
  void Function(BLEDevice?)? _onNearestDeviceChanged;

  NearestDeviceResolver() {
    _monitoraggioSoloPiano = true;
    devices = <BLEDevice>[];
  }

  void addSample(BLESample sample) {
    // Ricerca dispositivo
    var device = findDevice(sample);

    // Aggiunta nuovo campione
    device.samples.enqueue(sample);

    // Ricalcolo del dispositivo più vicino
    refreshNearestDevice(sample.timestamp);
  }

  void refreshNearestDevice(DateTime timestamp) {
    clearUnreachableDevices(
        timestamp.subtract(Duration(milliseconds: UNREACHABLE_DEVICE_TIMEOUT as int)));
    var currentNearestDevice = getNearestDeviceImpl(devices);
    var lastTs = currentNearestDevice != null
        ? currentNearestDevice.lastSampleTimestamp!
        : timestamp;

    if (currentNearestDevice != tmpNearestDevice) {
      nearestDeviceAssignTimestamp = lastTs;
      isRaised = false;
      tmpNearestDevice = currentNearestDevice;
    }

    if (isTimeToFireEvent(lastTs)) {
      nearestDevice = tmpNearestDevice!;
      fireEvent();
      isRaised = true;
    }
  }

 void clearUnreachableDevices(DateTime from) {
  var devicesToRemove = devices
      .where((d) => d.lastSampleTimestamp != null && d.lastSampleTimestamp! < from)
      .toList();

  for (var device in devicesToRemove) {
    devices.remove(device);
  }
}


BLEDevice findDevice(BLESample sample) {
  var device = devices.firstWhere((d) => d.id == sample.deviceId, orElse: () {
    var newDevice = BLEDevice(
      type: sample.deviceType,
      id: sample.deviceId,
      alias: sample.alias,
    );
    devices.add(newDevice);
    return newDevice;
  });
  return device;
}



  BLEDevice? getNearestDeviceImpl(List<BLEDevice> devices) {
    if (_monitoraggioSoloPiano!) {
      if (devices.where((d) => d.type == BLEDeviceType.Floor).isEmpty) {
        return null;
      }
    } else {
      if (devices.isEmpty) {
        return null;
      }
    }

    var nearestDevice = devices.first;
    var maxRxPowerValue = double.negativeInfinity;
    double? avgRxPowerValue = double.negativeInfinity;

    for (var device in devices) {
      if (_monitoraggioSoloPiano! && device.type == BLEDeviceType.Floor) {
        avgRxPowerValue = device.avgRxPower;
      }
      if (!_monitoraggioSoloPiano!) {
        avgRxPowerValue = device.avgRxPower;
      }

      if (avgRxPowerValue != null && avgRxPowerValue > maxRxPowerValue) {
        maxRxPowerValue = avgRxPowerValue;
        nearestDevice = device;
      }
    }

    return nearestDevice;
  }

  bool isTimeToFireEvent(DateTime currentStampleTimestamp) {
    if (isRaised) {
      return false;
    }

    if (devices.isEmpty) {
      return true;
    }

    if (devices.length == 1) {
      return true;
    }

    if (tmpNearestDevice?.type == BLEDeviceType.Car) {
      return true;
    }

    var delay =
        currentStampleTimestamp.difference(nearestDeviceAssignTimestamp!);
    return delay.inMilliseconds >= NEAREST_DEVICE_TIMEOUT;
  }

  void fireEvent() {
    onNearestDeviceChangedNotifier.value = nearestDevice;
  }

  @override
  bool get monitoraggioSoloPiano => _monitoraggioSoloPiano!;

  @override
  set monitoraggioSoloPiano(bool value) {
    _monitoraggioSoloPiano = value;
  }

  @override
  List<BLEDevice> getDevices() {
    return devices;
  }

  @override
  BLEDevice? getNearestDevice() {
    return nearestDevice;
  }

  @override
  ValueNotifier<BLEDevice?> getOnNearestDeviceChanged() {
    return onNearestDeviceChangedNotifier;
  }

  @override
  void onNearestDeviceChanged(void Function(BLEDevice?) value) {
    _onNearestDeviceChanged = value;
    onNearestDeviceChangedNotifier.addListener(() {
      _onNearestDeviceChanged?.call(nearestDevice);
    });
  }
}
