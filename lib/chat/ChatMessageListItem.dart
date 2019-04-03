import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './branchingPage.dart';
import './messageInfoPage.dart';
import '../auth_state.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

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
      onDoubleTap: () {
        // Navigate to Branching page
        Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
          return new BranchingPage(
            messageSnapshot: messageSnapshot,
          );
        }));
      },
      onLongPress: () {
        Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
          return new BranchingPage(
            messageSnapshot: messageSnapshot,
          );
        }));
      },
      onPanUpdate: (details) {
        if (details.delta.dx < 0) {
          print("Dragging in +X direction");
          Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
            return new MessageInfoPage(
              messageSnapshot: messageSnapshot,
            );
          }));
        }
      },
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
                      text: messageSnapshot['text']))
        ],
      ))
    ];
  }

  List<Widget> getSentMessageLayout() {
    String subchatsCount = messageSnapshot['subchatsCount'].toString();
    String subchatsCountLabel = messageSnapshot['subchatsCount'] > 1
        ? subchatsCount + ' subchats'
        : subchatsCount + ' subchat';
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
                        width: 150.0,
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
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black
                        ),)),
            messageSnapshot['subchatsCount'] != 0
                ? new Text(
                    subchatsCountLabel,
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
