import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:convo/screens/common_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyScreen extends StatefulWidget {
  static const String id = 'privacy_screen';
  @override
  _PrivacyScreenState createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  Completer<WebViewController> _controller = Completer<WebViewController>();
  bool checkedValue = false;
  bool isInitialLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Privacy Policy'),
        ),
        body: SafeArea(
            child: WebView(
          initialUrl: 'https://www.google.com/',
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },
          onPageFinished: (String url) {
            if (!isInitialLoaded) {
              setState(() => isInitialLoaded = true);
            }
          },
        )),
        bottomSheet: Padding(
          padding: Platform.isIOS
              ? const EdgeInsets.symmetric(vertical: 16.0)
              : const EdgeInsets.symmetric(vertical: 0.0),
          child: CheckboxListTile(
            dense: true,
            title: Transform(
              transform: Matrix4.translationValues(-16, 0.0, 0.0),
              child: Text(
                "Accept Terms & Conditions".toUpperCase(),
                style: Theme.of(context).textTheme.overline,
              ),
            ),
            value: checkedValue,
            onChanged: (newValue) {
              setState(() {
                checkedValue = newValue;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            secondary: _bookmarkButton(),
          ),
        ));
  }

  _bookmarkButton() {
    return FutureBuilder<WebViewController>(
      future: _controller.future,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        if (controller.hasData) {
          return checkedValue
              ? FlatButton(
                  onPressed: () {
                    Navigator.pushNamed(context, CommonScreen.id);
                  },
                  child: Text(
                    'Accept'.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                )
              : FlatButton(
                  onPressed: () {},
                  child: Text('Accept'.toUpperCase()),
                );
        }
        return Container();
      },
    );
  }
}
