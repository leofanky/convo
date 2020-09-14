import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'chat_screen.dart';
import 'package:convo/services/chat_arguments.dart';

final _firestore = Firestore.instance;

class PreviewImageScreen extends StatefulWidget {
  final String imagePath;
  final String receiverEmail;
  final String chatID;
  final String currentUser;
  final String receiverName;

  PreviewImageScreen(
      {this.imagePath,
      this.chatID,
      this.receiverEmail,
      this.currentUser,
      this.receiverName});

  @override
  _PreviewImageScreenState createState() => _PreviewImageScreenState();
}

class _PreviewImageScreenState extends State<PreviewImageScreen> {
  String photoUrl = '';
  bool isLoading = false;

  encryptMessage(messageText) {
    if (messageText != null) {
      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encrypt(messageText, iv: iv);
      return encrypted.base16;
    }
  }

  Future uploadPhotoToMessage(chatID, receiverEmail, currentUserEmail,
      messageImagePath, context) async {
    String fileName = messageImagePath;
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(File(messageImagePath));
    StorageTaskSnapshot storageTaskSnapshot;
    uploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
          photoUrl = downloadUrl;
          _firestore
              .collection('chats')
              .document(chatID)
              .collection('messages')
              .add({
            'image': encryptMessage(photoUrl),
            'sender': encryptMessage(currentUserEmail),
            'type': encryptMessage('image'),
            'receiver': encryptMessage(receiverEmail),
            'time': DateTime.now().millisecondsSinceEpoch,
            'read': false,
          }).then((data) async {
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
    print(widget.chatID);
    print(widget.currentUser);
    print(widget.receiverEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
            }),
        title: Text(
          'Preview',
          style: Theme.of(context).textTheme.subtitle2,
        ),
        backgroundColor: Colors.white,
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
                flex: 2,
                child: Image.file(File(widget.imagePath), fit: BoxFit.cover)),
            SizedBox(height: 10.0),
            Flexible(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(60.0),
                child: RaisedButton(
                  color: Theme.of(context).primaryColor,
                  onPressed: () async {
                    await uploadPhotoToMessage(
                        widget.chatID,
                        widget.receiverEmail,
                        widget.currentUser,
                        widget.imagePath,
                        context);
                    Navigator.pushNamed(
                      context,
                      ChatScreen.id,
                      arguments: ScreenArguments(
                        chatID: widget.chatID,
                        receiverEmail: widget.receiverEmail,
                        receiverName: widget.receiverName,
                      ),
                    );
                  },
                  child: Text('Send photo to ${widget.receiverName}',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
