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
  final exploreChatsStream = Firestore.instance
      .collection('chats')
      .where('isSubchat', isEqualTo: false)
      .orderBy('reddit.rank')
      .limit(50)
      .snapshots();

  // TODO: turn into a stateful widget
  // Change ChatItem design
  // Do not use a SteamBuilder, it updates too often
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text("r/worldnews"),
      ),
      body: new StreamBuilder<QuerySnapshot>(
        stream: exploreChatsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) { 
            case ConnectionState.waiting:
              return new Text('');
            default:
              return new Scrollbar(
                child: new ListView(
                physics: new ClampingScrollPhysics(),
                children:
                    snapshot.data.documents.map((DocumentSnapshot document) {
                  var chatDocument = ChatModel();
                  chatDocument.setChatModelFromDocumentSnapshot(document);
                  return new Material(
                      child: ChatItem(chatDocument: chatDocument));
                }).toList(),
              ),
              )
              ;
          }
        },
      ),
    );
  }
}
