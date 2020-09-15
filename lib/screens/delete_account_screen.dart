import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:convo/screens/welcome_screen.dart';
import 'package:flutter_translate/flutter_translate.dart';

class DeleteAccountScreen extends StatefulWidget {
  static const String id = 'delete_account_screen';

  @override
  _DeleteAccountScreenState createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = Firestore.instance;
  String password;
  FocusNode _focusNode = FocusNode();
  String resetError;
  bool visibleSpinner = false;

  void assignEmailToTextField() {}

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

  _deleteUserChatsFromFireStore() async {
    print('4+++++');

    FirebaseUser user = await _auth.currentUser();

    print(user.email);

    _firestore.collection('chats').snapshots().forEach((element) {
      print('element printing ${element.toString()}');

      element.documents.forEach((doc) {
        if (doc.data['user1'] == user.email ||
            doc.data['user2'] == user.email) {
          print('doc user chats ${doc.documentID}');
          _firestore
              .collection('chats')
              .document(doc.documentID)
              .delete()
              .then((value) {
            print('${doc.documentID} chat was deleted');
          });
        }
      });
    });
  }

  _deleteUserFromFireStore(context, userEmail) {
    return _firestore.collection('users').document(userEmail).delete();
  }

  _deleteDataUser(context, password) async {
    print(password);
    if (password == null || password == "") {
      resetError = translate('show_dialog.empty_password_field');
      _showErrorDialog(
        resetError,
        () => Navigator.of(context).pop(),
      );
    } else {
      FirebaseUser user = await _auth.currentUser();

      user
          .reauthenticateWithCredential(
        EmailAuthProvider.getCredential(
          email: user.email,
          password: password,
        ),
      )
          .then((value) {
        print('1+++++');

        print(user.email);
        _deleteUserFromFireStore(context, user.email).then((value) {
          print('2+++++');
          _deleteUserChatsFromFireStore();
          user.delete().then((value) {
            print('success delete user from firebase auth');
          }).catchError((error) {
            print(error);
          });
          resetError =
              translate('notification_snack_bar.account_successfully_deleted');
          _showErrorDialog(
            resetError,
            () => Navigator.pushNamed(context, WelcomeScreen.id),
          );
        });
      }).catchError(
        (error) {
          print(error);
          switch (error.code) {
            case 'ERROR_WRONG_PASSWORD':
              resetError = translate('show_dialog.wrong_password');
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
  }

  @override
  Widget build(BuildContext globalContext) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
          ),
          onPressed: () => Navigator.pop(globalContext),
        ),
        title: Text(translate('delete_account.title')),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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
                      translate('delete_account.enter_password'),
                      style: Theme.of(globalContext).textTheme.headline6,
                    ),
                  ),
                  SizedBox(
                    height: 32.0,
                  ),
                  TextFormField(
                    focusNode: _focusNode,
                    obscureText: true,
                    cursorColor: Theme.of(globalContext).primaryColor,
                    onChanged: (value) {
                      password = value;
                    },
                    decoration: InputDecoration(
                      hintText: translate('text_fields.hint_password_field'),
                      labelText: translate('text_fields.password_field'),
                      labelStyle: TextStyle(
                          color: Theme.of(globalContext).disabledColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(globalContext).disabledColor,
                            width: 2.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(globalContext).disabledColor,
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
                    color: Theme.of(globalContext).errorColor,
                    colorBrightness: Brightness.dark,
                    onPressed: () async {
                      print(password);
                      setState(() {});
                      _deleteDataUser(globalContext, password);
                    },
                    child: Text(
                      translate('button.delete_account').toUpperCase(),
                    ),
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
