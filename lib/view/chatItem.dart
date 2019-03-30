import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../chat/chatscreen.dart';
import '../auth_state.dart';
import 'dart:core';
import '../model/models.dart';
import '../chat/messageInfoPage.dart';

class ChatItem extends StatelessWidget {
  // Can be a DocumentSnapshot, can also be a chat document retreived from Algolia
  final ChatModel chatDocument;
  final bool isSubchat;
  final String heroTag;

  DocumentSnapshot parentMessageSnapshot;

  final SnackBar snackBar = SnackBar(
    content: Text("Message was successfully linked!"),
  );

  ChatItem(
      {this.chatDocument,
      this.isSubchat = false,
      this.parentMessageSnapshot,
      this.heroTag = "defaultTag"});

  // Future<bool> _isChatJoined() async {
  //   final QuerySnapshot result = await Firestore.instance
  //       .collection('joinedChats')
  //       .where('chatId', isEqualTo: chatDocument.id)
  //       .where('user.id', isEqualTo: AuthState.currentUser.documentID)
  //       .getDocuments();

  //   final List<DocumentSnapshot> documents = result.documents;

  //   return documents.length > 0 ? true : false;
  // }

  @override
  Widget build(BuildContext context) {
    print(heroTag + chatDocument.id.toString());
    return Hero(
      tag: heroTag + chatDocument.id.toString(),
      child: ListTile(
        leading: new CircleAvatar(
          backgroundImage: AssetImage('assets/default-chat.png'),
          backgroundColor: Colors.white,
          // backgroundImage:  // new NetworkImage(chatDocument.avatarURL),
        ),
        title: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            new Text(
              chatDocument.name,
              style: new TextStyle(fontWeight: FontWeight.bold),
            ),
            new Text(
              // TODO: sort out if the date and other stuff fit into the page
              // chatDocument['timestamp'].toDate().toLocal().toString().substring(0, 11),
              // do timeago
              chatDocument.timestamp.toString().substring(0, 11),
              style: new TextStyle(color: Colors.grey, fontSize: 14.0),
            ),
          ],
        ),
        subtitle: new Container(
            padding: const EdgeInsets.only(top: 5.0),
            // TODO: take into account that the message can also be an image
            child: StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance
                  .collection('messages')
                  .where('chatId', isEqualTo: chatDocument.id)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return new Text('Error: ${snapshot.error}');
                }
                if (snapshot.data != null) {
                  if (snapshot.data.documents.length > 0) {
                    print(snapshot.data.documents[0].data['text']);
                    if (snapshot.data.documents[0].data['text'] == null) {
                      String lastMessage = 'photo';
                      return Row(children: <Widget>[
                        new Icon(
                          Icons.camera_alt,
                          color: Colors.grey,
                          size: 15.0,
                        ),
                        Text(lastMessage,
                            style:
                                TextStyle(color: Colors.grey, fontSize: 15.0))
                      ]);
                    } else {
                      String lastMessage =
                          snapshot.data.documents[0].data['text'].toString();
                      return Text(lastMessage,
                          style: TextStyle(color: Colors.grey, fontSize: 15.0));
                    }
                  } else {
                    return Text("No messages yet");
                  }
                } else {
                  return Text("");
                }
              },
            )),
        onTap: () {
          Navigator.push(context, new MaterialPageRoute(builder: (context) {
            print(chatDocument.id);
            return new ChatScreen(chatDocument: chatDocument);
          }));
        },
      ),
    );
  }
}
