import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:convo/services/chat_arguments.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContactsStream();
  }
}

class ContactsStream extends StatefulWidget {
  @override
  _ContactsStreamState createState() => _ContactsStreamState();
}

class _ContactsStreamState extends State<ContactsStream> {
  Stream<QuerySnapshot> _streamContacts =
      _firestore.collection('users').snapshots();

  Future<dynamic> isChatExist(loggedUser, receiverUser) async {
    dynamic isExist;
    QuerySnapshot chatQuerySnapshot =
        await Firestore.instance.collection("chats").getDocuments();
    for (int i = 0; i < chatQuerySnapshot.documents.length; i++) {
      var chat = chatQuerySnapshot.documents[i];
      var user1 = chat.data['user1'];
      var user2 = chat.data['user2'];

      if ((loggedUser == user1 && receiverUser == user2) ||
          loggedUser == user2 && receiverUser == user1) {
        isExist = chat.documentID;
        break;
      } else {
        isExist = null;
      }
    }
    return isExist;
  }

  createUserChat(receiver) async {
    dynamic existChatID = await isChatExist(loggedInUser.email, receiver);
    if (existChatID != null) {
      print('chat already exist');
      return existChatID;
    } else {
      DocumentReference docRef = await _firestore.collection('chats').add({
        'user1': loggedInUser.email,
        'user2': receiver,
      });
      return docRef.documentID;
    }
  }

  _filterContacts(String searchQuery) {
    List<String> _filteredList = [];
    _firestore.collection('users').snapshots().listen(
          (data) => data.documents.forEach(
            (doc) {
              if (doc.data['name']
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()) ||
                  doc.data['email']
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase())) {
                _filteredList.add(doc['email']);
              }

              setState(() {
                _streamContacts = _firestore
                    .collection('users')
                    .where("email", whereIn: _filteredList)
                    .snapshots();
              });
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    Icons.add,
                    color: Theme.of(context).primaryColor,
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
                    onChanged: _filterContacts,
                    decoration: InputDecoration(
                      hintText:
                          translate('contacts.search_contacts').toUpperCase(),
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
              ],
            ),
          ),
        ),
        StreamBuilder(
          stream: _streamContacts,
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

            final contacts = snapshot.data.documents;
            List<ContactTile> contactsWidgets = [];

            for (var contact in contacts) {
              final userEmail = contact.documentID;
              final userName = contact.data['name'];
              final userPhotoUrl = contact.data['photoUrl'];
              final userOnlineStatus = contact.data['onlineStatus'];
              final showSearchContact = contact.data['showSearchContact'];
              final contactWidget = ContactTile(
                avatar: userPhotoUrl,
                name: userName,
                showContact: showSearchContact,
                lastSeen: userOnlineStatus == true
                    ? Text(
                        'online',
                        style: Theme.of(context).primaryTextTheme.subtitle2,
                      )
                    : Text(
                        'offline',
                        style: Theme.of(context)
                            .textTheme
                            .subtitle2
                            .copyWith(color: Colors.black38),
                      ),
                onPressed: () async {
                  Navigator.pushNamed(
                    context,
                    ChatScreen.id,
                    arguments: ScreenArguments(
                      chatID: await createUserChat(userEmail),
                      receiverEmail: userEmail,
                      receiverName: userName,
                    ),
                  );
                },
              );

              if (loggedInUser.email != userEmail) {
                contactsWidgets.add(contactWidget);
              }
            }

            return contactsWidgets.length != 0
                ? Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: ListView(
                        physics: ScrollPhysics(),
                        shrinkWrap: true,
                        children: contactsWidgets,
                      ),
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
        ),
      ],
    );
  }
}

class ContactTile extends StatelessWidget {
  ContactTile({
    this.avatar,
    this.lastSeen,
    this.name,
    this.onPressed,
    this.showContact,
  });

  final String avatar;
  final bool showContact;
  final String name;
  final Widget lastSeen;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        height: 72,
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: avatar != ''
                  ? CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor,
                      backgroundImage: NetworkImage(avatar),
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(name[0].toUpperCase()),
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      SizedBox(
                        height: 4.0,
                      ),
                      lastSeen,
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
