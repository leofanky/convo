import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageScreen extends StatefulWidget {
  static const String id = 'language_screen';

  @override
  _LanguageScreenState createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _language = 'en_US';
  String currentLocale = 'en_US';
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Future getLocalData() async {
    final SharedPreferences prefs = await _prefs;
    _language = prefs.getString('locale');
    setState(() {
      currentLocale = _language;
    });
  }

  void setLocalData(String locale) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setString("locale", locale);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getLocalData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(translate('language.selection.title')),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text(
                translate('language.name.en').toUpperCase(),
              ),
              leading: Radio(
                activeColor: Theme.of(context).primaryColor,
                value: 'en_US',
                groupValue: currentLocale,
                onChanged: (value) {
                  print(value);
                  changeLocale(context, value);
                  setState(() {
                    currentLocale = value;
                  });
                  setLocalData(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
            ListTile(
              title: Text(translate('language.name.de').toUpperCase()),
              leading: Radio(
                activeColor: Theme.of(context).primaryColor,
                value: 'de',
                groupValue: currentLocale,
                onChanged: (value) {
                  print(value);
                  changeLocale(context, value);
                  setState(() {
                    currentLocale = value;
                  });
                  setLocalData(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
            ListTile(
              title: Text(translate('language.name.es').toUpperCase()),
              leading: Radio(
                activeColor: Theme.of(context).primaryColor,
                value: 'es',
                groupValue: currentLocale,
                onChanged: (value) {
                  print(value);
                  changeLocale(context, value);
                  setState(() {
                    currentLocale = value;
                  });
                  setLocalData(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
            ListTile(
              title: Text(translate('language.name.ar').toUpperCase()),
              leading: Radio(
                activeColor: Theme.of(context).primaryColor,
                value: 'ar',
                groupValue: currentLocale,
                onChanged: (value) {
                  print(value);
                  changeLocale(context, value);
                  setState(() {
                    currentLocale = value;
                  });
                  setLocalData(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
            ListTile(
              title: Text(translate('language.name.ru').toUpperCase()),
              leading: Radio(
                activeColor: Theme.of(context).primaryColor,
                value: 'ru',
                groupValue: currentLocale,
                onChanged: (value) {
                  print(value);
                  changeLocale(context, value);
                  setState(() {
                    currentLocale = value;
                  });
                  setLocalData(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
            ListTile(
              title: Text(translate('language.name.fa').toUpperCase()),
              leading: Radio(
                activeColor: Theme.of(context).primaryColor,
                value: 'fa',
                groupValue: currentLocale,
                onChanged: (value) {
                  changeLocale(context, value);
                  setState(() {
                    currentLocale = value;
                  });
                  setLocalData(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
            ListTile(
              title: Text(translate('language.name.fr').toUpperCase()),
              leading: Radio(
                activeColor: Theme.of(context).primaryColor,
                value: 'fr',
                groupValue: currentLocale,
                onChanged: (value) {
                  print(value);
                  changeLocale(context, value);
                  setState(() {
                    currentLocale = value;
                  });
                  setLocalData(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
