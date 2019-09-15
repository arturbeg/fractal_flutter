import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fractal/last_message.dart';
import 'package:fractal/reported_chats_provider.dart';
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
import 'package:provider/provider.dart';

class ChatItem extends StatefulWidget {
  final ChatModel chatDocument;

  ChatItem({this.chatDocument});

  @override
  _ChatItemState createState() => _ChatItemState();
}

class _ChatItemState extends State<ChatItem> {

  final bool isSubchat = false;

  GlobalKey key = new GlobalKey();

  DocumentSnapshot parentMessageSnapshot;

  final SnackBar snackBar = SnackBar(
    content: Text("Message was successfully linked!"),
  );

  String _getShortenedName(String name, BuildContext context) {
    name = name.replaceAll("\n", " ");
    // if (isChatReported == null) {
    //   return "";
    // } else if (isChatReported) {
    //   return "This chat is reported";
    // } else {
    //   return name;
    // } 
    return "This is the chat name";
  }

  _lastMessageShortener(text) {
    text = text.replaceAll("\n", " ");
    if (text.length > 35) {
      return text.substring(0, 35) + '...';
    } else {
      return text;
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

  _buildChatItemMiniInfo() {
    if (widget.chatDocument.isSubchat) {
      return Column(
        children: <Widget>[
          Text(
            timeago.format(widget.chatDocument.lastMessageTimestamp,
                locale: 'en_short'),
            style: TextStyle(color: Colors.black45),
          ),
          FutureBuilder<String>(
            future: _subchatParentMessageRepliesCount(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              print(snapshot);
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return Text('');
                case ConnectionState.active:
                case ConnectionState.waiting:
                  return Text('');
                case ConnectionState.done:
                  if (snapshot.hasError) return Text('');
                  return Text(snapshot.data);
              }
              return null; // unreachable
            },
          )
        ],
      );
    } else {
      return Column(
        children: <Widget>[
          Text(
            timeago.format(widget.chatDocument.lastMessageTimestamp,
                locale: 'en_short'),
            style: TextStyle(color: Colors.black45),
          ),
          Text(shortenNumber(widget.chatDocument.reddit.reddit_score)),
        ],
      );
    }
  }

  Future<String> _subchatParentMessageRepliesCount() {
    return Firestore.instance
        .collection('messages')
        .document(widget.chatDocument.parentMessageId)
        .get()
        .then((parentMessage) {
      return parentMessage.data['repliesCount'].toString();
    });
  }

  _buildChatItemListTile(ReportedChatIds reportedChatsProvider, LastMessages lastMessagesProvider,  BuildContext context) {
    final isChatReported = reportedChatsProvider.isChatReported(widget.chatDocument.id);
    return GestureDetector(
      onTap: () {
        Navigator.push(context, new MaterialPageRoute(builder: (context) {
          return new ChatScreen(chatDocument: widget.chatDocument);
        }));
      },
      // TODO: Turn into a stateless widget?
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.7),
                                child: new Text(
                                  _getShortenedName(widget.chatDocument.name, context),
                                  style: new TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16.0),
                                )),
                            _buildChatItemMiniInfo(),
                          ],
                        ),
                        Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: isChatReported == null
                                ? Text(
                                    // TODO: change later
                                    "RRRRRRR",
                                    style: TextStyle(
                                        color: Colors.black45, fontSize: 16),
                                  )
                                : isChatReported
                                    ? Text(
                                        "Swipe left to unreport",
                                        style: TextStyle(
                                            color: Colors.black45,
                                            fontSize: 16),
                                      )
                                    : new Container(
                                        padding:
                                            const EdgeInsets.only(top: 5.0),
                                        child: StreamBuilder<QuerySnapshot>(
                                          initialData: lastMessagesProvider.getCachedLastMessage(widget.chatDocument.id),
                                          stream: Firestore.instance
                                              .collection('messages')
                                              .where('chatId',
                                                  isEqualTo:
                                                      widget.chatDocument.id)
                                              .orderBy("timestamp",
                                                  descending: true)
                                              .limit(1)
                                              .snapshots(),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<QuerySnapshot>
                                                  snapshot) {
                                            if (snapshot.hasError) {
                                              return new Text(
                                                  'Error: ${snapshot.error}');
                                            }
                                            // update the cached lastMessages
                                            lastMessagesProvider.updateCachedLastMessages(widget.chatDocument.id, snapshot.data);

                                            if (snapshot.data != null) {
                                              if (snapshot
                                                      .data.documents.length >
                                                  0) {
                                                if (snapshot.data.documents[0]
                                                        .data['text'] ==
                                                    null) {
                                                  String lastMessage = 'photo';
                                                  return Row(children: <Widget>[
                                                    new Icon(
                                                      Icons.camera_alt,
                                                      color: Colors.grey,
                                                      size: 15.0,
                                                    ),
                                                    Text(
                                                      _lastMessageShortener(
                                                          lastMessage),
                                                      style: TextStyle(
                                                          color: Colors.black45,
                                                          fontSize: 16),
                                                    )
                                                  ]);
                                                } else {
                                                  // Shorten the message in here
                                                  String lastMessage = snapshot
                                                      .data
                                                      .documents[0]
                                                      .data['text']
                                                      .toString();
                                                  return Text(
                                                    _lastMessageShortener(
                                                        lastMessage),
                                                    style: TextStyle(
                                                        color: Colors.black45,
                                                        fontSize: 16),
                                                  );
                                                }
                                              } else {
                                                return Text(
                                                  "No messages yet",
                                                  style: TextStyle(
                                                      color: Colors.black45,
                                                      fontSize: 16),
                                                );
                                              }
                                            } else {
                                              return Text(
                                                "No messages yet",
                                                style: TextStyle(
                                                    color: Colors.black45,
                                                    fontSize: 16),
                                              );
                                            }
                                          },
                                        )))
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          // TODO: introduce one more row before the divider for extra stuff like reddit score and the URL like in the hackernews app
          Divider(),
        ],
      ),
    );
  }

  _buildReportChatAction(ReportedChatIds reportedChatsProvider) {
    final isChatReported = reportedChatsProvider.isChatReported(widget.chatDocument.id);
    return isChatReported == null
        ? null
        : IconSlideAction(
            caption: isChatReported ? 'Unreport' : 'Report',
            color: Colors.red,
            icon: Icons.flag,
            onTap: () {
              reportedChatsProvider.updateReportedChatFirebase(widget.chatDocument.id, isChatReported, context);
            });
  }
  
  @override
  Widget build(BuildContext context) {
    final reportedChatsProvider = Provider.of<ReportedChatIds>(context);
    final lastMessagesProvider = Provider.of<LastMessages>(context);
    // reportedChatsProvider.isChatReportedFetch(widget.chatDocument.id);
    return new Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: _buildChatItemListTile(reportedChatsProvider, lastMessagesProvider, context),
      secondaryActions: <Widget>[_buildReportChatAction(reportedChatsProvider)],
    );
  }
}
