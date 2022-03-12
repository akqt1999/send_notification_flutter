import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:send_notification_flutter/screen%202.dart';

import '../screen3.dart';

class LocalLocationServices {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initialize(BuildContext context) {
    final InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher"),
    );
    _notificationsPlugin.initialize(initializationSettings, onSelectNotification: (String? route) async {
      if (route != null) {
        if (route == "screen2") {
          Get.to(Screen2());
        } else if (route == "screen3") {
          Get.to(Screen3());
        }
      }
    });
  }

  static void display(RemoteMessage message) async {
    try {
      final id = DateTime.now().microsecondsSinceEpoch ~/ 1000;

      final NotificationDetails notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
        "nguyen xuan tri",
        "nguyen xuan tri channel",
        importance: Importance.max,
        priority: Priority.high,

      ));

      await _notificationsPlugin.show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
        payload: message.data["route"]
      );
    } catch (e) {
      print(e);
    }
  }
}
