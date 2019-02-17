import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../chat/chatscreen.dart';
import '../auth_state.dart';
import 'dart:core';

class ChatItem extends StatelessWidget {
  final DocumentSnapshot chatDocument;

  ChatItem({this.chatDocument});

  Future<bool> _isChatJoined() async {
    final QuerySnapshot result = await Firestore.instance
        .collection('joinedChats')
        .where('chatId', isEqualTo: chatDocument.documentID)
        .where('userId', isEqualTo: AuthState.currentUser.documentID)
        .getDocuments();

    final List<DocumentSnapshot> documents = result.documents;

    return documents.length > 0 ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: new CircleAvatar(
        foregroundColor: Theme.of(context).accentColor,
        backgroundColor: Colors.grey,
        backgroundImage: new NetworkImage(chatDocument['avatarURL']),
      ),
      title: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          new Text(
            chatDocument['name'],
            style: new TextStyle(fontWeight: FontWeight.bold),
          ),
          new Text(
            // TODO: sort out if the date and other stuff fit into the page
            chatDocument['timestamp'].toDate().toLocal().toString().substring(0, 11),
            style: new TextStyle(color: Colors.grey, fontSize: 14.0),
          ),
        ],
      ),
      subtitle: new Container(
        padding: const EdgeInsets.only(top: 5.0),
        // TODO: take into account that the message can also be an image

        child: new Text(
          chatDocument['lastMessage']['text'],
          style: TextStyle(color: Colors.grey, fontSize: 15.0),
        ),
      ),
      onTap: () {
        _isChatJoined().then((isJoined) {
          if (!isJoined) {
            print("The chat was already joined");
            final reference = Firestore.instance.collection('joinedChats');
            reference.document().setData({
              "about": chatDocument['about'],
              "avatarURL": chatDocument['avatarURL'],
              "chatId": chatDocument.documentID,
              "chatTimestamp": chatDocument['timestamp'],
              "name": chatDocument['name'],
              "owner": chatDocument['owner'],
              "timestamp": FieldValue.serverTimestamp(),
              "userId": AuthState.currentUser.documentID,
              "lastMessage": chatDocument['lastMessage']
            });
          }
        });
        Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
          return new ChatScreen(chatDocument: chatDocument);
        }));
      },
    );
  }
}

class ChatLastMessage extends StatelessWidget {
  final String chatId;
  ChatLastMessage({this.chatId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('messages')
          .where('chatid', isEqualTo: chatId)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return new Text('Loading...');
          default:
            return Text(snapshot.data.documents[0]['text'],
                style: new TextStyle(fontWeight: FontWeight.bold));
        }
      },
    );
  }
}

// new ListView(
//               children: snapshot.data.documents.map((DocumentSnapshot document) {
//                 return Text(
//                         document['text'],
//                         style: new TextStyle(fontWeight: FontWeight.bold),
//                       );
//               }).toList(),
//             );

// ListView.builder(
//         itemCount: dummy.length,
//         itemBuilder: (context, l) => new Column(
//               children: <Widget>[
//                 new Divider(
//                   height: 10.0,
//                 ),
//                 new ExploreChatsList()
//               ],
//             ))
