import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ConnectionPage extends StatefulWidget {
  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  bool isConnected = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    checkConnection();
    _timer =
        Timer.periodic(Duration(seconds: 5), (Timer t) => checkConnection());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void checkConnection() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.4.1/'));
      if (response.statusCode == 200) {
        setState(() {
          isConnected = true;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SetupPage()),
        );
      } else {
        setState(() {
          isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        isConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Device Setup',
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: isConnected
            ? CircularProgressIndicator() // Show loading indicator while checking connection
            : Text('Device is not connected!'),
      ),
    );
  }
}

class SetupPage extends StatefulWidget {
  @override
  _SetupPage createState() => _SetupPage();
}

// ignore: must_be_immutable
class _SetupPage extends State<SetupPage> {
  TextEditingController ssidController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _password = true;

  Future<void> sethttp() async {
    final response = await http.post(Uri.parse('http://192.168.4.1/'), body: {
      'ssid': ssidController.text.trim(),
      'password': passwordController.text.trim(),
    });
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Successfull..'),
        margin: EdgeInsets.all(5),
        elevation: 10,
        behavior: SnackBarBehavior.floating,
      ));
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
                  child: CircularProgressIndicator(
                color: Colors.blue,
              )));
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      ssidController.text = _prefs.getString('textFieldValue1') ?? '';
      passwordController.text = _prefs.getString('textFieldValue2') ?? '';
    });
  }

  void _saveTextFieldValue(String value, String key) {
    _prefs.setString(key, value);
  }

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigating back to the main page when back button is pressed
        Navigator.popUntil(context, (route) => route.isFirst);
        return true;
      },
      child: Scaffold(
        key: _formKey,
        appBar: AppBar(
          title: Text(
            'Device Setup',
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          backgroundColor: Colors.black,
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter SSID';
                      }
                      return null;
                    },
                    controller: ssidController,
                    onChanged: (value) =>
                        _saveTextFieldValue(value, 'textFieldValue1'),
                    decoration: InputDecoration(
                        labelText: 'WiFi SSID',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.black))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: passwordController,
                    onChanged: (value) =>
                        _saveTextFieldValue(value, 'textFieldValue2'),
                    decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: togglepassword(),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.black))),
                    obscureText: _password,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          sethttp();
                        }
                      },
                      child: Text(
                        'Submit',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget togglepassword() {
    return IconButton(
      onPressed: () {
        setState(() {
          _password = !_password;
        });
      },
      icon: _password ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
      color: Colors.grey,
    );
  }
}
