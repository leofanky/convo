import 'package:convo/screens/common_screen.dart';
import 'package:convo/screens/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'registration_screen.dart';
import 'package:convo/services/chat_arguments.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_translate/flutter_translate.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
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

  void setLocalData(String email) async {
    final SharedPreferences prefs = await _prefs;
    print('2 step login email set local data $email');
    prefs.remove('email');
    prefs.setString("email", email);
  }

  void login() async {
    if (email == null || email == '') {
      authError = translate('show_dialog.empty_email_field');
      showErrorDialog(authError, context);
    } else if (password == null || password == '') {
      authError = translate('show_dialog.empty_password_field');
      showErrorDialog(authError, context);
    } else {
      setState(() {
        visibleSpinner = true;
      });
      try {
        final loginUser = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (loginUser != null) {
          print('1 step ');
          setLocalData(email);
          Navigator.pushNamed(context, CommonScreen.id);
        }
        setState(() {
          visibleSpinner = false;
        });
      } catch (e) {
        switch (e.code) {
          case 'ERROR_INVALID_EMAIL':
            authError = translate('show_dialog.invalid_email');
            showErrorDialog(authError, context);
            break;
          case 'ERROR_USER_NOT_FOUND':
            authError = translate('show_dialog.user_not_found');
            showErrorDialog(authError, context);
            break;
          case 'ERROR_WRONG_PASSWORD':
            authError = translate('show_dialog.wrong_password');
            showErrorDialog(authError, context);
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
    }
  }

  Future<void> showErrorDialog(String errorText, BuildContext context) async {
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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Hero(
                    tag: 'logotype',
                    child: Material(
                      elevation: 3,
                      color: Theme.of(context).primaryColor,
                      child: Container(
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
                            translate('sign_in.title'),
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                        SizedBox(
                          height: 32.0,
                        ),
                        TextField(
                          onChanged: (value) {
                            email = value;
                          },
                          cursorColor: Theme.of(context).primaryColor,
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
                          onChanged: (value) {
                            password = value;
                          },
                          cursorColor: Theme.of(context).primaryColor,
                          decoration: InputDecoration(
                            hintText:
                                translate('text_fields.hint_password_field'),
                            labelText: translate('text_fields.password_field'),
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
                        RaisedButton(
                          elevation: 0.0,
                          color: Theme.of(context).primaryColor,
                          colorBrightness: Brightness.dark,
                          onPressed: login,
                          child: Text(
                            translate('button.sign_in').toUpperCase(),
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
                    Navigator.pushNamed(context, RegistrationScreen.id);
                  },
                  child: Text(
                    translate('button.sign_up').toUpperCase(),
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
