import 'package:flutter/material.dart';
import 'package:fractal/pages/chats.dart';
// import '../view/ChatScreen.dart';
import '../model/models.dart';
import '../chat/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../view/chatItem.dart';
import '../explored_chats_state.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class explore extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ExploreState();
  }
}

class ExploreState extends State<explore> {

  final exploreChatsStream = Firestore.instance
      .collection('chats')
      .where('isSubchat', isEqualTo: false)
      .orderBy('reddit.rank')
      .limit(30)
      .snapshots();
  
  // TODO: load more functionality in here with a future builder

  _buildListView(documents) {
    if (documents != null) {
      return new Scrollbar(
          child: new ListView.builder(
        physics: new ClampingScrollPhysics(),
        itemCount: documents.length,
        itemBuilder: (BuildContext context, int index) {
          var chatDocument = ChatModel();
          chatDocument.setChatModelFromDocumentSnapshot(documents[index]);
          return new ChatItem(
            chatDocument: chatDocument,
          );
        },
      ));
    } else {
      // TODO: placeholder rectange like on Youtube or instagram
      return Text("");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text("r/worldnews"),
      ),
      body: new StreamBuilder<QuerySnapshot>(
        initialData: ExploreChatsCache.snapshot,
        stream: exploreChatsStream,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) {
            // TODO: use default
            case ConnectionState.waiting:
              print("Connection state is waiting");
              return Center(child: CircularProgressIndicator(),);
              // return _buildListView(ExploreChatsCache.snapshot.documents);
            case ConnectionState.none:
              print("Connection state is none");
              return Text('');
              // return _buildListView(ExploreChatsCache.snapshot.documents);
            case ConnectionState.active:
              print("Active");
              print("Connection state is done");
              ExploreChatsCache.instance.setExploreChats(snapshot.data);
              print(ExploreChatsCache.snapshot.documents[0].documentID);
              return _buildListView(snapshot.data.documents);
            case ConnectionState.done:
              print("Connection state is done");
              ExploreChatsCache.instance.setExploreChats(snapshot.data);
              print(ExploreChatsCache.snapshot.documents[0].documentID);
              return _buildListView(snapshot.data.documents);
          }
        },
      ),
    );
  }
}
