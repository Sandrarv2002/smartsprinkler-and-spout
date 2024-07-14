import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Forgot extends StatefulWidget {
  @override
  _ForgotState createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  TextEditingController _emailController = TextEditingController();
  FirebaseAuth _auth = FirebaseAuth.instance;
  bool _vis = false;

  Future resetpassword() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
                child: CircularProgressIndicator(
              color: Colors.blue,
            )));
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      Navigator.pushNamed(context, '/fourth');
    } catch (e) {
      Navigator.pop(context, true);
      setState(() {
        _vis = true;
      });
    }
  }

  Future checkConnection() async {
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
      resetpassword();
    }
  }

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 20, right: 10, top: 15),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 10, bottom: 20),
                child: Text(
                  'Please enter the email associated with your account.',
                ),
              ),
              SizedBox(height: 20.0),
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 20, right: 10),
                child: TextFormField(
                  onTap: () {
                    setState(() {
                      _vis = false;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter the email';
                    }
                    return null;
                  },
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10),
                child: Visibility(
                  child: Text(
                    "Email doesn't exists",
                    style: TextStyle(color: Colors.red),
                  ),
                  visible: _vis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 10, top: 30),
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        checkConnection();
                      }
                    },
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              Padding(
                padding: const EdgeInsets.only(top: 150),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/first');
                  },
                  child: Text(
                    'Remember Password? Log in',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
