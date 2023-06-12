import 'package:events_emitter/events_emitter.dart';
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
  EventEmitter _eventEmitter = EventEmitter();
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
  int? carFloorNum;

  Direction? carDirection;
  int? eta;
  TypeMissionStatus? _missionStatus;

  Future<void> startScanningAsync();
  Future<void> stopScanningAsync();
  Future<void> changeFloorAsync(List<int> destinationFloor);
  Future<void> getCarFloor();
  Future<void> connectDevice(BLEDevice device);

  // Event Handlers
  void Function(BLEDevice)? onNearestDeviceChanged;
  void Function(String)? onFloorChanged;
  void Function()? onMissionStatusChanged;
  void Function()? onCharacteristicUpdated;
  void Function()? onDeviceDisconnected;
}
