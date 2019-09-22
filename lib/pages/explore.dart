import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/models.dart';
import '../view/chatItem.dart';
import '../chats_provider.dart';

class explore extends StatelessWidget {
  _buildListView(List<ChatModel> documents) {
    if (documents != null) {
      if (documents.length == 0) {
        return Center(
          child: Text("No chats available"),
        );
      } else {
        return new Scrollbar(
            child: new ListView.builder(
          physics: new ClampingScrollPhysics(),
          itemCount: documents.length,
          itemBuilder: (BuildContext context, int index) {
            return new ChatItem(
              chatDocument: documents[index],
            );
          },
        ));
      }
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
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
        onRefresh: chatsProvider.fetchExploredChatsForCache,
        color: Colors.blue,
        backgroundColor: Colors.white,
        child: _buildListView(chatsProvider.getCachedExploredChats()),
      ),
    );
  }
}
