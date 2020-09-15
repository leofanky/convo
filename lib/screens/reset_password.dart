import 'package:convo/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:convo/services/chat_arguments.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'login_screen.dart';
import 'package:flutter_translate/flutter_translate.dart';

class ResetPassword extends StatefulWidget {
  static const String id = 'reset_password';
  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _auth = FirebaseAuth.instance;
  FirebaseUser loggedInUser;
  bool visibleSpinner = false;
  String password;
  String email;
  String resetError;
  final _emailResetPassword = TextEditingController();
  RegistrationArguments registrationArguments;

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email).then((value) {
      _showErrorDialog(
        translate('show_dialog.reset_password_successfully'),
        () => Navigator.pushNamed(context, LoginScreen.id),
      );
    }).catchError(
      (error) {
        print(error);
        switch (error.code) {
          case 'ERROR_USER_NOT_FOUND':
            resetError = translate('show_dialog.no_user_in_db');
            _showErrorDialog(
              resetError,
              () => Navigator.of(context).pop(),
            );
            visibleSpinner = false;
            break;
          case 'ERROR_INVALID_EMAIL':
            resetError = translate('show_dialog.bad_email');
            _showErrorDialog(
              resetError,
              () => Navigator.of(context).pop(),
            );
            visibleSpinner = false;
            break;
          case 'ERROR_NETWORK_REQUEST_FAILED':
            resetError = translate('show_dialog.network_error');
            _showErrorDialog(
              resetError,
              () => Navigator.of(context).pop(),
            );
            visibleSpinner = false;
            break;
          default:
            resetError = 'Error';
            print(resetError);
            visibleSpinner = false;
            break;
        }
      },
    );
  }

  Future<void> _showErrorDialog(String errorText, Function onPressed) async {
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
              onPressed: onPressed,
            ),
          ],
        );
      },
    );
  }

  void assignEmailToTextField() {
    Future.delayed(Duration.zero, () {
      setState(() {
        registrationArguments = ModalRoute.of(context).settings.arguments;
      });

      if (registrationArguments.currentEmail != null) {
        _emailResetPassword.text = registrationArguments.currentEmail;
        email = registrationArguments.currentEmail;
      } else {
        _emailResetPassword.text = '';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    assignEmailToTextField();
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
                        height: 200.0,
                        width: 200.0,
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
                            translate('reset_password.title'),
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
                          controller: _emailResetPassword,
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: Theme.of(context).primaryColor,
                          decoration: InputDecoration(
                            hintText: registrationArguments.currentEmail,
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
                        RaisedButton(
                          elevation: 0.0,
                          color: Theme.of(context).primaryColor,
                          colorBrightness: Brightness.dark,
                          onPressed: () async {
                            print(email);
                            setState(() {
                              visibleSpinner = true;
                            });
                            resetPassword(email);
                          },
                          child: Text(
                            translate('button.reset_password').toUpperCase(),
                          ),
                        ),
                        SizedBox(
                          height: 32.0,
                        ),
                        FlatButton(
                          onPressed: () {
                            Navigator.pushNamed(context, RegistrationScreen.id);
                          },
                          child: Text(
                            translate('button.sign_up').toUpperCase(),
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
                    translate('button.sign_in').toUpperCase(),
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
