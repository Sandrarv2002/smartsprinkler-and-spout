import 'package:Spout/login.dart';
import 'package:Spout/weather.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Splashscreen extends StatelessWidget {
  Splashscreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return WeatherPage();
        } else {
          return Login();
        }
      },
    );
  }
}
