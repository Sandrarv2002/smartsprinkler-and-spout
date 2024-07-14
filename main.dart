import 'package:Spout/firebase_options.dart';
import 'package:Spout/splash.dart';
import 'package:Spout/verifyemail.dart';
import 'setup.dart';
import 'Forgot.dart';
import 'changed.dart';
import 'loginpage.dart';
import 'Signup2.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

FirebaseMessaging messaging = FirebaseMessaging.instance;
Future<void> message() async {
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  message();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Sprinkler',
      home: Splashscreen(),
      routes: {
        '/first': (context) => Loginpage(),
        '/second': (context) => Signup(),
        '/third': (context) => Forgot(),
        '/fourth': (context) => Changed(),
        '/fifth': (context) => ConnectionPage(),
        '/sixth': (context) => Verifyemail()
      }));
}
