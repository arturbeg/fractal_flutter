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

class ChatScreenArguments {
  final chatDocument;
  ChatScreenArguments(this.chatDocument);
}

class ChatItem extends StatelessWidget {
  final ChatModel chatDocument;

  ChatItem({this.chatDocument});

  String _getShortenedName(
      String name, BuildContext context, bool isChatReported) {
    name = name.replaceAll("\n", " ");
    if (isChatReported == null) {
      return "";
    } else if (isChatReported) {
      return "This chat is reported";
    } else {
      return name;
    }
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
    if (chatDocument.isSubchat) {
      return Column(
        children: <Widget>[
          Text(
            timeago.format(chatDocument.lastMessageTimestamp,
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
            timeago.format(chatDocument.lastMessageTimestamp,
                locale: 'en_short'),
            style: TextStyle(color: Colors.black45),
          ),
          Text(shortenNumber(chatDocument.reddit.reddit_score)),
        ],
      );
    }
  }

  Future<String> _subchatParentMessageRepliesCount() {
    return Firestore.instance
        .collection('messages')
        .document(chatDocument.parentMessageId)
        .get()
        .then((parentMessage) {
      return parentMessage.data['repliesCount'].toString();
    });
  }

  _buildChatItemListTile(ReportedChatIds reportedChatsProvider,
      LastMessages lastMessagesProvider, BuildContext context) {
    final isChatReported =
        reportedChatsProvider.isChatReported(chatDocument.id);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/chat',
            arguments: ChatScreenArguments(chatDocument));
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
                                  _getShortenedName(chatDocument.name,
                                      context, isChatReported),
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
                                          initialData: lastMessagesProvider
                                              .getCachedLastMessage(
                                                  chatDocument.id),
                                          stream: lastMessagesProvider.fetchLastMessageFirebaseStream(chatDocument.id),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<QuerySnapshot>
                                                  snapshot) {
                                            if (snapshot.hasError) {
                                              return new Text(
                                                  'Error: ${snapshot.error}');
                                            }

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

  _buildReportChatAction(BuildContext context, ReportedChatIds reportedChatsProvider) {
    final isChatReported =
        reportedChatsProvider.isChatReported(chatDocument.id);
    return isChatReported == null
        ? null
        : IconSlideAction(
            caption: isChatReported ? 'Unreport' : 'Report',
            color: Colors.red,
            icon: Icons.flag,
            onTap: () {
              reportedChatsProvider.updateReportedChatFirebase(
                  chatDocument.id, isChatReported, context);
            });
  }

  @override
  Widget build(BuildContext context) {
    final reportedChatsProvider = Provider.of<ReportedChatIds>(context);
    final lastMessagesProvider = Provider.of<LastMessages>(context);
    // reportedChatsProvider.isChatReportedFetch(chatDocument.id);
    return new Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: _buildChatItemListTile(
          reportedChatsProvider, lastMessagesProvider, context),
      secondaryActions: <Widget>[_buildReportChatAction(context, reportedChatsProvider)],
    );
  }
}
