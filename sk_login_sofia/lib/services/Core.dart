import 'package:sk_login_sofia/enums/direction.dart';
import 'package:sk_login_sofia/enums/operation_mode.dart';
import 'package:sk_login_sofia/interfaces/ICoreController.dart';
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

class CoreController implements ICoreController {
  @override
  bool? isInForeground;

  @override
  List<BLEDevice>? devices;

  @override
  BLEDevice? nearestDevice;

  @override
  BLEDevice? car;

  @override
  User? loggerUser;

  @override
  IDataLoggerService? dataLogger;

  @override
  OperationMode? operationMode;

  @override
  bool? outOfService;

  @override
  bool? presenceOfLight;

  @override
  String? carFloor;

  @override
  Direction? carDirection;

  @override
  int? eta;

  final TypeMissionStatus _missionStatus = TypeMissionStatus.MISSION_NO_INIT;

  set carFloorNum(int? floorNum) {
    // Set the car floor number.
    // Implement your own logic here.
  }

  int get carFloorNum {
    int val;
    try {
      val = int.parse(carFloor ?? '');
    } catch (e) {
      val = 0; // Provide a default value if parsing fails
    }
    return val;
  }

  @override
  Future<void> startScanningAsync() async {
    // Start scanning for BLE devices.
    // Implement your own logic here.
  }

  @override
  Future<void> stopScanningAsync() async {
    // Stop scanning for BLE devices.
    // Implement your own logic here.
  }

  @override
  Future<void> changeFloorAsync(List<int> destinationFloor) async {
    // Change the floor of the current mission.
    // Implement your own logic here.
  }

  @override
  Future<void> getCarFloor() async {
    // Get the current floor of the car.
    // Implement your own logic here.
  }

  @override
  Future<void> connectDevice(BLEDevice device) async {
    // Connect to a BLE device.
    // Implement your own logic here.
  }

  @override
  void onNearestDeviceChanged(void Function(BLEDevice) handler) {
    // Register a handler to be called when the nearest device changes.
    // Implement your own logic here.
  }

  @override
  void onFloorChanged(void Function(String) handler) {
    // Register a handler to be called when the current floor changes.
    // Implement your own logic here.
  }

  @override
  void onMissionStatusChanged(void Function() handler) {
    // Register a handler to be called when the mission status changes.
    // Implement your own logic here.
  }

  @override
  void onCharacteristicUpdated(void Function() handler) {
    // Register a handler to be called when a characteristic is updated.
    // Implement your own logic here.
  }

  @override
  void onDeviceDisconnected(void Function() handler) {
    // Register a handler to be called when a device gets disconnected.
    // Implement your own logic here.
  }
}
