import 'package:flutter/material.dart';
// import '../view/ChatScreen.dart';
import '../model/models.dart';
import '../chat/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../view/chatItem.dart';
import '../auth_state.dart';
import '../login.dart';

class chats extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ChatState();
  }
}

class ChatState extends State<chats> {

  _buildSavedChats(){ 
        return StreamBuilder<QuerySnapshot>(
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
            return new Text(''); // Not displaying Loading...
          default:
            return new ListView.builder(
              itemCount: snapshot.data.documents.length,
              itemBuilder: (BuildContext context, int index) {
                var chatDocument = ChatModel();
                chatDocument.setChatModelFromJoinedChatDocumentSnapshot(
                    snapshot.data.documents[index]);
                return new 
                ChatItem(chatDocument: chatDocument);
              },
            );
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
    )
      );
  }

  @override
  Widget build(BuildContext context) {
    if(AuthState.currentUser == null) {
      return _buildSuggestionToLogIn();
    } else {
      return _buildSavedChats();
    }
  }
}