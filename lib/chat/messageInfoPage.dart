import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './branchingPage.dart';
import '../model/models.dart';
import '../view/chatItem.dart';

class MessageInfoPage extends StatefulWidget {

  final DocumentSnapshot messageSnapshot;

  MessageInfoPage({this.messageSnapshot});

  @override
  _MessageInfoPageState createState() => _MessageInfoPageState();
}

class _MessageInfoPageState extends State<MessageInfoPage> {
  

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text("Message Subchats"),
      ),
      body: new StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('chats')
    .where('parentMessageId', isEqualTo: widget.messageSnapshot.documentID).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError)
          return new Text(''); // Do not display errors
        switch (snapshot.connectionState) {
          case ConnectionState.waiting: return new Text(''); // Displaying no text instead of loading
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
    )
    );
  }
}
