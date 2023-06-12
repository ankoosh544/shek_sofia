import 'dart:async';
import 'package:events_emitter/events_emitter.dart';
import 'package:get_it/get_it.dart';
import 'package:sk_login_sofia/enums/direction.dart';
import 'package:sk_login_sofia/enums/operation_mode.dart';
import 'package:sk_login_sofia/interfaces/IAudioService.dart';
import 'package:sk_login_sofia/interfaces/IAuthService.dart';
import 'package:sk_login_sofia/interfaces/IBLEService.dart';
import 'package:sk_login_sofia/interfaces/ICoreController.dart';
import 'package:sk_login_sofia/interfaces/IDataLoggerService.dart';
import 'package:sk_login_sofia/interfaces/INearestDeviceResolver.dart';
import 'package:sk_login_sofia/interfaces/INotificationManager.dart';
import 'package:sk_login_sofia/models/BLECharacteristicEventArgs.dart';
import 'package:sk_login_sofia/models/BLEDevice.dart';
import 'package:sk_login_sofia/models/BLEDeviceType.dart';
import 'package:sk_login_sofia/models/BLESample.dart';
import 'package:sk_login_sofia/models/User.dart';
import 'package:vibration/vibration.dart';

enum TypeMissionStatus {
  MISSION_NO_INIT,
  MISSION_ABORTED,
  MISSION_QUEUED,
  MISSION_ARRIVING_DEPARTURE,
  MISSION_ARRIVING_DESTINATION,
  MISSION_FINISHED
}

typedef NearestDeviceChangedHandler = void Function(BLEDevice);
typedef FloorChangedHandler = void Function(String);
typedef MissionStatusChangedHandler = void Function();
typedef CharacteristicUpdatedHandler = void Function();
typedef DeviceDisconnectedHandler = void Function();

class CoreController implements ICoreController {
  EventEmitter _eventEmitter = EventEmitter();
  // Constants
  static const int SCAN_TIMEOUT = -1; // infinito
  static const int REFRESH_TIMEOUT = 500; // 500 ms
  static const double MIN_CAR_RX_POWER = -700;

  static const String FLOOR_REQUEST_CHARACTERISTIC_GUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String FLOOR_CHANGE_CHARACTERISTIC_GUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a9";
  static const String MISSION_STATUS_CHARACTERISTIC_GUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26aa";
  static const String OUT_OF_SERVICE_CHARACTERISTIC_GUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26ab";
  static const String MOVEMENT_DIRECTION_CAR =
      "beb5483e-36e1-4688-b7f5-ea07361b26ac";

  List<String> Characteristics = [];
  int IntervalloAvvisoVicinoAscensore = 60;
  int tickAttuali = 0;
  int SecondiPassati = 0;
  bool PrimaConnessioneDevice = true;
  bool ConnessioneInCorso = false;

  late IAuthService authService;
  late IBLEService bleService;
  late INotificationManager notificationManager;
  late INearestDeviceResolver resolver;
  late IAudioService audioService;
  late IDataLoggerService dataloggerService;

  bool isStarted = false;

  CoreController() {
    _eventEmitter = EventEmitter();
    authService = GetIt.instance.get<IAuthService>();
    bleService = GetIt.instance.get<IBLEService>();
    notificationManager = GetIt.instance.get<INotificationManager>();
    resolver = GetIt.instance.get<INearestDeviceResolver>();
    audioService = GetIt.instance.get<IAudioService>();
    dataloggerService = GetIt.instance.get<IDataLoggerService>();

    notificationManager.notificationReceived.listen((notification) {
      // NotificationManager_NotificationReceived(notification);
    });
    bleService.onSampleReceived.listen((sample) {
      BleService_OnSampleReceived(this, sample);
    });
    bleService.onDeviceDisconnected.listen((device) {
      //  BleService_OnDeviceDisconnected(device);
    });
    resolver.onNearestDeviceChanged.listen((nearestDevice) {
      Resolver_NearestDeviceChanged(this, nearestDevice);
    });

    bleService.timer1msTickk();
    Characteristics.add(FLOOR_CHANGE_CHARACTERISTIC_GUID);
    Characteristics.add(MISSION_STATUS_CHARACTERISTIC_GUID);
    Characteristics.add(OUT_OF_SERVICE_CHARACTERISTIC_GUID);
    //Characteristics.add(MOVEMENT_DIRECTION_CAR);
  }

  // void NotificationManager_NotificationReceived(Object sender, e) async {
  //   if (await authService.isLoggedAsync()) {
  //     //await Shell.current.goToAsync('//CommandPage');
  //   } else {
  //     //await Shell.current.goToAsync('//LoginPage');
  //   }
  // }

  void BleService_OnSampleReceived(dynamic sender, BLESample sample) {
    dataloggerService.addSample(sample);
    resolver.addSample(sample);
  }

  // void BleService_OnDeviceDisconnected(Object sender, e) {
  //   try {
  //     if (onDeviceDisconnected != null) {
  //       onDeviceDisconnected;
  //       print('Device disconnected!');
  //     }
  //   } catch (ex) {
  //     // if (Preferences.get('DevOptions', false) == true) {
  //     //   await showDialog(
  //     //     context: context,
  //     //     builder: (context) => AlertDialog(
  //     //       title: Text('Alert'),
  //     //       content: Text('${ex.message}\n${ex.stackTrace}\n${ex.source}'),
  //     //       actions: [
  //     //         TextButton(
  //     //           child: Text('OK'),
  //     //           onPressed: () => Navigator.pop(context),
  //     //         ),
  //     //       ],
  //     //     ),
  //     //   );
  //     // } else {
  //     //   debugPrint('${ex.message}\n${ex.stackTrace}\n${ex.source}');
  //     // }
  //   }
  // }

  void Resolver_NearestDeviceChanged(Object sender, BLEDevice device) async {
    if (device == null) {
      return;
    }

    if (ConnessioneInCorso) {
      return;
    }

    ConnessioneInCorso = true;
    await connectDeviceAndRead(device);

    if (device != null) {
      emitNotifications(device);
    }

    if (onNearestDeviceChanged != null) {
      onNearestDeviceChanged!(device);
    }

    if (operationMode == OperationMode.changeFloorMission) {
      if (bleService.connectedDeviceId.isNotEmpty) {
        await bleService.disconnectToDeviceAsync();
        await stopCharacteristicWatchAsync();
        await bleService.connectToDeviceAsync(device.id);
        await startCharacteristicReadWatchAsync();
      }
    }

    ConnessioneInCorso = false;
  }

  // properties
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
  TypeMissionStatus missionStatus = TypeMissionStatus.MISSION_NO_INIT;

  @override
  int? eta;

// Events

  // Event Handlers
  NearestDeviceChangedHandler? onNearestDeviceChanged;
  FloorChangedHandler? onFloorChanged;
  MissionStatusChangedHandler? onMissionStatusChanged;
  CharacteristicUpdatedHandler? onCharacteristicUpdated;
  DeviceDisconnectedHandler? onDeviceDisconnected;

  // Event handlers
  void bleService_OnDeviceDisconnected() {
    try {
      onDeviceDisconnected?.call();
    } catch (ex, stackTrace) {
      // if (Preferences.getBool('DevOptions') == true) {
      //   showDialog(
      //     context: context,
      //     builder: (_) => AlertDialog(
      //       title: Text('Alert'),
      //       content: Text('$ex\n\n$stackTrace'),
      //       actions: <Widget>[
      //         TextButton(
      //           onPressed: () {
      //             Navigator.of(context).pop();
      //           },
      //           child: Text('OK'),
      //         ),
      //       ],
      //     ),
      //   );
      // } else {
      //   debugPrint('$ex\n\n$stackTrace');
      // }
    }
  }

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
    isStarted = true;
    notificationManager.initialize();
    operationMode = OperationMode.deviceScanning;

    Timer.periodic(Duration(milliseconds: REFRESH_TIMEOUT), (timer) {
      // il refresh in polling viene fatto solo se non ricevo più campioni dal nearest device
      if (nearestDevice != null && !nearestDevice!.isAlive)
        resolver.refreshNearestDevice(DateTime.now());

      if (!isStarted) {
        timer.cancel();
      }
    });

    await bleService.startScanningAsync(SCAN_TIMEOUT);
  }

  @override
  Future<void> stopScanningAsync() async {
    isStarted = false;
    operationMode = OperationMode.idle;
    await bleService.stopScanningAsync();
  }

  @override
  Future<void> changeFloorAsync(List<int> destinationFloor) async {
    try {
      // cambio modalità operativa
      operationMode = OperationMode.changeFloorMission;

      // connessione dispositivo più vicino
      await bleService.connectToDeviceAsync(nearestDevice!.id);

      // invio comando BLE
      await bleService.sendCommandAsync(IBLEService.FLOOR_SERVICE_GUID,
          FLOOR_REQUEST_CHARACTERISTIC_GUID, destinationFloor);

      // avvio monitoraggio "Cambio piano" e "Fine monitoraggio"
      // await startCharacteristicWatchAsync();
    } catch (e) {
      // if (Preferences.get("DevOptions", false) == true) {
      //   await App.current.mainPage
      //       .displayAlert("Alert", "Errore invio chiamata", "Ok");
      // } else {
      //   debugPrint("Errore invio chiamata");
      // }
    }
  }

  @override
  Future<void> getCarFloor() async {
    // Get the current floor of the car.
    // Implement your own logic here.
  }

  @override
  Future<void> connectDevice(BLEDevice device) async {
    try {
      print("Alias device: ");
      print(device.alias);
      if (bleService.connectedDeviceId != null) {
        if (device == null) {
          return;
        }
        if (bleService.connectedDeviceId.isEmpty) {
          await connectDeviceAndRead(device);
        }
      }
    } catch (ex) {
      // if (Preferences.get("DevOptions", false) == true) {
      //   await App.current
      //       .showAlert("Alert", "${ex.message}\n${ex.stackTrace}\n${ex.source}", "OK");
      // } else {
      //   print("${ex.message}\n${ex.stackTrace}\n${ex.source}");
      // }
    }
  }

  Future<void> connectDeviceAndRead(BLEDevice device) async {
    try {
      if (bleService.connectedDeviceId.toString() == "") {
        if (device != null) {
          await bleService.connectToDeviceAsync(device.id);

          await getPianoCabina();
          await startCharacteristicReadWatchAsync();
        }
        return;
      }
    } catch (ex) {
      // if (Preferences.get("DevOptions", false) == true) {
      //   await App.current.showAlert("Alert", "${ex.message}\n${ex.stackTrace}\n${ex.source}", "OK");
      // } else {
      //   print("${ex.message}\n${ex.stackTrace}\n${ex.source}");
      // }
    }

    try {
      if (bleService.connectedDeviceId.toString() != device.id.toString()) {
        await stopCharacteristicWatchAsync();
        await bleService.disconnectToDeviceAsync();

        await bleService.connectToDeviceAsync(device.id);
        // await get_piano_cabina();
        await startCharacteristicReadWatchAsync();
        return;
      }
    } catch (ex) {
      // if (Preferences.get("DevOptions", false) == true) {
      //   await App.current.showAlert("Alert", "${ex.message}\n${ex.stackTrace}\n${ex.source}", "OK");
      // } else {
      //   print("${ex.message}\n${ex.stackTrace}\n${ex.source}");
      // }
    }
  }

  Future<void> stopCharacteristicWatchAsync() async {
    try {
      // Unsubscribe from characteristic update events
      bleService.onCharacteristicUpdated.listen((event) {});

      await bleService.stopCharacteristicWatchAsync(
          IBLEService.FLOOR_SERVICE_GUID, FLOOR_CHANGE_CHARACTERISTIC_GUID);
      await bleService.stopCharacteristicWatchAsync(
          IBLEService.FLOOR_SERVICE_GUID, MISSION_STATUS_CHARACTERISTIC_GUID);

      // Stop monitoring out of service and absence of light from the floor
      await bleService.stopCharacteristicWatchAsync(
          IBLEService.FLOOR_SERVICE_GUID, OUT_OF_SERVICE_CHARACTERISTIC_GUID);

      // Added cabin movement
      await bleService.stopCharacteristicWatchAsync(
          IBLEService.FLOOR_SERVICE_GUID, MOVEMENT_DIRECTION_CAR);

      print("*************** Stop watch characteristics ***************");
    } catch (e) {
      // Handle the exception
      // if(Preferences.getBool("DevOptions") == true)
      //   await showDialog(
      //     // Display alert dialog
      //     builder: (context) => AlertDialog(
      //       title: Text("Alert"),
      //       content: Text("${e.toString()}\r\n${e.stackTrace.toString()}\r\n${e.source.toString()}"),
      //       actions: [
      //         TextButton(
      //           onPressed: () => Navigator.pop(context),
      //           child: Text("OK"),
      //         ),
      //       ],
      //     ),
      //   );
    }
  }

  bool isFloor(BLEDevice device) {
    return device != null && device.type == BLEDeviceType.Floor;
  }

  void emitNotifications(BLEDevice device) {
    if (isFloor(device)) {
      // if (!isInForeground) {
      //   final secondsPassed =
      //       (DateTime.now().difference(tickAttuali).inMicroseconds /
      //           Duration.microsecondsPerSecond);
      //   print("Seconds: $secondsPassed");
      //   if (secondsPassed > IntervalloAvvisoVicinoAscensore ||
      //       PrimaConnessioneDevice) {
      //     PrimaConnessioneDevice = false;
      //     Vibration.vibrate();
      //     notificationManager.sendNotification(
      //         "Soffia", "Message tells you are near to Elevator");
      //     audioService.beep();
      //     tickAttuali = DateTime.now();
      //   }
      // }
    }

    // if (abilitaNotifica) {
    //   Vibration.vibrate();
    //   if (!isInForeground) {
    //     //this.notificationManager.SendNotification("Device info", $"New device detected {device.Alias}");
    //     notificationManager.sendNotification("Soffia", Res.AppResources.YouAreNearTheElevator);
    //     audioService.beep();
    //     await ritardoNotifica();
    //   }
    //   abilitaNotifica = false;
    // }
  }

  Future<void> getPianoCabina() async {
    try {
      carFloor = "999";
      if (bleService.connectedDeviceId.toString() != "") {
        try {
          await bleService.getValueFromCharacteristicGuid(
              IBLEService.FLOOR_SERVICE_GUID, FLOOR_CHANGE_CHARACTERISTIC_GUID);
        } catch (ex) {
          return;
          // await App.current.showAlert("Alert", "${ex.message}\n${ex.stackTrace}\n${ex.source}", "OK");
        }
        if (bleService.valueFromCharacteristic != null) {
          try {
            carFloor =
                ((bleService.valueFromCharacteristic[0]) & 0x3F).toString();
          } catch (ex) {
            // if (Preferences.get("DevOptions", false) == true) {
            //   carFloor = "*****";
            //   // Debug.Print("***** Caratteristica non trovata ******");
            // }
          }
        } else {
          carFloor = "999";
        }
      }
    } catch (ex) {
      // if (Preferences.get("DevOptions", false) == true) {
      //   await App.current.showAlert("Alert", "${ex.message}\n${ex.stackTrace}\n${ex.source}", "OK");
      // } else {
      //   print("${ex.message}\n${ex.stackTrace}\n${ex.source}");
      // }
    }
  }

  Future<void> startCharacteristicReadWatchAsync() async {
    int value;
    try {
      for (final characteristic in Characteristics) {
        value = 0;
        if (nearestDevice != null) {
          if (nearestDevice!.isAlive == true) {
            await bleService.getValueFromCharacteristicGuid(
                IBLEService.FLOOR_SERVICE_GUID, characteristic);
          }
        }
        BLECharacteristicEventArgs bl = BLECharacteristicEventArgs(
          value: bleService.valueFromCharacteristic,
          characteristicGuid: characteristic,
        );
        print("La caratteristica $characteristic ha il valore $value");
        if (bl.value != null) {
          bleServiceOnCharacteristicUpdated(this, bl);
        }
      }

      //  bleService.onCharacteristicUpdated += bleServiceOnCharacteristicUpdated;
      //bleService.onCharacteristicUpdated
      //    .listen(bleServiceOnCharacteristicUpdated);
      for (final characteristic in Characteristics) {
        await bleService.startCharacteristicWatchAsync(
            IBLEService.FLOOR_SERVICE_GUID, characteristic);
      }
    } catch (ex) {
      // if (Preferences.get("DevOptions", false) == true) {
      //   await App.current.showAlert(
      //       "Alert", "${ex.message}\n${ex.stackTrace}\n${ex.source}", "OK");
      // } else {
      //   print("${ex.message}\n${ex.stackTrace}\n${ex.source}");
      // }
    }
  }

  void bleServiceOnCharacteristicUpdated(
      Object sender, BLECharacteristicEventArgs e) {
    try {
      switch (e.characteristicGuid) {
        case FLOOR_CHANGE_CHARACTERISTIC_GUID:
          try {
            carFloor = ((e.value?[0]) ?? 0 & 0x3F).toString();
            if (((e.value?[0]) ?? 0 & 0x40) == 0x40) {
              presenceOfLight = true;
            } else {
              presenceOfLight = false;
            }

            if (((e.value?[1]) ?? 0 & 0x1) == 0x1) {
              if (((e.value?[1]) ?? 0 & 0x02) == 0x02) {
                carDirection = Direction.up;
              } else {
                carDirection = Direction.down;
              }
            } else {
              carDirection = Direction.stopped;
            }
          } catch (ex) {
            // if (Preferences.get("DevOptions", false) == true) {
            //   App.current.showAlert("Alert", "${ex.message}\n${ex.stackTrace}\n${ex.source}", "OK");
            // } else {
            //   print("${ex.message}\n${ex.stackTrace}\n${ex.source}");
            // }
          }
          break;

        case MISSION_STATUS_CHARACTERISTIC_GUID:
          try {
            if (e.value!.length > 2) {
              // missionStatus = e.value[0];
              // eta = e.value[1] * 256 + e.value[2];
            }
            if (onMissionStatusChanged != null) {
              onMissionStatusChanged;
            }
          } catch (ex) {
            // if (Preferences.get("DevOptions", false) == true) {
            //   App.current.showAlert("Alert",
            //       "${ex.message}\n${ex.stackTrace}\n${ex.source}", "OK");
            // } else {
            //   print("${ex.message}\n${ex.stackTrace}\n${ex.source}");
            // }
          }
          break;

        case OUT_OF_SERVICE_CHARACTERISTIC_GUID:
          // if (e.value[0] == 0) {
          //   outOfService = false;
          // } else {
          //   outOfService = true;
          // }
          break;

        case MOVEMENT_DIRECTION_CAR:
          // int valore = e!.value[0];
          // if ((e.value[0] & 0x1) == 0x1) {
          //   if ((e.value[0] & 0x02) == 0x02) {
          //     carDirection = Direction.up;
          //   } else {
          //     carDirection = Direction.down;
          //   }
          // } else {
          //   carDirection = Direction.stopped;
          // }
          break;
      }

      if (onCharacteristicUpdated != null) {
        onCharacteristicUpdated;
      }
    } catch (ex) {
      // App.current.showAlert(
      //     "Alert", "${ex.message}\n${ex.stackTrace}\n${ex.source}", "OK");
    }
  }

  // Events
  EventEmitter get eventEmitter => _eventEmitter;

  // Methods to subscribe to events
  void subscribeToNearestDeviceChanged(NearestDeviceChangedHandler handler) {
    onNearestDeviceChanged = handler;
    _eventEmitter.on('nearestDeviceChanged', (BLEDevice device) {
      if (onNearestDeviceChanged != null) {
        onNearestDeviceChanged!(device);
      }
    });
  }

  void subscribeToFloorChanged(FloorChangedHandler handler) {
    onFloorChanged = handler;
    _eventEmitter.on('floorChanged', (String floor) {
      if (onFloorChanged != null) {
        onFloorChanged!(floor);
      }
    });
  }

  void subscribeToMissionStatusChanged(MissionStatusChangedHandler handler) {
    onMissionStatusChanged = handler;
    _eventEmitter.on('missionStatusChanged', (dynamic) {
      if (onMissionStatusChanged != null) {
        onMissionStatusChanged!();
      }
    });
  }

  void subscribeToCharacteristicUpdated(CharacteristicUpdatedHandler handler) {
    onCharacteristicUpdated = handler;
    _eventEmitter.on('characteristicUpdated', (dynamic) {
      if (onCharacteristicUpdated != null) {
        onCharacteristicUpdated!();
      }
    });
  }

  void subscribeToDeviceDisconnected(DeviceDisconnectedHandler handler) {
    onDeviceDisconnected = handler;
    _eventEmitter.on('deviceDisconnected', (dynamic) {
      if (onDeviceDisconnected != null) {
        onDeviceDisconnected!();
      }
    });
  }

  // Trigger events
  void triggerNearestDeviceChanged(BLEDevice device) {
    _eventEmitter.emit('nearestDeviceChanged', [device]);
  }

  void triggerFloorChanged(String floor) {
    _eventEmitter.emit('floorChanged', [floor]);
  }

  void triggerMissionStatusChanged() {
    _eventEmitter.emit('missionStatusChanged', []);
  }

  void triggerCharacteristicUpdated() {
    _eventEmitter.emit('characteristicUpdated', []);
  }

  void triggerDeviceDisconnected() {
    _eventEmitter.emit('deviceDisconnected', []);
  }
}
