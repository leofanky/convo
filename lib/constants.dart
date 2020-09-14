import 'package:flutter/material.dart';

final ThemeData chatTheme = ThemeData(
  scaffoldBackgroundColor: Color(0xffffffff),
  brightness: Brightness.light,
  tabBarTheme: TabBarTheme(
    indicatorSize: TabBarIndicatorSize.tab,
    labelColor: Color(0xffffffff),
    unselectedLabelColor: Color(0xb2ffffff),
  ),
  primaryColor: Color(0xff880e4f),
  primaryColorBrightness: Brightness.dark,
  buttonColor: Color(0x12ffffff),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color(0xff880e4f),
  ),
  errorColor: Color(0xffff6d00),
  textTheme: TextTheme(
    subtitle1: TextStyle(
      color: Colors.black87,
    ),
    bodyText1: TextStyle(
      color: Colors.black87,
    ),
    caption: TextStyle(
      color: Color(0xdd000000),
      fontSize: null,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
    ),
    button: TextStyle(
      color: Color(0xdd000000),
      fontSize: null,
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.normal,
    ),
    overline: TextStyle(
      color: Color(0xff000000),
      fontSize: null,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
    ),
  ),
  primaryTextTheme: TextTheme(
    subtitle2: TextStyle(
      color: Color(0xff880e4f),
    ),
  ),
);
