
import 'package:sk_login_sofia/enums/direction.dart';
import 'package:sk_login_sofia/enums/operation_mode.dart';
import 'package:sk_login_sofia/interfaces/IDataLoggerService.dart';
import 'package:sk_login_sofia/models/BLEDevice.dart';
import 'package:sk_login_sofia/models/User.dart';

enum TypeMissionStatus {
  MISSION_NO_INIT,
  MISSION_ABORTED,
  MISSION_QUEUED,
  MISSION_ARRIVING_DEPARTURE,
  MISSION_ARRIVING_DESTINATION,
  MISSION_FINISHED
}

abstract class ICoreController {
  bool? isInForeground;
  List<BLEDevice>? devices;
  BLEDevice? nearestDevice;
  BLEDevice? car;
  User? loggerUser;
  IDataLoggerService? dataLogger;
  OperationMode? operationMode;
  bool? outOfService;
  bool? presenceOfLight;
  String? carFloor;

 int get carFloorNum {
  int val;
  try {
    val = int.parse(carFloor ?? '');
  } catch (e) {
    val = 0; // Provide a default value if parsing fails
  }
  return val;
}



  Direction? carDirection;
  int? eta;
  TypeMissionStatus? missionStatus;

  Future<void> startScanningAsync();
  Future<void> stopScanningAsync();
  Future<void> changeFloorAsync(List<int> destinationFloor);
  Future<void> getCarFloor();
  Future<void> connectDevice(BLEDevice device);

  void onNearestDeviceChanged(void Function(BLEDevice) handler);
  void onFloorChanged(void Function(String) handler);
  void onMissionStatusChanged(void Function() handler);
  void onCharacteristicUpdated(void Function() handler);
  void onDeviceDisconnected(void Function() handler);
}
