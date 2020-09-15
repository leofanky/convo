const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();


exports.myFunction = functions.firestore.document('/chats/{chatsID}/messages/{msgID}')
  .onWrite((change, context) => { 
      var changed = change.after.data();
      var chatsid = context.params.chatsID;
      var msgid = context.params.msgID;

      if (changed['read']) {
        const CUT_OFF_TIME = 30  * 1000;
        const FieldValue = admin.firestore.FieldValue;
      
        setTimeout(() => {
          db.collection('chats').doc(chatsid).collection('messages').doc(msgid).delete()
        }, CUT_OFF_TIME);
      }
  });

