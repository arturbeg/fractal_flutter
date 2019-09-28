import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fractal/providers/blocked_user_provider.dart';
import '../auth_state.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat/chatscreen.dart';
import '../model/models.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../login.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

// TODO: refactor to make more DRY
class ChatMessageListItem extends StatefulWidget {
  final DocumentSnapshot messageSnapshot;
  final bool isPreviousMessageByTheSameSender;

  ChatMessageListItem(
      {this.messageSnapshot, this.isPreviousMessageByTheSameSender});

  @override
  _ChatMessageListItemState createState() => _ChatMessageListItemState();
}

class _ChatMessageListItemState extends State<ChatMessageListItem> {
  bool isAnonymous;

  @override
  initState() {
    super.initState();
    // TODO: find a better place to do kickstart such as this one
    BlockedUserManager temporaryProvider = Provider.of<BlockedUserManager>(context, listen: false);
    temporaryProvider.kickstartBlockedUserIds();
  }

  Future<bool> _getMessageHasSubchat(DocumentSnapshot messageSnapshot) async {
    final QuerySnapshot result = await Firestore.instance
        .collection('chats')
        .where('parentMessageId', isEqualTo: messageSnapshot.documentID)
        .getDocuments();

    final List<DocumentSnapshot> documents = result.documents;

    return documents.length > 0 ? true : false;
  }

  _openSubchat(DocumentSnapshot messageSnapshot, context) async {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("Opening the subchat"),
      duration: Duration(seconds: 1),
    ));

    final QuerySnapshot result = await Firestore.instance
        .collection('chats')
        .where('parentMessageId', isEqualTo: messageSnapshot.documentID)
        .getDocuments();

    final List<DocumentSnapshot> documents = result.documents;

    final chatDocument = documents[0];

    var document = ChatModel();
    document.setChatModelFromDocumentSnapshot(chatDocument);

    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return new ChatScreen(chatDocument: document);
    }));
  }

  _buildMessage(BuildContext context, BlockedUserManager blockedUserProvider) {
    return GestureDetector(
      child: Row(
          children: _isSentMessage(widget.messageSnapshot['sender']['id'])
              ? getSentMessageLayout(blockedUserProvider)
              : getReceivedMessageLayout(blockedUserProvider)),
      onDoubleTap: () {
        // TODO: DRY
        if (widget.messageSnapshot['imageURL'] == null) {
          _getMessageHasSubchat(widget.messageSnapshot).then((hasSubchat) {
            if (hasSubchat) {
              _openSubchat(widget.messageSnapshot, context);
            } else {
              if (AuthState.currentUser != null) {
                final subchatName = widget.messageSnapshot['text'];
                _createSubchat(subchatName, widget.messageSnapshot, context);
              } else {
                Navigator.of(context)
                    .push(new MaterialPageRoute(builder: (context) {
                  return new LoginPage(redirectBack: true);
                }));
              }
            }
          });
        }
      },
      onLongPress: () {
        if (AuthState.currentUser != null) {
          if (widget.messageSnapshot['imageURL'] == null) {
            _getMessageHasSubchat(widget.messageSnapshot).then((hasSubchat) {
              if (hasSubchat) {
                _openSubchat(widget.messageSnapshot, context);
              } else {
                if (AuthState.currentUser != null) {
                  final subchatName = widget.messageSnapshot['text'];
                  _createSubchat(subchatName, widget.messageSnapshot, context);
                } else {
                  Navigator.of(context)
                      .push(new MaterialPageRoute(builder: (context) {
                    return new LoginPage(redirectBack: true);
                  }));
                }
              }
            });
          }
        }
      },
    );
  }

  _createSubchat(
      String subchatName, DocumentSnapshot messageSnapshot, context) async {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("Creating a subchat..."),
      duration: Duration(seconds: 1),
    ));

    final DocumentReference chatDocumentReference =
        await Firestore.instance.collection("chats").add({
      "about": "",
      "avatarURL": "",
      "name": subchatName,
      "owner": {
        'id': AuthState.currentUser.documentID,
        'name': AuthState.currentUser['name'],
        'facebookID': AuthState.currentUser['facebookID'],
        'isGoogle': AuthState.currentUser['isGoogle'],
        'googleProfileURL': AuthState.currentUser['googleProfileURL'],
        // TODO: add google stuff to the owner, sender...
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
      var document = ChatModel();
      document.setChatModelFromDocumentSnapshot(chatDocument);

      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
        return new ChatScreen(chatDocument: document);
      }));
    });
  }

  _buildBlockUserAction(BlockedUserManager blockedUserProvider) {
    String senderId = widget.messageSnapshot.data['sender']['id'];
    return IconSlideAction(
        caption: blockedUserProvider.isSenderBlocked(senderId)
            ? 'Unblock user'
            : 'Block user',
        color: Colors.transparent,
        icon: Icons.block,
        foregroundColor: Colors.red,
        onTap: () {
          blockedUserProvider.blockAction(widget.messageSnapshot, context);
        });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: only allow branching of text messages
    // TODO: refactor for slidable to only work for incoming messages
    // TODO: check for blocked or not only performed on incoming messages
    BlockedUserManager blockedUserProvider =
        Provider.of<BlockedUserManager>(context);

    return !_isSentMessage(widget.messageSnapshot['sender']['id']) ? new Slidable(
        actionPane: SlidableDrawerActionPane(),
        actionExtentRatio: 0.25,
        actions: <Widget>[_buildBlockUserAction(blockedUserProvider)],
        secondaryActions: <Widget>[
          IconSlideAction(
              caption: 'Report',
              color: Colors.transparent,
              icon: Icons.flag,
              foregroundColor: Colors.red,
              onTap: () {
                if (AuthState.currentUser != null) {
                  final reference =
                      Firestore.instance.collection('reportedMessages');

                  reference.document().setData({
                    'userID': AuthState.currentUser.documentID,
                    'messageID': widget.messageSnapshot.documentID
                  });

                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text("Message reported!"),
                  ));
                } else {
                  Navigator.of(context)
                      .push(new MaterialPageRoute(builder: (context) {
                    return new LoginPage(redirectBack: true);
                  }));
                }
              }),
        ],
        child: _buildMessage(context, blockedUserProvider)) : _buildMessage(context, blockedUserProvider);
  }

  bool _isSentMessage(senderID) {
    if (AuthState.currentUser != null) {
      return AuthState.currentUser.documentID == senderID;
    } else {
      return false;
    }
  }

  _buildTextMessageContent(BlockedUserManager blockedUserProvider) {
    String senderId = widget.messageSnapshot.data['sender']['id'];
    return new Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        margin: widget.isPreviousMessageByTheSameSender &
                !_isSentMessage(widget.messageSnapshot['sender']['id'])
            ? EdgeInsets.only(
                left:
                    38.0) // 30 + 8 (can turn into a variable, the inset values)
            : EdgeInsets.all(0.0),
        child: blockedUserProvider.isSenderBlocked(senderId)
            ? Text('Sender is blocked')
            : widget.messageSnapshot['imageURL'] != null
                // TODO: add the cached image in here
                // TODO: add placeholder avatar image (find one on google)
                ? CachedNetworkImage(
                    imageUrl: widget.messageSnapshot['imageURL'],
                    imageBuilder: (context, imageProvider) => new ClipRRect(
                        borderRadius: new BorderRadius.circular(8.0),
                        child: FadeInImage(
                          image: imageProvider,
                          placeholder:
                              AssetImage('assets/placeholder-image.png'),
                        )),
                    placeholder: (context, url) {
                      return ClipRRect(
                          borderRadius: new BorderRadius.circular(8.0),
                          child: FadeInImage(
                            image: AssetImage('assets/placeholder-image.png'),
                            placeholder:
                                AssetImage('assets/placeholder-image.png'),
                          ));
                    },
                  )
                : Card(
                    margin: EdgeInsets.all(0.0),
                    // make colour dependent on the sender
                    // TODO: remove the ! in here and up here
                    // TODO: fully sort out the colouring scheme
                    color:
                        _isSentMessage(widget.messageSnapshot['sender']['id'])
                            ? Color.fromRGBO(0, 132, 255, 0.7)
                            : Color.fromRGBO(230, 230, 230, 1.0),
                    child: Container(
                        margin: const EdgeInsets.all(8.0),
                        child: new Linkify(
                          onOpen: (link) async {
                            if (await canLaunch(link.url)) {
                              await launch(link.url);
                            } else {
                              throw 'Could not launch $link';
                            }
                          },
                          text: widget.messageSnapshot['text'],
                          style: TextStyle(
                              fontSize: 15.0,
                              color: _isSentMessage(
                                      widget.messageSnapshot['sender']['id'])
                                  ? Colors.white
                                  : Colors.black),
                        ))));
  }

  _buildSenderProfilePhoto() {
    // bool isGoogle = (AuthState.currentUser.data.containsKey('isGoogle') &&
    //     AuthState.currentUser.data['isGoogle']);
    bool isGoogle = widget.messageSnapshot.data['sender'].containsKey('isGoogle') && widget.messageSnapshot.data['sender']['isGoogle'];
    bool isAnonymous =
        widget.messageSnapshot.data['sender']['isAnonymous'] != null &&
            widget.messageSnapshot.data['sender']['isAnonymous'];
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        new Container(
          // TODO: play with the size
          width: 30.0,
          height: 30.0,
          margin: const EdgeInsets.only(right: 8.0),
          child: CachedNetworkImage(
            imageUrl: isGoogle
                  ? widget.messageSnapshot.data['sender']['googleProfileURL']
                  : 'https://graph.facebook.com/${widget.messageSnapshot['sender']['facebookID']}/picture?height=30',
            imageBuilder: (context, imageProvider) => new CircleAvatar(
              backgroundImage: isAnonymous
                  ? AssetImage('assets/default-avatar.png')
                  : imageProvider,
            ),
          ),
        ),
      ],
    );
  }

  _buildSenderName() {
    bool isAnonymous =
        widget.messageSnapshot.data['sender']['isAnonymous'] != null &&
            widget.messageSnapshot.data['sender']['isAnonymous'];
    return new Text(
        isAnonymous
            ? widget.messageSnapshot['sender']['anonymousName']
            : widget.messageSnapshot['sender']['name'],
        style: new TextStyle(
            fontSize: 14.0, color: Colors.black, fontWeight: FontWeight.bold));
  }

  List<Widget> getReceivedMessageLayout(
      BlockedUserManager blockedUserProvider) {
    String repliesCount = widget.messageSnapshot['repliesCount'].toString();
    String repliesCountLabel = widget.messageSnapshot['repliesCount'] > 1
        ? repliesCount + ' replies'
        : repliesCount + ' reply';
    return widget.isPreviousMessageByTheSameSender
        ? <Widget>[
            // _buildSenderProfilePhoto(),
            new Expanded(
                child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // _buildSenderName(),
                _buildTextMessageContent(blockedUserProvider),
                Container(
                    margin: widget.isPreviousMessageByTheSameSender &
                            !_isSentMessage(
                                widget.messageSnapshot['sender']['id'])
                        ? EdgeInsets.only(
                            left:
                                38.0) // 30 + 8 (can turn into a variable, the inset values)
                        : EdgeInsets.all(0.0),
                    child: widget.messageSnapshot['imageURL'] != null
                        ? null
                        : widget.messageSnapshot['repliesCount'] > 0
                            ? GestureDetector(
                                child: new Text(
                                  repliesCountLabel,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 10.0),
                                ),
                                onTap: () {
                                  _openSubchat(widget.messageSnapshot, context);
                                },
                              )
                            : null)
              ].where((c) => c != null).toList(),
            ))
          ]
        : <Widget>[
            _buildSenderProfilePhoto(),
            new Expanded(
                child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildSenderName(),
                _buildTextMessageContent(blockedUserProvider),
                widget.messageSnapshot['imageURL'] != null
                    ? null
                    : widget.messageSnapshot['repliesCount'] > 0
                        ? new Text(
                            repliesCountLabel,
                            style:
                                TextStyle(color: Colors.grey, fontSize: 10.0),
                          )
                        : null
              ].where((c) => c != null).toList(),
            ))
          ];
  }

  List<Widget> getSentMessageLayout(BlockedUserManager blockedUserProvider) {
    String repliesCount = widget.messageSnapshot['repliesCount'].toString();
    String repliesCountLabel = widget.messageSnapshot['repliesCount'] > 1
        ? repliesCount + ' replies'
        : repliesCount + ' reply';
    return <Widget>[
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            // new Text(widget.messageSnapshot['sender']['name'],
            //     style: new TextStyle(
            //         fontSize: 14.0,
            //         color: Colors.black,
            //         fontWeight: FontWeight.bold)),
            _buildTextMessageContent(blockedUserProvider),

            widget.messageSnapshot['imageURL'] != null
                ? null
                : widget.messageSnapshot['repliesCount'] > 0
                    ? GestureDetector(
                        child: new Text(
                          repliesCountLabel,
                          style: TextStyle(color: Colors.grey, fontSize: 10.0),
                        ),
                        onTap: () {
                          _openSubchat(widget.messageSnapshot, context);
                        },
                      )
                    : null
          ].where((c) => c != null).toList(),
        ),
      ),
    ];
  }
}
