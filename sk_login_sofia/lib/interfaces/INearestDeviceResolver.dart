import 'package:sk_login_sofia/models/BLEDevice.dart';
import 'package:sk_login_sofia/models/BLESample.dart';
import 'package:meta/meta.dart';

abstract class INearestDeviceResolver {
  List<BLEDevice> get devices;
  BLEDevice get nearestDevice;
  bool? monitoraggioSoloPiano;

  void addSample(BLESample sample);
  void refreshNearestDevice(DateTime timestamp);
  void clearUnreachableDevices(DateTime from);

  @visibleForTesting
  Stream<BLEDevice> get onNearestDeviceChanged;
}
