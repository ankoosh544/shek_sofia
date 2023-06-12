abstract class INotificationManager {
  Stream<void> get notificationReceived;

  void initialize();
  void sendNotification(String title, String message, [DateTime? notifyTime]);
  void receiveNotification(String title, String message);
}
