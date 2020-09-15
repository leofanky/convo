import 'dart:async';

import 'package:convo/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convo/services/chat_arguments.dart';
import 'package:convo/services/helpers.dart';
import 'package:async/async.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

final _firestore = Firestore.instance;
String currentUserEmail;

class ChatsScreen extends StatefulWidget {
  static const String id = 'chats_screen';
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String _email;
  Stream<QuerySnapshot> _streamChats =
      _firestore.collection('chats').snapshots();
  Stream<QuerySnapshot> _streamChats1;
  Stream<QuerySnapshot> _streamChats2;
  Stream<List<QuerySnapshot>> bothStreams;

  void getLocalData() async {
    final SharedPreferences prefs = await _prefs;
    _email = prefs.getString('email');
    setState(() {
      currentUserEmail = _email;
    });
    print('shared prefs chats screen $currentUserEmail');
  }

  @override
  void initState() {
    super.initState();
    getLocalData();
    bothStreams = StreamZip([_streamChats]);
  }

  _filterChats(String searchQuery) {
    List<String> _filteredList = [];

    _firestore.collection('chats').snapshots().listen(
          (data) => data.documents.forEach(
            (doc) {
              if (currentUserEmail == doc['user1']) {
                if (doc['user2'].contains(searchQuery.toLowerCase())) {
                  _filteredList.add(doc['user2']);
                }
              } else if (currentUserEmail == doc['user2']) {
                if (doc['user1'].contains(searchQuery.toLowerCase())) {
                  _filteredList.add(doc['user1']);
                }
              }
              setState(() {
                print(_filteredList);
                _streamChats1 = _firestore
                    .collection('chats')
                    .where("user1", whereIn: _filteredList)
                    .snapshots();
                _streamChats2 = _firestore
                    .collection('chats')
                    .where("user2", whereIn: _filteredList)
                    .snapshots();
                bothStreams = StreamZip([_streamChats1, _streamChats2])
                    .asBroadcastStream();
              });
            },
          ),
        );
  }

  @override
  Widget build(BuildContext globalContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Material(
          color: Colors.white,
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 32,
              bottom: 8.0,
            ),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Colors.black,
                  ),
                  onPressed: () {},
                ),
                Container(
                  height: 30,
                  child: VerticalDivider(
                    color: Colors.black12,
                  ),
                ),
                Expanded(
                  child: TextField(
                    onChanged: _filterChats,
                    decoration: InputDecoration(
                      hintText: translate('chats.search_chats').toUpperCase(),
                      hintStyle: Theme.of(context).textTheme.overline,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Colors.black,
                  ),
                  onPressed: () {},
                )
              ],
            ),
          ),
        ),
        ChatsStream(
          streamChats: bothStreams,
          globalContext: globalContext,
        ),
      ],
    );
  }
}

class ChatsStream extends StatelessWidget {
  ChatsStream({
    this.streamChats,
    this.globalContext,
    this.prefs,
  });

  final Stream<List<QuerySnapshot>> streamChats;
  final BuildContext globalContext;
  final Future prefs;
  final List<int> countAllUnreadList = [];

  void countAllUnreadMessages(int value, prefs) async {
    countAllUnreadList.add(value);
    countAllUnreadList.length;
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
    return StreamBuilder(
      stream: streamChats,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Expanded(
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          );
        }

        List<DocumentSnapshot> commonList = [];

        snapshot.data[0].documents.forEach((element) {
          commonList.add(element);
        });

        if (snapshot.data.length > 1) {
          snapshot.data[1].documents.forEach((element2) {
            commonList.add(element2);
          });
        }

        final chats = commonList;
        List<StreamBuilder<dynamic>> chatWidgets = [];
        for (var chat in chats.reversed) {
          final userFirst = chat.data['user1'];
          final userSecond = chat.data['user2'];
          final lastMessageText = chat.data['lastMessageText'];
          final lastMessageTime = readTimestamp(chat.data['lastMessageTime']);
          final chatID = chat.documentID;

          if (currentUserEmail == userFirst || currentUserEmail == userSecond) {
            final chatWidget = StreamBuilder(
              stream: chat.reference.collection('messages').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: SizedBox(),
                  );
                }
                final messages = snapshot.data.documents;
                List<int> countUnread = [];
                for (var message in messages) {
                  if (message.data['read'] == false &&
                      decryptMessage(message.data['receiver']) ==
                          currentUserEmail) {
                    countUnread.add(1);
                    countAllUnreadMessages(1, prefs);
                  }
                }

                return ChatTile(
                  receiverEmail:
                      currentUserEmail == userFirst ? userSecond : userFirst,
                  lastMessageText: lastMessageText,
                  lastMessageTime: lastMessageTime,
                  unreadCount: countUnread.length,
                  chatID: chatID,
                  globalContext: globalContext,
                );
              },
            );
            chatWidgets.add(chatWidget);
          }
        }

        return chatWidgets.length != 0
            ? Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        top: 16.0,
                      ),
                      child: Text(
                        translate('chats.latest').toUpperCase(),
                        style: Theme.of(context).textTheme.overline,
                      ),
                    ),
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: ListView(
                          shrinkWrap: true,
                          physics: ScrollPhysics(),
                          children: chatWidgets,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Expanded(
                child: Column(
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
                ),
              );
      },
    );
  }
}

class ChatTile extends StatelessWidget {
  ChatTile({
    this.lastMessageText,
    this.receiverEmail,
    this.lastMessageTime,
    this.onPress,
    this.unreadCount,
    this.chatID,
    this.globalContext,
  });

  final String chatID;
  final String lastMessageText;
  final String receiverEmail;
  final String lastMessageTime;
  final Function onPress;
  final int unreadCount;
  final BuildContext globalContext;

  void _deleteSelectedChat(context) {
    _firestore
        .collection('chats')
        .document(chatID)
        .collection('messages')
        .snapshots()
        .forEach((element) {
      element.documents.forEach((child) {
        _firestore
            .collection('chats')
            .document(chatID)
            .collection('messages')
            .document(child.documentID)
            .delete();
      });
    }).then((value) {
      _firestore.collection('chats').document(chatID).delete().then((value) {
        Scaffold.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).primaryColor,
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                translate('notification_snack_bar.success_deleted_chat'),
              ),
            ),
          ),
        );
      });
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
                translate('chats.delete_this_chat'),
                style: Theme.of(context)
                    .textTheme
                    .subtitle2
                    .copyWith(color: Theme.of(context).errorColor),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _deleteSelectedChat(context);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (lastMessageText != null) {
      return StreamBuilder(
          stream: _firestore
              .collection('users')
              .document(receiverEmail)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox();
            }
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                Navigator.pushNamed(
                  context,
                  ChatScreen.id,
                  arguments: ScreenArguments(
                    chatID: chatID,
                    receiverName: snapshot.data['name'],
                    receiverEmail: receiverEmail,
                  ),
                );
              },
              onLongPress: () {
                _settingModalBottomSheet(globalContext);
              },
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, top: 16.0, bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        snapshot.data['photoUrl'] != ''
                            ? CircleAvatar(
                                radius: 20,
                                backgroundColor: Theme.of(context).primaryColor,
                                backgroundImage:
                                    NetworkImage(snapshot.data['photoUrl']),
                              )
                            : CircleAvatar(
                                radius: 20,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                    snapshot.data['name'][0].toUpperCase()),
                              ),
                        SizedBox(
                          width: 16.0,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                snapshot.data['name'],
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              Text(
                                lastMessageText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyText1,
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 16.0,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              lastMessageTime.toUpperCase(),
                              style: Theme.of(context).textTheme.overline,
                            ),
                            unreadCount == 0
                                ? SizedBox()
                                : Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Material(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6.0,
                                          vertical: 3.0,
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .caption,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.black12,
                  ),
                ],
              ),
            );
          });
    } else {
      return SizedBox();
    }
  }
}
