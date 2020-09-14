import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convo/services/chat_arguments.dart';
import 'package:convo/services/helpers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'camera_screen.dart';
import 'common_screen.dart';

final _firestore = Firestore.instance;

String currentUserEmail;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final textEditingController = TextEditingController();
  String messageText;
  bool textFocusActive = false;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String photoUrl = '';
  File messageImageFile;
  String _email;
  String _locale;
  String currentLocale;
  bool isLoading = false;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getLocalData();
  }

  Future getLocalData() async {
    final SharedPreferences prefs = await _prefs;
    _email = prefs.getString('email');
    _locale = prefs.getString('locale');
    setState(() {
      currentUserEmail = _email;
      currentLocale = _locale;
    });
    print('shared prefs chat screen $currentUserEmail');
  }

  // TODO check on iphone set state focus active text field

  Future getImage(chatID, receiverEmail, senderEmail) async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile.path != null) {
      setState(() {
        messageImageFile = File(pickedFile.path);
        isLoading = true;
      });
    }
    uploadFileToMessage(chatID, receiverEmail, senderEmail);
  }

  Future uploadFileToMessage(chatID, receiverEmail, senderEmail) async {
    String fileName = currentUserEmail;
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(messageImageFile);
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
            'sender': encryptMessage(senderEmail),
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
  }

  encryptMessage(messageText) {
    if (messageText != null) {
      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encrypt(messageText, iv: iv);

      return encrypted.base16;
    }
  }

  @override
  Widget build(BuildContext globalContext) {
    final ScreenArguments args =
        ModalRoute.of(globalContext).settings.arguments;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () async {
              final snapshot = await _firestore
                  .collection('chats')
                  .document(args.chatID)
                  .collection('messages')
                  .getDocuments();

              if (snapshot.documents.length == 0) {
                _firestore
                    .collection('chats')
                    .document(args.chatID)
                    .delete()
                    .then((value) {
                  print('chat success clean from firestore');
                });
              }

              Navigator.pushNamed(
                context,
                CommonScreen.id,
              );
            }),
        actions: <Widget>[
          StreamBuilder(
              stream: _firestore
                  .collection('users')
                  .document(args.receiverEmail)
                  .snapshots(),
              builder: (context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  );
                }

                if (snapshot.data['photoUrl'] != null) {
                  print(snapshot.data['photoUrl']);
                  print(snapshot.data['name']);
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      bottom: 8.0,
                      right: 16.0,
                    ),
                    child: snapshot.data['photoUrl'] != ''
                        ? CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColor,
                            backgroundImage:
                                NetworkImage(snapshot.data['photoUrl']),
                          )
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(snapshot.data['name'][0]
                                .toString()
                                .toUpperCase()),
                          ),
                  );
                } else {
                  return Container();
                }
              }),
        ],
        title: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    args.receiverName,
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  SizedBox(
                    height: 4.0,
                  ),
                  StreamBuilder(
                      stream: _firestore
                          .collection('users')
                          .document(args.receiverEmail)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                          );
                        }

                        if (snapshot.data['photoUrl'] != null) {
                          return snapshot.data['onlineStatus'] == true
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      width: 4.0,
                                      height: 4.0,
                                      decoration: new BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 8.0,
                                    ),
                                    Text(
                                      translate('status.online').toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .overline
                                          .copyWith(color: Colors.black38),
                                    ),
                                  ],
                                )
                              : Text(
                                  translate('status.offline').toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .overline
                                      .copyWith(color: Colors.black38),
                                );
                        } else {
                          return Container();
                        }
                      }),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(
              chatID: args.chatID,
              globalContext: context,
            ),
            SizedBox(
              height: 16,
            ),
            Material(
              elevation: 16,
              child: Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        cursorColor: Theme.of(context).primaryColor,
                        maxLines: null,
                        controller: textEditingController,
                        onChanged: (value) {
                          messageText = value;
                          setState(() {
                            value.length != 0
                                ? textFocusActive = true
                                : textFocusActive = false;
                          });
                        },
                        decoration: InputDecoration(
                          suffixIcon: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              FlatButton(
                                onPressed: () {
                                  textEditingController.clear();
                                  print(messageText);
                                  if (messageText != null ||
                                      messageText == '') {
                                    _firestore
                                        .collection('chats')
                                        .document(args.chatID)
                                        .collection('messages')
                                        .add({
                                      'text': encryptMessage(messageText),
                                      'sender':
                                          encryptMessage(currentUserEmail),
                                      'type': encryptMessage('text'),
                                      'receiver':
                                          encryptMessage(args.receiverEmail),
                                      'time':
                                          DateTime.now().millisecondsSinceEpoch,
                                      'read': false,
                                    });
                                    _firestore
                                        .collection('chats')
                                        .document(args.chatID)
                                        .setData({
                                      'lastMessageText': messageText,
                                      'lastMessageTime':
                                          DateTime.now().millisecondsSinceEpoch,
                                    }, merge: true);
                                  } else {
                                    print('e');
                                  }

                                  setState(() {
                                    textFocusActive = false;
                                  });
                                },
                                child: textFocusActive
                                    ? Transform.rotate(
                                        angle: -90 * math.pi / 180,
                                        child: Container(
                                          width: 35.0,
                                          height: 35.0,
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.send,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.send,
                                      ),
                              ),
                            ],
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20.0),
                          hintText: translate('text_fields.hint_chat_field'),
                          border: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.photo_camera),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        CameraScreen.id,
                        arguments: ScreenArguments(
                          chatID: args.chatID,
                          receiverEmail: args.receiverEmail,
                          currentUser: currentUserEmail,
                          receiverName: args.receiverName,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file),
                    onPressed: () async {
                      print(
                          '${args.chatID}  ${args.receiverEmail} $currentUserEmail');
                      await getImage(
                          args.chatID, args.receiverEmail, currentUserEmail);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.phone),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.place),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.mic),
                    onPressed: () {},
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

class MessageStream extends StatefulWidget {
  MessageStream({
    this.chatID,
    this.globalContext,
  });
  final String chatID;
  final BuildContext globalContext;

  @override
  _MessageStreamState createState() => _MessageStreamState();
}

class _MessageStreamState extends State<MessageStream> {
  readMessages(messageReceiver, isRead, messageID) async {
    if (messageReceiver == currentUserEmail && isRead == false) {
      await _firestore
          .collection("chats")
          .document(widget.chatID)
          .collection('messages')
          .document(messageID)
          .setData({
        'read': true,
      }, merge: true);
    }
  }

  decryptMessage(encryptedText) {
    if (encryptedText != null) {
      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decrypt16(encryptedText, iv: iv);

      return decrypted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .document(widget.chatID)
          .collection('messages')
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Theme.of(context).primaryColor,
            ),
          );
        }
        final messages = snapshot.data.documents;

        List<MessageBubble> messageWidgets = [];
        for (var message in messages) {
          final messageText = decryptMessage(message.data['text']);
          final messageImage = decryptMessage(message.data['image']);
          final messageType = decryptMessage(message.data['type']);
          final messageSender = decryptMessage(message.data['sender']);
          final messageReceiver = decryptMessage(message.data['receiver']);
          final messageTime = readTimestamp(message.data['time']);
          final isRead = message.data['read'];
          final currentUser = currentUserEmail;
          final messageID = message.documentID;

          readMessages(messageReceiver, isRead, messageID);

          final messageWidget = MessageBubble(
            text: messageText,
            sender: messageSender,
            type: messageType,
            imageUrl: messageImage,
            time: messageTime,
            isCurrent: currentUser == messageSender,
            isRead: isRead,
            chatID: widget.chatID,
            messageID: messageID,
            globalContext: widget.globalContext,
          );
          messageWidgets.add(messageWidget);
        }

        return Expanded(
          child: messageWidgets.length == 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.chat,
                      size: 80,
                      color: Colors.black38,
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                    Text(
                      translate('chat.no_messages'),
                      style: Theme.of(context).textTheme.headline6.copyWith(
                            color: Colors.black38,
                          ),
                    ),
                  ],
                )
              : ListView(
                  shrinkWrap: true,
                  reverse: true,
                  children: messageWidgets,
                ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({
    this.sender,
    this.text,
    this.isCurrent,
    this.time,
    this.isRead,
    this.messageID,
    this.chatID,
    this.globalContext,
    this.imageUrl,
    this.type,
  });

  final String text;
  final String messageID;
  final String chatID;
  final String sender;
  final String type;
  final String imageUrl;
  final bool isCurrent;
  final String time;
  final bool isRead;
  final BuildContext globalContext;

  void _deleteSelectedMessage(context) {
    _firestore
        .collection('chats')
        .document(chatID)
        .collection('messages')
        .document(messageID)
        .delete()
        .then((value) {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).primaryColor,
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                translate('notification_snack_bar.success_deleted_message')),
          ),
        ),
      );
    });
  }

  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).errorColor,
                ),
                title: Text(
                  translate('chat.delete_this_message'),
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2
                      .copyWith(color: Theme.of(context).errorColor),
                ),
                onTap: () {
                  _deleteSelectedMessage(bc);
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        });
  }

  Future<void> _showImageDialog(imageUrl) async {
    return showDialog<void>(
      context: globalContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          content: SizedBox.expand(
            child: Container(
              child: CachedNetworkImage(
                placeholder: (context, url) => Container(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black38),
                  ),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  padding: EdgeInsets.all(70.0),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Material(
                  child: Text('image is not avialble'),
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
                imageUrl: imageUrl,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(
                translate(
                  "show_dialog.close",
                ),
                style: Theme.of(context)
                    .textTheme
                    .headline6
                    .copyWith(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _settingModalBottomSheet(globalContext);
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 8.0,
          bottom: 8.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isCurrent ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: <Widget>[
            Flexible(
              child: Material(
                borderRadius: BorderRadius.only(
                  bottomLeft:
                      isCurrent ? Radius.circular(4.0) : Radius.circular(0.0),
                  topLeft: Radius.circular(4.0),
                  topRight: Radius.circular(4.0),
                  bottomRight:
                      isCurrent ? Radius.circular(0.0) : Radius.circular(4.0),
                ),
                elevation: 2.0,
                color: isCurrent
                    ? type == 'image' && imageUrl != null
                        ? Color(0xffF3F3F3) // TODO put this color to theming
                        : Theme.of(context).primaryColor
                    : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    type == 'image' && imageUrl != null
                        ? Container(
                            child: FlatButton(
                              onPressed: () async {
                                await _showImageDialog(imageUrl);
                              },
                              child: Material(
                                child: CachedNetworkImage(
                                  placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black38),
                                    ),
                                    width: 200.0,
                                    height: 200.0,
                                    padding: EdgeInsets.all(70.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Material(
                                    child: Text('image is not avialble'),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8.0),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                  ),
                                  imageUrl: imageUrl,
                                  width: 200.0,
                                  fit: BoxFit.fitWidth,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4.0),
                                  topRight: Radius.circular(4.0),
                                ),
                                clipBehavior: Clip.hardEdge,
                              ),
                              padding: EdgeInsets.all(0),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(
                              top: 16.0,
                              left: 16.0,
                              right: 16.0,
                            ),
                            child: Text(
                              '$text',
                              softWrap: true,
                              maxLines: null,
                              style: TextStyle(
                                fontSize: 14,
                                color: isCurrent ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 16.0, left: 16.0, right: 16.0, bottom: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: Stack(
                              children: <Widget>[
                                Icon(
                                  Icons.check,
                                  size: 12,
                                  color: isCurrent
                                      ? type == 'image' && imageUrl != null
                                          ? Colors.black87
                                          : Colors.white
                                      : Colors.black,
                                ),
                                isRead
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(left: 4.0),
                                        child: Icon(
                                          Icons.check,
                                          size: 12,
                                          color: isCurrent
                                              ? type == 'image' &&
                                                      imageUrl != null
                                                  ? Colors.black87
                                                  : Colors.white
                                              : Colors.black,
                                        ),
                                      )
                                    : SizedBox(),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 8.0,
                          ),
                          Text(
                            time != null ? time : translate('time.no_time'),
                            style: TextStyle(
                              fontSize: 10.0,
                              color: isCurrent
                                  ? type == 'image' && imageUrl != null
                                      ? Colors.black87
                                      : Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    )
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
