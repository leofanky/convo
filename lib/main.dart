import 'package:convo/screens/chats_screen.dart';
import 'package:flutter/material.dart';
import 'package:convo/screens/privacy_screen.dart';
import 'package:convo/screens/welcome_screen.dart';
import 'package:convo/screens/login_screen.dart';
import 'package:convo/screens/registration_screen.dart';
import 'package:convo/screens/chat_screen.dart';
import 'package:convo/screens/common_screen.dart';
import 'screens/language_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/reset_password.dart';
import 'constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/delete_account_screen.dart';
import 'screens/camera_screen.dart';

void main() async {
  var delegate = await LocalizationDelegate.create(
      fallbackLocale: 'en_US',
      supportedLocales: ['en_US', 'es', 'fa', 'ru', 'de'],
      preferences: TranslatePreferences());
  runApp(LocalizedApp(delegate, Convo()));
}

class Convo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var localizationDelegate = LocalizedApp.of(context).delegate;
    return LocalizationProvider(
      state: LocalizationProvider.of(context).state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: chatTheme,
        home: WelcomeScreen(),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          localizationDelegate
        ],
        supportedLocales: localizationDelegate.supportedLocales,
        locale: localizationDelegate.currentLocale,
        initialRoute: WelcomeScreen.id,
        routes: {
          WelcomeScreen.id: (context) => WelcomeScreen(),
          ResetPassword.id: (context) => ResetPassword(),
          RegistrationScreen.id: (context) => RegistrationScreen(),
          LoginScreen.id: (context) => LoginScreen(),
          ChatScreen.id: (context) => ChatScreen(),
          ChatsScreen.id: (context) => ChatsScreen(),
          CommonScreen.id: (context) => CommonScreen(),
          SettingsScreen.id: (context) => SettingsScreen(),
          LanguageScreen.id: (context) => LanguageScreen(),
          CameraScreen.id: (context) => CameraScreen(),
          DeleteAccountScreen.id: (context) => DeleteAccountScreen(),
          PrivacyScreen.id: (context) => PrivacyScreen(),
        },
      ),
    );
  }
}

class TranslatePreferences implements ITranslatePreferences {
  static const String _selectedLocaleKey = 'selected_locale';
  @override
  Future<Locale> getPreferredLocale() async {
    final preferences = await SharedPreferences.getInstance();
    if (!preferences.containsKey(_selectedLocaleKey)) return null;
    var locale = preferences.getString(_selectedLocaleKey);
    return localeFromString(locale);
  }

  @override
  Future savePreferredLocale(Locale locale) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_selectedLocaleKey, localeToString(locale));
  }
}
