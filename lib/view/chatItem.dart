import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../chat/chatscreen.dart';
import '../auth_state.dart';
import 'dart:core';
import '../model/models.dart';
import '../chat/messageInfoPage.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../pages/chats.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../auth_state.dart';
import '../login.dart';

class ChatItem extends StatefulWidget {
  final ChatModel chatDocument;

  ChatItem({this.chatDocument});

  @override
  _ChatItemState createState() => _ChatItemState();
}

class _ChatItemState extends State<ChatItem> {
  final bool isSubchat = false;
  bool isChatReported;

  GlobalKey key = new GlobalKey();

  DocumentSnapshot parentMessageSnapshot;

  final SnackBar snackBar = SnackBar(
    content: Text("Message was successfully linked!"),
  );

  _getShortenedName(String name) {
    if (isChatReported == null) {
      return "";
    } else if (isChatReported) {
      return "This chat is reported";
    } else {
      return name;
    }
  }

  @override
  void initState() {
    super.initState();
    if (AuthState.currentUser != null) {
      final chatId = widget.chatDocument.id;
      Firestore.instance
          .collection('users')
          .document(AuthState.currentUser.documentID)
          .get()
          .then((userDocument) {
        if (userDocument.data.containsKey('reportedChats')) {
          final List reportedChats = userDocument.data['reportedChats'];
          if (mounted) {
            setState(() {
              isChatReported = reportedChats.contains(chatId);
            });
          }
        } else {
          if (mounted) {
            setState(() {
              isChatReported = false;
            });
          }
        }
      });
    } else {
      if (mounted) {
        setState(() {
          isChatReported = false;
        });
      }
    }
  }

  String shortenNumber(int value) {
    const units = <int, String>{
      1000000000: 'B',
      1000000: 'M',
      1000: 'K',
    };
    return units.entries
        .map((e) => '${value ~/ e.key}${e.value}')
        .firstWhere((e) => !e.startsWith('0'), orElse: () => '$value');
  }

  _buildChatItemListTile(context) {
    return ListTile(
      leading: widget.chatDocument.isSubchat
          ? null
          : new Container(
              child: Column(
              children: <Widget>[
                Text(shortenNumber(widget.chatDocument.reddit.reddit_score)),
                Text(
                  timeago.format(widget.chatDocument.lastMessageTimestamp,
                      locale: 'en_short'),
                  style: new TextStyle(color: Colors.grey, fontSize: 14.0),
                  textAlign: TextAlign.left,
                ),
              ],
            )),
      title: new Column(
        children: <Widget>[
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Flexible(
                child: new Text(
                  _getShortenedName(widget.chatDocument.name),
                  style: new TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
      subtitle: isChatReported == null
          ? Text("No messages yet")
          : isChatReported
              ? Text("Swipe left to unreport")
              : new Container(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: Firestore.instance
                        .collection('messages')
                        .where('chatId', isEqualTo: widget.chatDocument.id)
                        .orderBy("timestamp", descending: true)
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return new Text('Error: ${snapshot.error}');
                      }
                      if (snapshot.data != null) {
                        if (snapshot.data.documents.length > 0) {
                          if (snapshot.data.documents[0].data['text'] == null) {
                            String lastMessage = 'photo';
                            return Row(children: <Widget>[
                              new Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 15.0,
                              ),
                              Text(lastMessage,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 15.0))
                            ]);
                          } else {
                            String lastMessage = snapshot
                                .data.documents[0].data['text']
                                .toString();
                            return Text(lastMessage,
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 15.0));
                          }
                        } else {
                          return Text("No messages yet");
                        }
                      } else {
                        return Text("No messages yet");
                      }
                    },
                  )),
      onTap: () {
        Navigator.push(context, new MaterialPageRoute(builder: (context) {
          return new ChatScreen(chatDocument: widget.chatDocument);
        }));
      },
    );
  }

  _buildReportChatAction() {
    return isChatReported == null
        ? null
        : IconSlideAction(
            caption: isChatReported ? 'Unreport' : 'Report',
            color: Colors.red,
            icon: Icons.flag,
            onTap: () {
              if (AuthState.currentUser != null) {
                Firestore.instance.runTransaction((transaction) async {
                  var documentReference = Firestore.instance
                      .collection('users')
                      .document(AuthState.currentUser.documentID);

                  var data;

                  if (isChatReported) {
                    data = {
                      'reportedChats':
                          FieldValue.arrayRemove([widget.chatDocument.id])
                    };
                  } else {
                    data = {
                      'reportedChats':
                          FieldValue.arrayUnion([widget.chatDocument.id])
                    };
                  }

                  await transaction.update(documentReference, data);

                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: isChatReported
                        ? Text("Report removed!")
                        : Text("Chat reported"),
                  ));

                  if (mounted) {
                    setState(() {
                      isChatReported = !isChatReported;
                    });
                  }
                });
              } else {
                Navigator.of(context)
                    .push(new MaterialPageRoute(builder: (context) {
                  return new LoginPage(redirectBack: true);
                }));
              }
            });
  }

  @override
  Widget build(BuildContext context) {
    return new Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: _buildChatItemListTile(context),
      secondaryActions: <Widget>[_buildReportChatAction()],
    );
  }
}
