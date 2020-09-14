import 'package:flutter/material.dart';
import 'chats_screen.dart';
import 'contacts_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_translate/flutter_translate.dart';

import 'dart:io';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CommonScreen extends StatefulWidget {
  static const String id = 'common_screen';

  @override
  _CommonScreenState createState() => _CommonScreenState();
}

class _CommonScreenState extends State<CommonScreen>
    with WidgetsBindingObserver {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final _firestore = Firestore.instance;
  FirebaseUser loggedInUser;
  String _email;
  final _auth = FirebaseAuth.instance;
  int unreadMessages;
  bool userOnlineStatus = true;
  var pages = [
    ContactsScreen(),
    ChatsScreen(),
    SettingsScreen(),
  ];
  int _selectedIndex = 1;
  TextEditingController editingController = TextEditingController();
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    getCurrentUser();

    WidgetsBinding.instance.addObserver(this);

    registerNotification();
    configLocalNotification();
  }

  void registerNotification() {
    firebaseMessaging.requestNotificationPermissions();

    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        print('onMessage: $message');
        Platform.isAndroid
            ? showNotification(message['notification'])
            : showNotification(message['aps']['alert']);
        return;
      },
      onResume: (Map<String, dynamic> message) {
        print('onResume: $message');
        return;
      },
      onLaunch: (Map<String, dynamic> message) {
        print('onLaunch: $message');
        return;
      },
    );

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      Firestore.instance
          .collection('users')
          .document(loggedInUser.email)
          .updateData({'pushToken': token});
    }).catchError((err) {
      print(err.message.toString());
    });
  }

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid
          ? 'com.LeonardoFanchini.convo'
          : 'com.LeonardoFanchini.convo',
      'Flutter chat',
      'Desc',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(0, message['title'].toString(),
        message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));
  }

  void configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void getLocalData() async {
    final SharedPreferences prefs = await _prefs;
    _email = prefs.getString('email');
    switchToOnline(_email);
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        getLocalData();
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        onDetached(_email);
        break;
      case AppLifecycleState.resumed:
        onResumed(_email);
        break;
    }
  }

  void onDetached(String email) {
    print('detached');
    switchToOffline(email);
  }

  void onResumed(String email) {
    print('resumed');
    switchToOnline(email);
  }

  void switchToOffline(String currentUserEmail) {
    print(currentUserEmail);
    _firestore.collection('users').document(currentUserEmail).setData({
      'onlineStatus': false,
    }, merge: true);
  }

  void switchToOnline(String currentUserEmail) async {
    print(currentUserEmail);
    await _firestore.collection('users').document(currentUserEmail).setData({
      'onlineStatus': true,
    }, merge: true);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: null,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        backgroundColor: Colors.white,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box),
            title: Text(translate('contacts.title')),
          ),
          BottomNavigationBarItem(
            icon: Stack(
              alignment: Alignment.topRight,
              children: <Widget>[
                Icon(Icons.chat),
              ],
            ),
            title: Text(translate('chats.title')),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            title: Text(translate('settings.title')),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
