import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:qr_mobile_vision/qr_camera.dart';

class WeatherPage extends StatefulWidget {
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  var uid, currentUser;
  var qr;
  late var timer;
  late final Ref = FirebaseDatabase.instance.ref('users/$uid/');
  String _motor = 'ON', _username = 'User';
  int _temperature = 0, _humidity = 0, _moisture = 0;
  double _pressure = 0, _altitude = 0;
  int index = 0;
  String condition = "Sunny";
  List<String> _imageList = [
    'assets/sun.png',
    'assets/heavy-rain.png',
    'assets/cloud.png',
  ];
  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      uid = currentUser.uid;
      DatabaseReference _qr = Ref.child('Device/');
      _qr.onValue.listen((DatabaseEvent event) {
        setState(() {
          qr = event.snapshot.value.toString();
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Something went wrong!!'),
        margin: EdgeInsets.all(5),
        elevation: 10,
        behavior: SnackBarBehavior.floating,
      ));
    }
    timer = Timer.periodic(Duration(seconds: 3), (timer) {
      sensordata();
    });
    Timer.periodic(Duration(seconds: 10), (timer) {
      imagechange();
    });
  }

  void imagechange() {
    DateTime currentTime = DateTime.now();
    if (_humidity > 85 && _pressure < 1000 && _temperature < 30) {
      setState(() {
        index = 1;
        condition = 'Rainy';
      });
    } else if (currentTime.hour >= 18 || currentTime.hour <= 5) {
      setState(() {
        index = 2;
        condition = 'Fair';
      });
    } else if (currentTime.hour >= 5 || currentTime.hour <= 10) {
      setState(() {
        index = 0;
        condition = 'Cloudy';
      });
    } else if (_humidity > 85) {
      setState(() {
        index = 0;
        condition = 'Cloudy';
      });
    } else {
      setState(() {
        index = 0;
        condition = 'Sunny';
      });
    }
  }

  void qrcode() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => QrCamera(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30, left: 175),
                    child: FloatingActionButton(
                        onPressed: () {
                          QrCamera.toggleFlash();
                        },
                        child: Icon(Icons.light)),
                  ),
                  onError: (context, error) => Text(
                    error.toString(),
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  qrCodeCallback: (code) {
                    setState(() {
                      qr = code!;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Successfully Linked'),
                      margin: EdgeInsets.all(5),
                      elevation: 10,
                      behavior: SnackBarBehavior.floating,
                    ));
                    Ref.child('Device/').set('$qr');
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                )));
  }

  Future _signout() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
                child: CircularProgressIndicator(
              color: Colors.blue,
            )));
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void sensordata() {
    DatabaseReference _usernameRef = Ref.child('name/');
    _usernameRef.onValue.listen((DatabaseEvent event) {
      setState(() {
        _username = event.snapshot.value.toString();
      });
    });
    if (qr != null && qr != "0") {
      print("Workerd");
      timer.cancel();
      late final Ref1 = FirebaseDatabase.instance.ref('Devices/$qr/');
      DatabaseReference _temperatureRef = Ref1.child('data/Temperature');
      DatabaseReference _humidityRef = Ref1.child('data/Humidity');
      DatabaseReference _moistureRef = Ref1.child('data/Moisture');
      DatabaseReference _pressureRef = Ref1.child('data/Pressure');
      DatabaseReference _altitudeRef = Ref1.child('data/Altitude');
      DatabaseReference _motorRef = Ref1.child('data/Motor');
      _temperatureRef.onValue.listen((DatabaseEvent event) {
        setState(() {
          _temperature = int.parse(event.snapshot.value.toString());
        });
      });
      _humidityRef.onValue.listen((DatabaseEvent event) {
        setState(() {
          _humidity = int.parse(event.snapshot.value.toString());
        });
      });
      _moistureRef.onValue.listen((DatabaseEvent event) {
        setState(() {
          _moisture = int.parse(event.snapshot.value.toString());
        });
      });
      _pressureRef.onValue.listen((DatabaseEvent event) {
        setState(() {
          _pressure = double.parse(event.snapshot.value.toString());
        });
      });
      _altitudeRef.onValue.listen((DatabaseEvent event) {
        setState(() {
          _altitude = double.parse(event.snapshot.value.toString());
        });
      });
      _motorRef.onValue.listen((DatabaseEvent event) {
        setState(() {
          _motor = event.snapshot.value.toString();
        });
      });
    }
  }

  Future checkConnection() async {
    final Ref1 = FirebaseDatabase.instance.ref('Devices/$qr/');
    var connectivity = await (Connectivity().checkConnectivity());
    if (connectivity == ConnectivityResult.none) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text("No Internet Connection"),
              actions: [
                TextButton(
                    onPressed: Navigator.of(context).pop, child: Text("OK"))
              ],
            );
          });
    } else {
      if (qr != null && qr != "0") {
        if (_motor == "OFF") {
          DatabaseReference _motorRef = Ref1.child('data/Motor');
          _motorRef.set("ON");
          setState(() {
            _motor = "OFF";
          });
        } else {
          DatabaseReference _motorRef = Ref1.child('data/Motor');
          _motorRef.set("OFF");
          setState(() {
            _motor = "ON";
          });
        }
      } else {
        if (_motor == "ON") {
          setState(() {
            _motor = "OFF";
          });
        } else {
          setState(() {
            _motor = "ON";
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          leadingWidth: 0,
          title: Text(
            'Hi,$_username',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black, fontSize: 24),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            PopupMenuButton(
                icon: Icon(Icons.more_vert, color: Colors.black),
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      child: ListTile(
                          leading: Icon(Icons.logout), title: Text("Sign Out")),
                      onTap: () {
                        _signout();
                      },
                    ),
                    PopupMenuItem<String>(
                      child: ListTile(
                          leading: Icon(Icons.link),
                          title: Text("Link Device")),
                      onTap: () {
                        qrcode();
                      },
                    )
                  ];
                })
          ],
        ),
        body: Center(
          child: ListView(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 15),
                  child: Center(
                    child: Image.asset(
                      _imageList[index],
                      height: 138,
                      width: 133,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '$condition', // Replace with actual weather condition description
                  style: TextStyle(fontSize: 24),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 0),
                child: Center(
                  child: SizedBox(
                    height: 55,
                    child: Text(
                      '$_temperature°C', // Replace with actual temperature
                      style:
                          TextStyle(fontSize: 48, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                      height: 130,
                      width: 167,
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F2F4),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    left: 5,
                                  ),
                                  child: Image.asset(
                                    'assets/drops-humidity-svgrepo-com.png',
                                    height: 42,
                                    width: 35,
                                  ),
                                ),
                                Text(
                                  'Humidity',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Center(
                              child: Text(
                            '$_humidity%',
                            style: TextStyle(fontSize: 32),
                          )),
                        ],
                      )),
                  Container(
                    height: 130,
                    width: 167,
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F2F4),
                      borderRadius: BorderRadius.circular(
                          25), /*boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 2)]*/
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  left: 7,
                                ),
                                child: Image.asset(
                                  'assets/pressure-svgrepo-com.png',
                                  height: 42,
                                  width: 35,
                                ),
                              ),
                              Text(
                                'Pressure',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Center(
                              child: Text(
                            '$_pressure' + ' mb',
                            style: TextStyle(fontSize: 32),
                          )),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    height: 130,
                    width: 167,
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F2F4),
                      borderRadius: BorderRadius.circular(
                          25), /*boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 2)]*/
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  left: 7,
                                ),
                                child: Image.asset(
                                  'assets/moisture-svgrepo-com.png',
                                  height: 42,
                                  width: 35,
                                ),
                              ),
                              Text(
                                'Moisture',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Center(
                              child: Text(
                            '$_moisture%',
                            style: TextStyle(fontSize: 32),
                          )),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 130,
                    width: 167,
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F2F4),
                      borderRadius: BorderRadius.circular(
                          25), /*boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 2)]*/
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  left: 7,
                                ),
                                child: Image.asset(
                                  'assets/mountains-altitude-svgrepo-com.png',
                                  height: 42,
                                  width: 35,
                                ),
                              ),
                              Text(
                                'Altitude',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Center(
                              child: Text(
                            '$_altitude' + ' m',
                            style: TextStyle(fontSize: 32),
                          )),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              Center(
                child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: SizedBox(
                      height: 50,
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          checkConnection();
                        },
                        child: Text(
                          '$_motor',
                          style: TextStyle(color: Colors.black, fontSize: 24),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE8F2F4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20))),
                      ),
                    )),
              ),
              Center(
                child: Padding(
                    padding: const EdgeInsets.only(top: 30, bottom: 20),
                    child: SizedBox(
                      height: 50,
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/fifth');
                        },
                        child: Text(
                          'Device Setup',
                          style: TextStyle(color: Colors.black, fontSize: 24),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE8F2F4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20))),
                      ),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
