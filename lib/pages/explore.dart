import 'package:flutter/material.dart';
// import '../view/ChatScreen.dart';
import '../model/models.dart';
import '../chat/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../view/chatItem.dart';



class explore extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ExploreState();
  }
}

class ExploreState extends State<explore> {
  @override
  Widget build(BuildContext context) {
    return new ExploreChatsList();
  }
}


class ExploreChatsList extends StatelessWidget {

  final exploreChatsStream = Firestore.instance.collection('chats').snapshots();
  // TODO: change the StreamBuilder implementation (circular progress instead of "Loading...")
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: exploreChatsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError)
          return new Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.waiting: return new Text('Loading...');
          default:
            return new ListView(
              children: snapshot.data.documents.map((DocumentSnapshot document) {
                var chatDocument = ChatModel();
                chatDocument.setChatModelFromDocumentSnapshot(document);
                return new ChatItem(chatDocument: chatDocument);
              }).toList(),
            );
        }
      },
    );
  }
}


