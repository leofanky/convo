import 'package:intl/intl.dart';

Future<String> getUserPhotoUrl(_firestore, String user) async {
  return await _firestore.collection('users').document(user).get().then((ds) {
    return ds.data['photoUrl'];
  });
}

Future<bool> getUserOnlineStatus(_firestore, String user) async {
  return await _firestore.collection('users').document(user).get().then((ds) {
    return ds.data['onlineStatus'];
  });
}

deleteChat(_firestore, String chatID) async {
  return await _firestore.collection('chats').document(chatID).delete();
}

String readTimestamp(int timestamp) {
  if (timestamp != null) {
    var now = DateTime.now();
    var format = DateFormat('HH:mm a');
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var diff = date.difference(now) * -1;
    String time;

    if (diff.inSeconds <= 0 ||
        diff.inSeconds > 0 && diff.inMinutes == 0 ||
        diff.inMinutes > 0 && diff.inHours == 0 ||
        diff.inHours > 0 && diff.inDays == 0) {
      time = format.format(date);
    } else {
      if (diff.inDays == 1) {
        time = diff.inDays.toString() + ' DAY AGO';
      } else {
        time = diff.inDays.toString() + ' DAYS AGO';
      }
    }

    return time;
  }
  return null;
}
