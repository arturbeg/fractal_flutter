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
  final ChatModel chatDocument;
  ChatScreenArguments(this.chatDocument);
}

class ChatItem extends StatefulWidget {
  final ChatModel chatDocument;

  ChatItem({this.chatDocument});

  @override
  _ChatItemState createState() => _ChatItemState(chatDocument: chatDocument);
}

class _ChatItemState extends State<ChatItem> {
  LastMessages lastMessagesProvider;
  ReportedChatIds reportedChatsProvider;
  // TODO: find a better solution to be independent from leave chat
  final ChatModel chatDocument;

  _ChatItemState({this.chatDocument});

  @override
  initState() {
    super.initState();
    // No need for set state in here since no need to rebuild
    reportedChatsProvider =
        Provider.of<ReportedChatIds>(context, listen: false);
    lastMessagesProvider = Provider.of<LastMessages>(context, listen: false);
    lastMessagesProvider.fetchLastMessageForCache(chatDocument.id);
  }

  String _getShortenedName(
      String name, BuildContext context) {
    name = name.replaceAll("\n", " ");
    return name;
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

  _buildFutureBuilder() {
    return FutureBuilder<String>(
      future: chatDocument.isSubchat
          ? _subchatParentMessageRepliesCount()
          : _chatTotalNumberOfMessages(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        // print(snapshot);
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
    );
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
          _buildFutureBuilder()
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
          _buildFutureBuilder()
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

  Future<String> _chatTotalNumberOfMessages() async {
    QuerySnapshot messages = await Firestore.instance
        .collection('messages')
        .where('chatId', isEqualTo: chatDocument.id)
        .getDocuments();
    return messages.documents.length.toString();
  }

  _buildChatItemListTile(ReportedChatIds reportedChatsProvider,
      LastMessages lastMessagesProvider, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, new MaterialPageRoute(builder: (context) {
          return new ChatScreen(chatDocument: chatDocument);
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
                                  _getShortenedName(chatDocument.name, context),
                                  style: new TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16.0),
                                )),
                            _buildChatItemMiniInfo(),
                          ],
                        ),
                        Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: new Container(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: StreamBuilder<QuerySnapshot>(
                                  initialData: lastMessagesProvider
                                      .getCachedLastMessage(chatDocument.id),
                                  stream: lastMessagesProvider
                                      .fetchLastMessageFirebaseStream(
                                          chatDocument.id),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<QuerySnapshot> snapshot) {
                                    if (snapshot.hasError) {
                                      return new Text(
                                          'Error: ${snapshot.error}');
                                    }

                                    if (snapshot.data != null) {
                                      if (snapshot.data.documents.length > 0) {
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
                                              .data.documents[0].data['text']
                                              .toString();
                                          return Text(
                                            _lastMessageShortener(lastMessage),
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

  _buildReportChatAction(
      BuildContext context, ReportedChatIds reportedChatsProvider) {
    return IconSlideAction(
        caption: 'Report',
        color: Colors.red,
        icon: Icons.flag,
        onTap: () {
          reportedChatsProvider.updateReportedChatFirebase(
              chatDocument.id, context);
        });
  }

  @override
  Widget build(BuildContext context) {
    return new Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: _buildChatItemListTile(
          reportedChatsProvider, lastMessagesProvider, context),
      secondaryActions: <Widget>[
        _buildReportChatAction(context, reportedChatsProvider)
      ],
    );
  }
}
