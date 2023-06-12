// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:sk_login_sofia/interfaces/INotificationManager.dart';

// class NotificationManager implements INotificationManager {
//   final String channelId = 'default';
//   final String channelName = 'Default';
//   final String channelDescription = 'The default channel for notifications.';

//   int messageId = 0;
//   int pendingIntentId = 0;

//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   NotificationManager() {
//     initialize();
//   }xz

//   @override
//   void initialize() {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('app_icon');
//     final InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);

//     flutterLocalNotificationsPlugin.initialize(initializationSettings);
//   }

//   @override
//   Future<void> sendNotification(String title, String message,
//       {DateTime? notifyTime}) async {
//     if (notifyTime != null) {
//       await _scheduleNotification(title, message, notifyTime);
//     } else {
//       await showNotification(title, message);
//     }
//   }

//   Future<void> _scheduleNotification(
//       String title, String message, DateTime notifyTime) async {
//     tz.initializeTimeZones();
//     final location = tz.local;
//     final scheduledDate = tz.TZDateTime.from(notifyTime, location);

//     final androidPlatformChannelSpecifics = AndroidNotificationDetails(
//       channelId,
//       channelName,
//       channelDescription,
//       importance: Importance.max,
//       priority: Priority.high,
//       ticker: 'ticker',
//       sound: RawResourceAndroidNotificationSound('beep'),
//     );
//     final platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);

//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       messageId++,
//       title,
//       message,
//       scheduledDate,
//       platformChannelSpecifics,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   Future<void> showNotification(String title, String message) async {
//     final androidPlatformChannelSpecifics = AndroidNotificationDetails(
//       channelId,
//       channelName,
//       channelDescription,
//       importance: Importance.max,
//       priority: Priority.high,
//       ticker: 'ticker',
//       sound: RawResourceAndroidNotificationSound('beep'),
//     );
//     final platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);

//     await flutterLocalNotificationsPlugin.show(
//       messageId++,
//       title,
//       message,
//       platformChannelSpecifics,
//     );
//   }

//   @override
//   void receiveNotification(String title, String message) {
//     // Handle received notification
//   }

//   @override
//   VoidCallback get notificationReceived => () {
//         // Handle notification received callback
//       };
// }