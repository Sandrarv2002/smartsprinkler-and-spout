import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Loginpage extends StatefulWidget {
  @override
  _LoginpageState createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _password = true;
  bool _vis = false;

  // ignore: body_might_complete_normally_nullable
  Future<User?> signInWithEmailAndPassword() async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim());
      if (credential.user!.emailVerified) {
        return credential.user;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Verify Email'),
          margin: EdgeInsets.all(5),
          elevation: 10,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on FirebaseAuthException catch (e) {
      print(e.message);
      setState(() {
        _vis = true;
      });
    }
    return null;
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
      signIn();
    }
  }

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return true;
      },
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding:
                      EdgeInsets.only(left: 0, right: 80, top: 15, bottom: 30),
                  child: Text(
                    'Log in',
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Visibility(
                  child: Text(
                    "Wrong Credential",
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  visible: _vis,
                ),
                SizedBox(height: 20.0),
                TextFormField(
                    onTap: () {
                      setState(() {
                        _vis = false;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter email';
                      }
                      return null;
                    },
                    controller: _emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email',
                    )),
                SizedBox(height: 20.0),
                TextFormField(
                  controller: _passwordController,
                  enableInteractiveSelection: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter password';
                    }
                    return null;
                  },
                  obscureText: _password,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: togglepassword(),
                    labelText: 'Password',
                  ),
                ),
                SizedBox(height: 20.0),
                Padding(
                  padding: const EdgeInsets.only(left: 190),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/third');
                    },
                    child: Text(
                      "Forgot password?",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          checkConnection();
                        }
                      },
                      child: Text('Log in',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/second');
                    },
                    child: Text(
                      "Don't you have an account? Sign Up",
                      style: TextStyle(color: Colors.black),
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

  void signIn() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
                child: CircularProgressIndicator(
              color: Colors.blue,
            )));
    User? user = await signInWithEmailAndPassword();
    if (user != null) {
      print("User is logined successfully");
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      Navigator.pop(context, true);
      _auth.signOut();
      print("Error occured");
    }
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
