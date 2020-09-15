import 'package:convo/screens/privacy_screen.dart';
import 'package:convo/screens/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:convo/services/chat_arguments.dart';
import 'package:flutter_translate/flutter_translate.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = 'registration_screen';

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = Firestore.instance;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool visibleSpinner = false;
  String password;
  String email;
  String authError;
  AnimationController _controller;
  Animation _animation;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _animation = Tween(begin: 200.0, end: 150.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _showErrorDialog(String errorText) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('NOTIFICATION'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(errorText),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(
                translate('show_dialog.close'),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String subStringEmailCharacter(String email) {
    return email.substring(0, email.indexOf('@'));
  }

  void setLocalData(String email) async {
    final SharedPreferences prefs = await _prefs;
    prefs.remove('email');
    prefs.remove('name');
    prefs.setString("email", email.toLowerCase());
    prefs.setString("name", subStringEmailCharacter(email.toLowerCase()));
  }

  void pushToUserProfileData(String email) async {
    _firestore.collection('users').document(email.toLowerCase()).setData({
      'email': email.toLowerCase(),
      'photoUrl': '',
      'onlineStatus': true,
      'about': 'Hi there! That\'s all about me',
      'name': subStringEmailCharacter(email.toLowerCase()),
      'chattingWith': 'test',
      'pushToken': 'test'
    });

    setLocalData(email);
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  void register() async {
    if (email == null || email == '') {
      authError = translate('show_dialog.empty_email_field');
      _showErrorDialog(authError);
    } else if (password == null || password == '') {
      authError = translate('show_dialog.empty_password_field');
      _showErrorDialog(authError);
    } else {
      setState(() {
        visibleSpinner = true;
      });
      try {
        final newUser = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        if (newUser != null) {
          Navigator.pushNamed(context, PrivacyScreen.id);
        }
        setState(() {
          visibleSpinner = false;
        });
      } catch (e) {
        print(e);
        switch (e.code) {
          case 'ERROR_INVALID_EMAIL':
            authError = translate('show_dialog.invalid_email');
            _showErrorDialog(authError);
            break;
          case 'ERROR_WEAK_PASSWORD':
            authError = translate('show_dialog.weak_password');
            _showErrorDialog(authError);
            break;
          case 'ERROR_EMAIL_ALREADY_IN_USE':
            authError = translate('show_dialog.already_in_use_email');
            _showErrorDialog(authError);
            break;
          default:
            authError = 'Error';
            print(authError);
            break;
        }
        setState(() {
          visibleSpinner = false;
        });
      }
      pushToUserProfileData(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        progressIndicator: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
        color: Theme.of(context).primaryColor,
        inAsyncCall: visibleSpinner,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Hero(
                    tag: 'logotype',
                    child: Material(
                      elevation: 3,
                      child: Container(
                        color: Theme.of(context).primaryColor,
                        height: _animation.value,
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo-white.png',
                            height: 80,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(
                          height: 32.0,
                        ),
                        Center(
                          child: Text(
                            translate('register.title'),
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                        SizedBox(
                          height: 32.0,
                        ),
                        TextField(
                          cursorColor: Theme.of(context).primaryColor,
                          onChanged: (value) {
                            email = value;
                          },
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: translate('text_fields.hint_email_field'),
                            labelText: translate('text_fields.email_field'),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 32.0,
                        ),
                        TextFormField(
                          focusNode: _focusNode,
                          obscureText: true,
                          cursorColor: Theme.of(context).primaryColor,
                          onChanged: (value) {
                            password = value;
                          },
                          decoration: InputDecoration(
                            hintText:
                                translate('text_fields.hint_password_field'),
                            labelText: translate('text_fields.password_field'),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 32.0,
                        ),
                        RaisedButton(
                          elevation: 0.0,
                          color: Theme.of(context).primaryColor,
                          colorBrightness: Brightness.dark,
                          onPressed: register,
                          child: Text(
                            translate('button.sign_up').toUpperCase(),
                          ),
                        ),
                        SizedBox(
                          height: 32.0,
                        ),
                        FlatButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              ResetPassword.id,
                              arguments: RegistrationArguments(
                                currentEmail: email,
                              ),
                            );
                          },
                          child: Text(
                            translate('button.forgot_password').toUpperCase(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: FlatButton(
                  onPressed: () {
                    Navigator.pushNamed(context, LoginScreen.id);
                  },
                  child: Text(
                    translate('button.login').toUpperCase(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
