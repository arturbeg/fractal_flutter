import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './branchingPage.dart';
import './messageInfoPage.dart';
import '../auth_state.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat/chatscreen.dart';
import '../model/models.dart';

class ChatMessageListItem extends StatelessWidget {
  final DocumentSnapshot messageSnapshot;

  // final Animation animation;
  // ChatMessageListItem({this.animation});
  // String messageText;
  // String senderName;

  ChatMessageListItem({this.messageSnapshot});

  Future<bool> _getMessageHasSubchat(DocumentSnapshot messageSnapshot) async {
    final QuerySnapshot result = await Firestore.instance
        .collection('chats')
        .where('parentMessageId', isEqualTo: messageSnapshot.documentID)
        .getDocuments();

    final List<DocumentSnapshot> documents = result.documents;

    return documents.length > 0 ? true : false;
  }

  _openSubchat(DocumentSnapshot messageSnapshot, context) async {
    final QuerySnapshot result = await Firestore.instance
        .collection('chats')
        .where('parentMessageId', isEqualTo: messageSnapshot.documentID)
        .getDocuments();

    final List<DocumentSnapshot> documents = result.documents;

    final chatDocument = documents[0];

    var document = ChatModel();
    document.setChatModelFromDocumentSnapshot(chatDocument);

    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      var document = ChatModel();
      document.setChatModelFromDocumentSnapshot(chatDocument);
      return new ChatScreen(chatDocument: document);
    }));
  }

  _createSubchat(
      String subchatName, DocumentSnapshot messageSnapshot, context) async {
    final DocumentReference chatDocumentReference =
        await Firestore.instance.collection("chats").add({
      "about": "",
      "avatarURL": "",
      "name": subchatName,
      "owner": {
        'id': AuthState.currentUser.documentID,
        'name': AuthState.currentUser['name'],
        'facebookID': AuthState.currentUser['facebookID']
      },
      "timestamp": FieldValue.serverTimestamp(),
      "parentMessageId": messageSnapshot.documentID,
      "parentChat": {
        'id': messageSnapshot.data['chat']['id'],
        'name': messageSnapshot.data['chat']['name'],
        'avatarURL': messageSnapshot.data['chat']['avatarURL'],
      },
      "isSubchat": true,
      "lastMessageTimestamp": FieldValue.serverTimestamp(),
      "url": "",
      // TODO: add reddit and other attributes
      "reddit": {
        "id": "",
        "author": "",
        "num_comments": 0,
        "over_18": false,
        "subreddit": "",
        "upvote_ratio": 0.0,
        "shortlink": "",
        'reddit_score': 0,
        'rank': 1000
      },
    });

    chatDocumentReference.get().then((chatDocument) {
      //print("Got the newly created subchat");
      var document = ChatModel();
      document.setChatModelFromDocumentSnapshot(chatDocument);

      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
        var document = ChatModel();
        document.setChatModelFromDocumentSnapshot(chatDocument);
        return new ChatScreen(chatDocument: document);
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: only allow branching of text messages
    return new GestureDetector(
      onDoubleTap: () {
        // If message subchat exists --> open it
        // If message subchat does not exist --> create subchat and navigate to it
        if (messageSnapshot['imageURL'] == null) {
          _getMessageHasSubchat(messageSnapshot).then((hasSubchat) {
            if (hasSubchat) {
              _openSubchat(messageSnapshot, context);
            } else {
              final subchatName = messageSnapshot['text'];
              _createSubchat(subchatName, messageSnapshot, context);
            }
          });
        }
      },
      onLongPress: () {
        if (messageSnapshot['imageURL'] == null) {
          _getMessageHasSubchat(messageSnapshot).then((hasSubchat) {
            if (hasSubchat) {
              _openSubchat(messageSnapshot, context);
            } else {
              final subchatName = messageSnapshot['text'];
              _createSubchat(subchatName, messageSnapshot, context);
            }
          });
        }
      },
      // onForcePressStart: () {
      //   _getMessageHasSubchat(messageSnapshot).then((hasSubchat) {
      //     if(hasSubchat) {
      //       _openSubchat(messageSnapshot, context);
      //     } else {
      //       final subchatName = messageSnapshot['text'];
      //       _createSubchat(subchatName, messageSnapshot, context);
      //     }
      //   });
      // },
      child: Row(
          children: messageSnapshot['sender']['id'] ==
                  AuthState.currentUser.documentID
              ? getSentMessageLayout()
              : getReceivedMessageLayout()),
    );

    // return new SizeTransition(
    //   sizeFactor: 1.0// new CurvedAnimation(parent: animation, curve: Curves.decelerate),
    //   child: new Row(
    //     children: getReceivedMessageLayout(),
    //   )
    // );
  }

  List<Widget> getReceivedMessageLayout() {
    String repliesCount = messageSnapshot['repliesCount'].toString();
    String repliesCountLabel = messageSnapshot['repliesCount'] > 1
        ? repliesCount + ' replies'
        : repliesCount + ' reply';
    return <Widget>[
      new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: new CircleAvatar(
                backgroundImage: new NetworkImage(
                    'https://graph.facebook.com/${messageSnapshot['sender']['facebookID']}/picture?height=80'),
                //AssetImage('assets/default-avatar.png'),
              )),
        ],
      ),
      new Expanded(
          child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Text(messageSnapshot['sender']['name'],
              style: new TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold)),
          new Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: messageSnapshot['imageURL'] != null
                  ? new Image.network(
                      messageSnapshot['imageURL'],
                      height: 100.0,
                    )
                  : new Linkify(
                      onOpen: (link) async {
                        if (await canLaunch(link.url)) {
                          await launch(link.url);
                        } else {
                          throw 'Could not launch $link';
                        }
                      },
                      text: messageSnapshot['text'])),
          messageSnapshot['repliesCount'] > 0
              ? new Text(
                  repliesCountLabel,
                  style: TextStyle(color: Colors.grey, fontSize: 10.0),
                )
              : null
        ],
      ))
    ];
  }

  List<Widget> getSentMessageLayout() {
    // String subchatsCount = messageSnapshot['subchatsCount'].toString();
    // String subchatsCountLabel = messageSnapshot['subchatsCount'] > 1
    //     ? subchatsCount + ' subchats'
    //     : subchatsCount + ' subchat';
    String repliesCount = messageSnapshot['repliesCount'].toString();
    String repliesCountLabel = messageSnapshot['repliesCount'] > 1
        ? repliesCount + ' replies'
        : repliesCount + ' reply';
    return <Widget>[
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            new Text(messageSnapshot['sender']['name'],
                style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            new Container(
                margin: const EdgeInsets.only(top: 5.0),
                child: messageSnapshot['imageURL'] != null
                    ? FadeInImage(
                        image: NetworkImage(messageSnapshot['imageURL']),
                        placeholder: AssetImage('assets/placeholder-image.png'),
                        width: 200.0,
                      )
                    : new Linkify(
                        onOpen: (link) async {
                          if (await canLaunch(link.url)) {
                            await launch(link.url);
                          } else {
                            throw 'Could not launch $link';
                          }
                        },
                        text: messageSnapshot['text'],
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                      )),
            messageSnapshot['imageURL'] != null
                ? null
                : messageSnapshot['repliesCount'] > 0
                    ? new Text(
                        repliesCountLabel,
                        style: TextStyle(color: Colors.grey, fontSize: 10.0),
                      )
                    : null
          ].where((c) => c != null).toList(),
        ),
      ),
      new Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          new Container(
              margin: const EdgeInsets.only(left: 8.0),
              child: new CircleAvatar(
                backgroundImage: new NetworkImage(
                    'https://graph.facebook.com/${messageSnapshot['sender']['facebookID']}/picture?height=80'),
                //AssetImage('assets/default-avatar.png'),
              )),
        ],
      ),
    ];
  }
}
