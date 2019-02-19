import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './branchingPage.dart';
import './messageInfoPage.dart';
import '../auth_state.dart';

class ChatMessageListItem extends StatelessWidget {
  final DocumentSnapshot messageSnapshot;

  // final Animation animation;
  // ChatMessageListItem({this.animation});
  // String messageText;
  // String senderName;

  ChatMessageListItem({this.messageSnapshot});

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () {
        // Navigate to Branching page
        Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
          return new BranchingPage(
            messageSnapshot: messageSnapshot,
          );
        }));
      },
      onHorizontalDragEnd: (event) {
        Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
          return new MessageInfoPage(
            messageSnapshot: messageSnapshot,
          );
        }));
      },
      child: Row(
        children: messageSnapshot['sender']['id'] == AuthState.currentUser.documentID ?    
        getSentMessageLayout() : getReceivedMessageLayout()
      ),
    );

    // return new SizeTransition(
    //   sizeFactor: 1.0// new CurvedAnimation(parent: animation, curve: Curves.decelerate),
    //   child: new Row(
    //     children: getReceivedMessageLayout(),
    //   )
    // );
  }

  List<Widget> getReceivedMessageLayout() {
    return <Widget>[
      new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: new CircleAvatar(
                backgroundImage:
                    new NetworkImage(messageSnapshot['sender']['avatarURL']),
              )),
        ],
      ),
      new Expanded(
          child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Text("Artur Begyan",
              style: new TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold)),
          new Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: messageSnapshot['imageURL'] != null
                  ? new Image.network(
                      messageSnapshot['imageURL'],
                      width: 250.0,
                    )
                  : new Text(messageSnapshot['text']))
        ],
      ))
    ];
  }

  List<Widget> getSentMessageLayout() {
    String subchatsCount = messageSnapshot['subchatsCount'].toString();
    String subchatsCountLabel = messageSnapshot['subchatsCount'] > 1 ? subchatsCount + ' subchats' : subchatsCount + ' subchat';
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
                    ? new Image.network(
                        messageSnapshot['imageURL'],
                        width: 250.0,
                      )
                    : new Text(messageSnapshot['text'])),
          messageSnapshot['subchatsCount'] != 0 ?
          new Text(subchatsCountLabel, style: TextStyle(
            color: Colors.grey, fontSize: 10.0
          ),) : null
          ].where(
            (c) => c != null
          ).toList(),
          
        ),
      ),
      new Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          new Container(
              margin: const EdgeInsets.only(left: 8.0),
              child: new CircleAvatar(
                backgroundImage:
                    new NetworkImage(messageSnapshot['sender']['avatarURL']),
              )),
        ],
      ),
    ];
  }
}
