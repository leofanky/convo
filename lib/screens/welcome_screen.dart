import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'registration_screen.dart';
import 'package:flutter/cupertino.dart';

class WelcomeScreen extends StatefulWidget {
  static const String id = 'welcome_screen';

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Hero(
                tag: 'logotype',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      child: Center(
                          child: Image.asset('assets/images/logo-white.png')),
                      height: 100.0,
                    ),
                    SizedBox(
                      height: 48.0,
                    ),
                    RaisedButton(
                      elevation: 0,
                      colorBrightness: Brightness.dark,
                      onPressed: () {
                        Navigator.pushNamed(context, LoginScreen.id);
                      },
                      child: Text(
                        translate('button.sign_in').toUpperCase(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: FlatButton(
                colorBrightness: Brightness.dark,
                onPressed: () {
                  Navigator.pushNamed(context, RegistrationScreen.id);
                },
                child: Column(
                  children: <Widget>[
                    Text(
                      translate('button.sign_up').toUpperCase(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
