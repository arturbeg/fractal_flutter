import 'package:flutter/material.dart';
import 'package:fractal/pages/chats.dart';
import 'package:provider/provider.dart';
// import '../view/ChatScreen.dart';
import '../model/models.dart';
import '../chat/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../view/chatItem.dart';
import '../explored_chats_state.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../chats_provider.dart';
import 'dart:async';

class explore extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ExploreState();
  }
}

class ExploreState extends State<explore> {
  // TODO: load more functionality in here with a future builder

  // TODO: put this login into a provider

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
      return Text("11");
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatsProvider = Provider.of<CachedChats>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text("r/worldnews"),
      ),
      body: RefreshIndicator(
        onRefresh: chatsProvider.handleRefresh,
        color: Colors.white,
        backgroundColor: Colors.black,
        child: FutureBuilder(
            initialData: chatsProvider.cachedExploredChats,
            future: chatsProvider.exploredChatsFuture,
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return Text('none');
                case ConnectionState.active:
                case ConnectionState.waiting:
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                case ConnectionState.done:
                  if (snapshot.hasError)
                    return Text('Error: ${snapshot.error}');
                  chatsProvider.updatedCachedExploredChats(snapshot.data);
                  return _buildListView(snapshot.data.documents);
              }
              return null;
            }),
      ),
    );
  }
}
