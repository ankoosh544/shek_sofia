import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sk_login_sofia/enums/direction.dart';
import 'package:sk_login_sofia/enums/operation_mode.dart';
import 'package:sk_login_sofia/interfaces/IAudioService.dart';
import 'package:sk_login_sofia/interfaces/IAuthService.dart';
import 'package:sk_login_sofia/interfaces/IBLEService.dart';
import 'package:sk_login_sofia/interfaces/IDataLoggerService.dart';
import 'package:sk_login_sofia/interfaces/INearestDeviceResolver.dart';
import 'package:sk_login_sofia/interfaces/INotificationManager.dart';
import 'package:sk_login_sofia/interfaces/IRidesService.dart';
import 'package:sk_login_sofia/models/BLECharacteristicEventArgs.dart';
import 'package:sk_login_sofia/models/BLEDevice.dart';
import 'package:sk_login_sofia/models/BLESample.dart';
import 'package:sk_login_sofia/models/User.dart';
import 'package:sk_login_sofia/interfaces/ICoreController.dart';
import 'package:sk_login_sofia/services/AudioService.dart';
import 'package:sk_login_sofia/services/AuthService.dart';
import 'package:sk_login_sofia/services/BLEService.dart';
import 'package:sk_login_sofia/services/DataLoggerService.dart';
import 'package:sk_login_sofia/services/NearestDeviceResolver.dart';
import 'package:sk_login_sofia/services/NotificationManager.dart';
import 'package:sk_login_sofia/services/RidesService.dart';
import 'package:flutter/material.dart';


enum TypeMissionStatus {
  MISSION_NO_INIT,
  MISSION_ABORTED,
  MISSION_QUEUED,
  MISSION_ARRIVING_DEPARTURE,
  MISSION_ARRIVING_DESTINATION,
  MISSION_FINISHED
}

class CoreController implements ICoreController {
  static const int SCAN_TIMEOUT = -1; // infinito
  static const int REFRESH_TIMEOUT = 500; // 500 ms
  static const double MIN_CAR_RX_POWER = -700;

  static const String FLOOR_REQUEST_CHARACTERISTIC_GUID =
      'beb5483e-36e1-4688-b7f5-ea07361b26a8'; // used to send new destination floor and priority
  static const String FLOOR_CHANGE_CHARACTERISTIC_GUID =
      'beb5483e-36e1-4688-b7f5-ea07361b26a9'; // sends the current floor of the elevator car to the phone
  static const String MISSION_STATUS_CHARACTERISTIC_GUID =
      'beb5483e-36e1-4688-b7f5-ea07361b26aa'; // sends the destination floor of the elevator car
  static const String OUT_OF_SERVICE_CHARACTERISTIC_GUID =
      'beb5483e-36e1-4688-b7f5-ea07361b26ab'; // out of service lift default 0
  static const String MOVEMENT_DIRECTION_CAR =
      'beb5483e-36e1-4688-b7f5-ea07361b26ac'; // movement and direction of the car
                                              // byte 0 = 1 car in motion
                                              // byte 1 = 0 Car up
                                              // byte 1 = 1 Car down

  List<String> characteristics = [];

  int intervalloAvvisoVicinoAscensore = 60; // in seconds
  int tickAttuali = 0; // stores the current tick value
  int secondiPassati = 0;
  bool primaConnessioneDevice = true;
  bool connessioneInCorso = false;

  IAuthService? authService;
  IBLEService? bleService;
  INearestDeviceResolver? resolver;
  INotificationManager? notificationManager;
  IAudioService? audioService;
  IDataLoggerService? dataloggerService;

  bool isStarted = false;

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
  Direction? carDirection = Direction.stopped; // 0 = up, 1 = down
  int _missionStatus = TypeMissionStatus.MISSION_NO_INIT;
  int? eta = -1;

  // properties
  //events
   StreamController<BLEDevice> _nearestDeviceChangedController =
      StreamController<BLEDevice>.broadcast();
  Stream<BLEDevice> get onNearestDeviceChanged =>
      _nearestDeviceChangedController.stream;

  // FloorChanged event
  StreamController<String> _floorChangedController =
      StreamController<String>.broadcast();
  Stream<String> get onFloorChanged => _floorChangedController.stream;

  // MissionStatusChanged event
  StreamController<void> _missionStatusChangedController =
      StreamController<void>.broadcast();
  Stream<void> get onMissionStatusChanged =>
      _missionStatusChangedController.stream;

  // CharacteristicUpdated event
  StreamController<void> _characteristicUpdatedController =
      StreamController<void>.broadcast();
  Stream<void> get onCharacteristicUpdated =>
      _characteristicUpdatedController.stream;

  // DeviceDisconnected event
  StreamController<void> _deviceDisconnectedController =
      StreamController<void>.broadcast();
  Stream<void> get onDeviceDisconnected =>
      _deviceDisconnectedController.stream;

  // Triggering the events
  void triggerNearestDeviceChanged(BLEDevice device) {
    _nearestDeviceChangedController.add(device);
  }

  void triggerFloorChanged(String floor) {
    _floorChangedController.add(floor);
  }

  void triggerMissionStatusChanged() {
    _missionStatusChangedController.add(null);
  }

  void triggerCharacteristicUpdated() {
    _characteristicUpdatedController.add(null);
  }

  void triggerDeviceDisconnected() {
    _deviceDisconnectedController.add(null);
  }

 

 CoreController() {
  GetIt.instance.registerLazySingleton<IAuthService>(() => AuthService());
  GetIt.instance.registerLazySingleton<ICoreController>(() => CoreController());
  GetIt.instance.registerLazySingleton<IRidesService>(() => RidesService());
  GetIt.instance.registerLazySingleton<INearestDeviceResolver>(() => NearestDeviceResolver());
  GetIt.instance.registerLazySingleton<IBLEService>(() => BLEService());
  GetIt.instance.registerLazySingleton<IAudioService>(() => AudioService());
  GetIt.instance.registerLazySingleton<IDataLoggerService>(() => DataLoggerService());

  notificationManager!.notificationReceived.listen((event) => NotificationManager_NotificationReceived);
  bleService!.onSampleReceived.listen((event) => BleService_OnSampleReceived);
  bleService!.onDeviceDisconnected.listen((event) => BleService_OnDeviceDisconnected);
  if (resolver != null) {
  resolver!.onNearestDeviceChanged = (event) {
    Resolver_NearestDeviceChanged;
  };
}


  bleService!.timer1msTickk();
  characteristics.add(FLOOR_CHANGE_CHARACTERISTIC_GUID);
  characteristics.add(MISSION_STATUS_CHARACTERISTIC_GUID);
  characteristics.add(OUT_OF_SERVICE_CHARACTERISTIC_GUID);
  //characteristics.add(MOVEMENT_DIRECTION_CAR);
}

void Resolver_NearestDeviceChanged(dynamic sender, BLEDevice device) async {
  if (device == null) {
    return;
  }

  if (connessioneInCorso == true) {
    return;
  }
  connessioneInCorso = true;

  await ConnectDeviceAndRead(device);

  // invio segnalazioni (vibrazione + audio) e notifica
  if (device != null) {
    EmitNotifications(device);
  }

  // invio evento
  if (onNearestDeviceChanged != null) {
    onNearestDeviceChanged(this, device);
  }

  // se "ChangeFloor" => connessione automatica per ricevere le notifiche di cambio piano e fine missione
  if (OperationMode == OperationMode.changeFloorMission) {
    // disconnessione precedente device connesso
    if (bleService!.connectedDeviceId.isNotEmpty) {
      await bleService!.disconnectToDeviceAsync();
      await StopCharacteristicWatchAsync();

      // connessione dispositivo più vicino
      await bleService!.connectToDeviceAsync(device.id);
      await StartCharacteristicReadWatchAsync();
      //MARIO    await ConnectDeviceAndRead(device);
    }
  }

  connessioneInCorso = false;
  //await StartCharacteristicWatchAsync();
}


Future<void> StopCharacteristicWatchAsync() async {
  try {
    // sottoscrizione eventi cambio valore caratteristica
    bleService?.onCharacteristicUpdated?.listen((event) => BleService_OnCharacteristicUpdated(this,event));

    await bleService?.stopCharacteristicWatchAsync(IBLEService.FLOOR_SERVICE_GUID, FLOOR_CHANGE_CHARACTERISTIC_GUID);
    await bleService?.stopCharacteristicWatchAsync(IBLEService.FLOOR_SERVICE_GUID, MISSION_STATUS_CHARACTERISTIC_GUID);

    // Mario - Stop Monitoraggio di out of service e assenza di luce letto dal piano
    await bleService?.stopCharacteristicWatchAsync(IBLEService.FLOOR_SERVICE_GUID, OUT_OF_SERVICE_CHARACTERISTIC_GUID);

    // Mario aggiunto movimento della cabina
    await bleService?.stopCharacteristicWatchAsync(IBLEService.FLOOR_SERVICE_GUID, MOVEMENT_DIRECTION_CAR);

    debugPrint('*************** Stop watch caratteristics ***************');
  } catch (ex) {
    // Handle any exceptions
  }
}

void BleService_OnCharacteristicUpdated(Object sender, BLECharacteristicEventArgs e) async{
  
  try {
    switch (e.characteristicGuid) {
      case FLOOR_CHANGE_CHARACTERISTIC_GUID:
        try {
          carFloor = ((e.value?[0] ?? 0) & 0x3F).toString();

          if (((e.value?[0] ?? 0) & 0x40) == 0x40)
            presenceOfLight = true;
          else
            presenceOfLight = false;

          if (((e.value?[1] ?? 0) & 0x1) == 0x1) {
            if (((e.value?[1] ?? 0) & 0x02) == 0x02) {
              carDirection = Direction.up;
            } else {
              carDirection = Direction.down;
            }
          } else {
            carDirection = Direction.stopped;
          }
        } catch (ex) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          if (prefs.getBool('DevOptions') == true)
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Alert'),
                content: Text('${ex.toString()}\n${ex.stackTrace}\n${ex.source}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          else
            debugPrint('${ex.toString()}\n${ex.stackTrace}\n${ex.source}');
        }
        break;

      case MISSION_STATUS_CHARACTERISTIC_GUID:
        try {
          if (e.value!.length > 2) {
            missionStatus = e.value[0];
            eta = e.value[1] * 256 + e.value[2];
          }
          if (onMissionStatusChanged != null)
            onMissionStatusChanged(this, null);
        } catch (ex) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          if (prefs.get('DevOptions') == true)
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Alert'),
                content: Text('${ex.toString()}\n${ex.stackTrace}\n${ex.source}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          else
            debugPrint('${ex.toString()}\n${ex.stackTrace}\n${ex.source}');
        }
        break;

      case OUT_OF_SERVICE_CHARACTERISTIC_GUID:
        if (e.value[0] == 0) {
          outOfService = false;
        } else {
          outOfService = true;
        }
        break;

      case MOVEMENT_DIRECTION_CAR:
        byte Valore = e.value[0];
        if ((e.value[0] & 0x1) == 0x1) {
          if ((e.value[0] & 0x02) == 0x02) {
            carDirection = Direction.up;
          } else {
            carDirection = Direction.down;
          }
        } else {
          carDirection = Direction.stopped;
        }
        break;
    }

    // invio evento
    if (onCharacteristicUpdated != null)
      onCharacteristicUpdated(this, null);
  } catch (ex) {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alert'),
        content: Text('${ex.toString()}\n${ex.stackTrace}\n${ex.source}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}


void EmitNotifications(BLEDevice device) {
  if (IsFloor(device)) {
    if (!isInForeground) {
      int secondiPassati = ((DateTime.now().microsecondsSinceEpoch - tickAttuali) ~/ 1000000);
      debugPrint('secondi:');
      debugPrint(secondiPassati.toString());
      if (secondiPassati > IntervalloAvvisoVicinoAscensore || PrimaConnessioneDevice) {
        PrimaConnessioneDevice = false;
        Vibration.vibrate();
        notificationManager.sendNotification('Soffia', Res.AppResources.YouAreNearTheElevator);
        audioService.beep();
        tickAttuali = DateTime.now().microsecondsSinceEpoch;
      }
    }
  }
}

Future<void> ConnectDeviceAndRead(BLEDevice device) async {
  try {
    if (bleService!.connectedDeviceId.toString() == '') {
      if (device != null) {
        await bleService.connectToDeviceAsync(device.Id);
        await Get_Piano_Cabina();
        await StartCharacteristicReadWatchAsync();
      }
      return;
    }
  } catch (ex) {
    if (Preferences.get('DevOptions', false) == true) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Alert'),
            content: Text('${ex.toString()}\n${ex.stackTrace}\n${ex.source}'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      debugPrint('${ex.toString()}\n${ex.stackTrace}\n${ex.source}');
    }
  }

  try {
    if (bleService!.connectedDeviceId.toString() != device.Id.toString()) {
      await StopCharacteristicWatchAsync();
      await bleService.DisconnectToDeviceAsync();
      await bleService.ConnectToDeviceAsync(device.Id);
      //await Get_Piano_Cabina();
      await StartCharacteristicReadWatchAsync();
      return;
    }
  } catch (ex) {
    if (Preferences.get('DevOptions', false) == true) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Alert'),
            content: Text('${ex.toString()}\n${ex.stackTrace}\n${ex.source}'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      debugPrint('${ex.toString()}\n${ex.stackTrace}\n${ex.source}');
    }
  }
}

void NotificationManager_NotificationReceived(BuildContext context) async {
  if (await authService!.isLoggedAsync()) {
    await Navigator.pushNamedAndRemoveUntil(context, '/CommandPage', (route) => false);
  } else {
    await Navigator.pushNamedAndRemoveUntil(context, '/LoginPage', (route) => false);
  }
}

void BleService_OnSampleReceived(dynamic sender, BLESample sample) {
  dataloggerService!.addSample(sample);
  resolver!.addSample(sample);
}

void BleService_OnDeviceDisconnected() {
  try {
    if (OnDeviceDisconnected != null) {
      OnDeviceDisconnected(this, null);
    }
  } catch (ex) {
    if (Preferences.get('DevOptions', false) == true) {
      showAlertDialog('Alert', '${ex.toString()}\n${ex.stackTrace}\n${ex.source}');
    } else {
      debugPrint('${ex.toString()}\n${ex.stackTrace}\n${ex.source}');
    }
  }
}

void BleService_OnDeviceDisconnected() {
  try {
    if (OnDeviceDisconnected != null) {
      OnDeviceDisconnected(this, null);
    }
  } catch (ex) {
    if (Preferences.get('DevOptions', false) == true) {
      showAlertDialog('Alert', '${ex.toString()}\n${ex.stackTrace}\n${ex.source}');
    } else {
      debugPrint('${ex.toString()}\n${ex.stackTrace}\n${ex.source}');
    }
  }
}


  // Other event handlers and methods

  // Clean up the event streams
  void dispose() {
    _nearestDeviceChangedController.close();
    _floorChangedController.close();
    _missionStatusChangedController.close();
    _characteristicUpdatedController.close();
    _deviceDisconnectedController.close();

    authService?.dispose();
  bleService?.dispose();
  notificationManager?.dispose();
  resolver?.dispose();
  audioService?.dispose();
  dataloggerService?.dispose();
  }




}
