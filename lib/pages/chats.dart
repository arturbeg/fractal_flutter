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

class ChatState extends State<chats> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  CachedChats cachedChatsProvider;

  @override
  void initState() {
    super.initState();
    setState(() {
      cachedChatsProvider = Provider.of<CachedChats>(context, listen: false);
    });
    cachedChatsProvider.fetchSavedChatsForCache();
  }

  _buildSavedChats(CachedChats cachedChatsProvider) {
    return StreamBuilder<QuerySnapshot>(
      initialData: cachedChatsProvider.getCachedSavedChats(),
      stream: Firestore.instance
          .collection('joinedChats')
          .where('user.id', isEqualTo: AuthState.currentUser.documentID)
          .orderBy('lastMessageTimestamp', descending: true)
          .limit(80)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            // TODO: later introduce a custom progress indicator
            return Center(
              child: CircularProgressIndicator(),
            );
          default:
            return Scrollbar(
                child: new ListView.builder(
              physics: new ClampingScrollPhysics(),
              itemCount: snapshot.data.documents.length,
              itemBuilder: (BuildContext context, int index) {
                var chatDocument = ChatModel();
                chatDocument.setChatModelFromJoinedChatDocumentSnapshot(
                    snapshot.data.documents[index]);
                return new ChatItem(
                  chatDocument: chatDocument,
                );
              },
            ));
        }
      },
    );
  }

  _buildSuggestionToLogIn() {
    return Center(
        child: new SizedBox(
      width: double.infinity,
      child: new FlatButton(
        child: Text('Log in to see your saved chats'),
        textColor: Colors.black,
        onPressed: () {
          // print('pressed!');
          Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
            return new LoginPage(redirectBack: true);
          }));
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (AuthState.currentUser == null) {
      return _buildSuggestionToLogIn();
    } else {
      return _buildSavedChats(cachedChatsProvider);
    }
  }
}
