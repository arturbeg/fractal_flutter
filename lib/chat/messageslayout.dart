import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './chatmessagelistitem.dart';

class MessagesList extends StatelessWidget {
  
  final DocumentSnapshot chatDocument;
  
  MessagesList({this.chatDocument});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('messages').where(
        'chatId', isEqualTo: chatDocument.documentID
      ).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError)
          return new Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          // TODO: fix the loading issue, displayed too often
          case ConnectionState.waiting: return new Text('Loading...');
          default:
            return new ListView(
              children: snapshot.data.documents.map((DocumentSnapshot document) {
                return new ChatMessageListItem(messageSnapshot: document,);
              }).toList(),
            );
        }
      },
    );
  }
}