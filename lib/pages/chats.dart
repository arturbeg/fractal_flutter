import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import '../view/ChatScreen.dart';
import '../model/models.dart';
import '../chat/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../view/chatItem.dart';
import '../auth_state.dart';
import '../login.dart';
import 'package:async/async.dart';
import '../chats_provider.dart';

class chats extends StatefulWidget {
  ChatState state;

  @override
  State<StatefulWidget> createState() {
    // need to expose the state for children to use
    var state = new ChatState();
    return state;
  }
}

class ChatState extends State<chats> {
  @override
  void initState() {
    super.initState();
  }

  _buildSavedChatsList(List<ChatModel> documents) {
    if (documents == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      if (documents.length == 0) {
        return Center(
          child: Text("No saved chats yet"),
        );
      } else {
        return Scrollbar(
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
    }
  }

  _buildSuggestionToLogIn() {
    return Center(
      child: new RaisedButton(
        child: Text('Log in to see your saved chats'),
        color: Color.fromRGBO(0, 132, 255, 0.7),
        textColor: Colors.white,
        onPressed: () {
          //// print('pressed!');
          Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
            return new LoginPage(redirectBack: true);
          }));
        }));
  }

  @override
  Widget build(BuildContext context) {
    CachedChats cachedChatsProvider = Provider.of<CachedChats>(context);
    if (AuthState.currentUser == null) {
      return _buildSuggestionToLogIn();
    } else {
      return RefreshIndicator(
        child: _buildSavedChatsList(cachedChatsProvider.getCachedSavedChats()),
        color: Colors.blue,
        backgroundColor: Colors.white,
        onRefresh: cachedChatsProvider.fetchSavedChatsForCache, 
      );
    }
  }
}
