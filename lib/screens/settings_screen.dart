import 'dart:async';
import 'dart:io';
import 'package:convo/screens/delete_account_screen.dart';
import 'package:convo/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_screen.dart';
import 'package:flutter_translate/flutter_translate.dart';

final _firestore = Firestore.instance;
final _auth = FirebaseAuth.instance;
String currentUserEmail;

class SettingsScreen extends StatefulWidget {
  static const String id = 'settings_screen';
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool editProfileMode;
  String aboutTextField = '';
  String nameTextField = '';
  String emailTextField = '';
  final _aboutField = TextEditingController();
  final _nameField = TextEditingController();
  final _emailField = TextEditingController();
  String photoUrl = '';
  File avatarImageFile;
  String _email;
  String _locale;
  String currentLocale;
  bool isLoading = false;
  final picker = ImagePicker();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future getLocalData() async {
    final SharedPreferences prefs = await _prefs;
    _email = prefs.getString('email');
    _locale = prefs.getString('locale');
    setState(() {
      currentUserEmail = _email;
      currentLocale = _locale;
    });
  }

  @override
  void initState() {
    super.initState();
    getLocalData();
    editProfileMode = true;
  }

  @override
  void dispose() {
    _emailField.dispose();
    _aboutField.dispose();
    _nameField.dispose();
    super.dispose();
  }

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile.path != null) {
      setState(() {
        avatarImageFile = File(pickedFile.path);
        isLoading = true;
      });
    }
    uploadFile();
  }

  Future uploadFile() async {
    String fileName =
        currentUserEmail + DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(avatarImageFile);
    StorageTaskSnapshot storageTaskSnapshot;
    uploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
          photoUrl = downloadUrl;
          _firestore
              .collection('users')
              .document(currentUserEmail)
              .updateData({'photoUrl': photoUrl}).then((data) async {
            setState(() {
              isLoading = false;
            });
            Scaffold.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Theme.of(context).primaryColor,
                content: Text(
                  translate('notification_snack_bar.success_upload'),
                ),
              ),
            );
          }).catchError((err) {
            setState(() {
              isLoading = false;
            });
            Scaffold.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Theme.of(context).primaryColor,
                content: Text(
                  err.toString(),
                ),
              ),
            );
          });
        }, onError: (err) {
          setState(() {
            isLoading = false;
          });
          Scaffold.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).primaryColor,
              content: Text(
                translate('notification_snack_bar.file_is_not_image'),
              ),
            ),
          );
        });
      } else {
        setState(() {
          isLoading = false;
        });
        Scaffold.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).primaryColor,
            content: Text(
              translate('notification_snack_bar.file_is_not_image'),
            ),
          ),
        );
      }
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Scaffold.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).primaryColor,
          content: Text(
            err.toString(),
          ),
        ),
      );
    });
  }

  switchUserToOffline(currentUserEmail) async {
    await _firestore.collection('users').document(currentUserEmail).setData({
      'onlineStatus': false,
    }, merge: true);
  }

  _signOut() async {
    print('signout');
    print(currentUserEmail);
    await switchUserToOffline(currentUserEmail);
    await _auth.signOut().then((value) {
      Navigator.pushReplacementNamed(context, LoginScreen.id);
    });
  }

  void updateProfileData(snapshot) {
    if (editProfileMode) {
      _aboutField.text = snapshot.data['about'];
      _nameField.text = snapshot.data['name'];
      _emailField.text = snapshot.data['email'];
    } else {
      if (_aboutField.text.isEmpty ||
          _nameField.text.isEmpty ||
          _emailField.text.isEmpty) {
        Scaffold.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).errorColor,
            content: Row(
              children: <Widget>[
                _aboutField.text.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                            translate('notification_snack_bar.empty_about')),
                      )
                    : SizedBox(),
                _nameField.text.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                            translate('notification_snack_bar.empty_name')),
                      )
                    : SizedBox(),
                _emailField.text.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                            translate('notification_snack_bar.empty_email')),
                      )
                    : SizedBox(),
              ],
            ),
          ),
        );
      } else {
        _firestore.collection('users').document(currentUserEmail).setData({
          'name': _nameField.text,
          'about': _aboutField.text,
          'email': _emailField.text,
        }, merge: true);

        Scaffold.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).primaryColor,
            content: Text(
              translate('notification_snack_bar.changes_saved'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StreamBuilder(
              stream: _firestore
                  .collection('users')
                  .document(currentUserEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Stack(
                          alignment: AlignmentDirectional.centerEnd,
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                Container(
                                  height: 150,
                                  color: Theme.of(context).primaryColor,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 24.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: editProfileMode
                                              ? snapshot.data['photoUrl'] != ''
                                                  ? CircleAvatar(
                                                      radius: 36,
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .primaryColor,
                                                      backgroundImage:
                                                          NetworkImage(
                                                        snapshot
                                                            .data['photoUrl'],
                                                      ),
                                                    )
                                                  : CircleAvatar(
                                                      radius: 36,
                                                      backgroundColor:
                                                          Colors.black54,
                                                      child: Text(
                                                        snapshot.data['name'][0]
                                                            .toString()
                                                            .toUpperCase(),
                                                      ),
                                                    )
                                              : GestureDetector(
                                                  onTap: getImage,
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: <Widget>[
                                                      CircleAvatar(
                                                        radius: 36,
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .primaryColor,
                                                        backgroundImage:
                                                            NetworkImage(
                                                                snapshot.data[
                                                                    'photoUrl']),
                                                      ),
                                                      Container(
                                                        width: 56,
                                                        height: 56,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black54,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          30)),
                                                        ),
                                                        child: Icon(
                                                          Icons.camera_alt,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      Positioned(
                                                        child: isLoading
                                                            ? Container(
                                                                child: Center(
                                                                  child: CircularProgressIndicator(
                                                                      valueColor: AlwaysStoppedAnimation<
                                                                          Color>(Theme.of(
                                                                              context)
                                                                          .primaryColor)),
                                                                ),
                                                              )
                                                            : Container(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            editProfileMode
                                                ? Text(
                                                    snapshot.data['name'],
                                                    style: Theme.of(context)
                                                        .accentTextTheme
                                                        .headline6,
                                                  )
                                                : Container(
                                                    width: 150,
                                                    child: TextField(
                                                      autofocus: true,
                                                      controller: _nameField,
                                                      cursorColor: Colors.white,
                                                      style: Theme.of(context)
                                                          .accentTextTheme
                                                          .headline6,
                                                      decoration:
                                                          InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        0.0),
                                                        border:
                                                            InputBorder.none,
                                                        hintText: snapshot
                                                            .data['name'],
                                                        hintStyle:
                                                            Theme.of(context)
                                                                .accentTextTheme
                                                                .headline6,
                                                      ),
                                                    ),
                                                  ),
                                            SizedBox(
                                              height: 8.0,
                                            ),
                                            editProfileMode
                                                ? Text(
                                                    snapshot.data['email'],
                                                    style: Theme.of(context)
                                                        .accentTextTheme
                                                        .caption,
                                                  )
                                                : Container(
                                                    width: 150,
                                                    child: TextField(
                                                      controller: _emailField,
                                                      cursorColor: Colors.white,
                                                      style: Theme.of(context)
                                                          .accentTextTheme
                                                          .caption,
                                                      decoration:
                                                          InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        0.0),
                                                        border:
                                                            InputBorder.none,
                                                        hintText: snapshot
                                                            .data['email']
                                                            .toString(),
                                                        hintStyle:
                                                            Theme.of(context)
                                                                .accentTextTheme
                                                                .caption,
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Text(
                                        translate('settings.about')
                                            .toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .overline,
                                      ),
                                      SizedBox(
                                        height: 8.0,
                                      ),
                                      editProfileMode
                                          ? Text(
                                              snapshot.data['about'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1,
                                            )
                                          : TextField(
                                              controller: _aboutField,
                                              cursorColor:
                                                  Theme.of(context).accentColor,
                                              maxLines: null,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 0.0),
                                                border: InputBorder.none,
                                                hintMaxLines: 10,
                                                hintText:
                                                    snapshot.data['about'],
                                                hintStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodyText1,
                                              ),
                                              onChanged: (value) {
                                                aboutTextField = value;
                                              },
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              top: 120.0,
                              right: 0.0,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: FloatingActionButton(
                                  child: editProfileMode
                                      ? Icon(Icons.edit)
                                      : Icon(Icons.check),
                                  onPressed: () {
                                    updateProfileData(snapshot);
                                    setState(() {
                                      if (editProfileMode) {
                                        editProfileMode = false;
                                      } else {
                                        editProfileMode = true;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ]),
                    ],
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  );
                }
              }),
          SizedBox(
            height: 16.0,
          ),
          Material(
            elevation: 4,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                  ),
                  child: Text(
                    translate('settings.title').toUpperCase(),
                    style: Theme.of(context).textTheme.overline,
                  ),
                ),
                MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      ProfileListTile(
                        icon: Icon(
                          Icons.translate,
                          color: Colors.white,
                        ),
                        heading: translate('language.title'),
                        rightHandWidget: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                        ),
                        onPress: () {
                          Navigator.pushNamed(context, LanguageScreen.id);
                        },
                      ),
                      ProfileListTile(
                        onPress: () {
                          Navigator.pushNamed(context, DeleteAccountScreen.id);
                        },
                        icon: Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                        ),
                        heading: 'Delete account & all data',
                        rightHandWidget: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                        ),
                      ),
                      ProfileListTile(
                        icon: Icon(
                          Icons.exit_to_app,
                          color: Colors.white,
                        ),
                        heading: translate('button.logout'),
                        rightHandWidget: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                        ),
                        onPress: _signOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ProfileListTile extends StatelessWidget {
  ProfileListTile({
    this.icon,
    this.heading,
    this.onPress,
    this.rightHandWidget,
  });

  final Icon icon;
  final Widget rightHandWidget;
  final String heading;
  final Function onPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPress,
      child: Container(
        height: 72,
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                right: 32.0,
                left: 16.0,
                top: 16.0,
                bottom: 16,
              ),
              child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: icon,
                  )),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        heading,
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: rightHandWidget,
                      )
                    ],
                  ),
                  Divider(
                    height: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
