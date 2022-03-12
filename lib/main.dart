import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:send_notification_flutter/screen%202.dart';
import 'package:send_notification_flutter/screen3.dart';
import 'package:send_notification_flutter/services/local_location_services.dart';
import 'package:http/http.dart' as http;
import 'package:send_notification_flutter/services/token_controller.dart';

import 'helps/containts.dart';

Future<void> main() async {
  //WidgetsFlutterBinding.ensureInitialized(); "Đc thêm vào khi sử dụng await async"
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AndroidNotificationChannel channel;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  TextEditingController titleEditingController = TextEditingController();
  TextEditingController bodyEditingController = TextEditingController();
  TextEditingController userNameEditingController = TextEditingController();
  TextEditingController screenEditingController = TextEditingController();
  String mtoken = "";

  TokenController _tokenController = Get.put(TokenController());

  @override
  void initState() {
    super.initState();

    LocalLocationServices.initialize(context);
    FirebaseMessaging.instance.subscribeToTopic("hello");
    _requestPermission();
    _loadFCM();
    //_listenFCM();
    listendFCM();
    _getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: userNameEditingController,
              decoration: InputDecoration(hintText: "user name"),
            ),
            TextField(
              controller: titleEditingController,
              decoration: InputDecoration(hintText: "title"),
            ),
            TextField(
              controller: bodyEditingController,
              decoration: InputDecoration(hintText: "body"),
            ),
            TextField(
              controller: screenEditingController,
              decoration: InputDecoration(hintText: "screen"),
            ),
            ElevatedButton(
                onPressed: () {
                  getTokenAndSaveTofirebase(userNameEditingController.text);
                },
                child: Text("get token and save to firebase")),
            ElevatedButton(
              onPressed: () {
                getTokenByUserName(userNameEditingController.text);
              },
              child: Text("test  get token by user name"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          String title = titleEditingController.text;
          String body = bodyEditingController.text;
          String screen = screenEditingController.text;
          Map<String, dynamic> data = {'route': screen};
          _sendNotificationToUserName(
            body: body,
            title: title,
            userName: userNameEditingController.text,
              data:data,
          );
        },
        tooltip: 'send',
        child: const Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  // void _listenFCM() {
  //   // App đóng hết sẽ hiển thị thôn báo . người dùng nhấn vào sẽ vào trang đó
  //   FirebaseMessaging.instance.getInitialMessage().then((message) {
  //     if (message != null) {
  //       final route = message.data['route'];
  //       print("testnoti getInitialMessage $route");
  //     }
  //   });
  //
  //   //forground work (Thông báo khi ở trong app)
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     RemoteNotification? notification = message.notification;
  //     AndroidNotification? android=message.notification?.android;
  //
  //     print("testnoti onMessage_${notification!.title}");
  //     print("testnoti onMessage_${notification.body}");
  //     LocalLocationServices.display(message);
  //   });
  //
  //   //Thông báo khi thoát  ra khỏi app
  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     print('A new onMessageOpenedApp event was published!');
  //     RemoteNotification? notification = message.notification;
  //     final routeFromMessage = message.data["route"];
  //     print("testnoti onMessageOpenedApp_${routeFromMessage}");
  //     print("testnoti onMessageOpenedApp_${notification!.title}");
  //     print("testnoti onMessageOpenedApp_${notification.body}");
  //
  //     if (routeFromMessage == "screen2") {
  //       Get.to(Screen2());
  //     } else if (routeFromMessage == "screen3") {
  //       Get.to(Screen3());
  //     }
  //   });
  // }

  void _sendNotificationToUserName({String? userName, String? title, String? body, Map<String, dynamic>? data}) async {
    await _tokenController.getTokenByUserName(userName ?? "").then((token) {
      sendPushMessage(token: token, title: title ?? "", body: body ?? "", data: data);
    });
  }

  void _requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("user grand permission");
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print("User grand provisional oermission");
    } else {
      print("user declined or has not accepted");
    }
  }

  void _getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) => print("token:_ $token"));
  }

  void _loadFCM() async {
    if (!kIsWeb) {
      channel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        importance: Importance.high,
        enableVibration: true,
      );

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void listendFCM() async {
    final InitializationSettings initializationSettings =
        InitializationSettings(android: AndroidInitializationSettings("@mipmap/ic_launcher"));
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: (String? route) async {
      if (route != null) {
        if (route == "FLUTTER_NOTIFICATION_CLICK") {
          Get.to(Screen2());
        }else if(route=="screen2"){
          Get.to(Screen2());
        }else if(route=="screen3"){
          Get.to(Screen3());
        }
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      // final route = message.data["click_action"];
      // print("clickaction__ $route");
      // if (route == "FLUTTER_NOTIFICATION_CLICK") {
      //   Get.to(Screen2());
      // }
      if (notification != null && android != null && !kIsWeb) {
        print("titile${notification.title}");
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                importance: Importance.max,
                priority: Priority.high,
                icon: 'launch_background',
              ),
            ),
            payload: message.data["route"]);
      }
    });
  }

  void sendPushMessage(
      {required String token, required String body, required String title, Map<String, dynamic>? data}) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAAKvqc9yw:APA91bGX_wBsStm-WQouS_2DDkK7YCyh5YDT1pUnuzWtt1S881W9JvcbZJrMwYl_dZClcccuVHGa0rANRBCFuQufiNwtNt77Y9ORDCa1PZ-YOcpoM-1ws4Mbg9wp_midfTsmyyVfSTRM',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{'body': body, 'title': title},
            'priority': 'high',
            // 'data': <String, dynamic>{'click_action': 'FLUTTER_NOTIFICATION_CLICK', 'id': '1', 'status': 'done'},
            'data': data,
            "to": token,
          },
        ),
      );
    } catch (e) {
      print("error send notification $e");
    }
  }

  void getTokenAndSaveTofirebase(String? namUser) async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        mtoken = token!;
        print("tolend:$token");
        saveTokenToFirebase(nameUser: namUser, token: token);
      });
    });
  }

  void saveTokenToFirebase({String? token, String? nameUser}) async {
    try {
      await FirebaseFirestore.instance.collection(Containts.USER_TOKEN).doc(nameUser).set({'token': token});
    } catch (e) {
      print("error save token to firebase $e");
    }
  }

  void getTokenByUserName(String userName) async {
    String token;
    await _tokenController.getTokenByUserName(userName).then((value) {
      print("tokend==$value");
    });
  }
}
