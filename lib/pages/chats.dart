import 'package:flutter/material.dart';
// import '../view/ChatScreen.dart';
import '../model/models.dart';
import '../chat/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../view/chatItem.dart';
import '../auth_state.dart';

class chats extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ChatState();
  }
}

class ChatState extends State<chats> {
  // TODO: allow ordering chats according to the timestamp of their last message

  int chatsLimit = 10;

  final joinedChats = Firestore.instance
      .collection('joinedChats')
      .where('user.id', isEqualTo: AuthState.currentUser.documentID)
      .orderBy('timestamp', descending: true)
      .limit(2)
      .snapshots();

  final _scrollController = new ScrollController();

  // @override
  // initState() {
  //   super.initState();
  
  //   _scrollController.addListener(() {
  //     double maxScroll = _scrollController.position.maxScrollExtent;
  //     double currentScroll = _scrollController.position.pixels;
  //     double delta = 200.0; // or something else..
  //     print(maxScroll);
  //     print(currentScroll);
  //     // TODO: fix the scroll after state is changeds
  //     setState(() {
  //       if (maxScroll - currentScroll <= delta) {
  //         chatsLimit = chatsLimit + 10;
  //       }
  //       _scrollController.position.pixels = currentScroll;  
  //     });
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('joinedChats')
          .where('user.id', isEqualTo: AuthState.currentUser.documentID)
          .orderBy('timestamp', descending: true)
          .limit(chatsLimit)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return new Text(''); // Not displaying Loading...
          default:
            return new ListView.builder(
              controller: _scrollController,
              itemCount: snapshot.data.documents.length,
              itemBuilder: (BuildContext context, int index) {
                var chatDocument = ChatModel();
                chatDocument.setChatModelFromJoinedChatDocumentSnapshot(
                    snapshot.data.documents[index]);
                return new ChatItem(chatDocument: chatDocument);
              },
            );
        }
      },
    );
  }
}
