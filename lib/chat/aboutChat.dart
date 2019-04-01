import 'package:flutter/material.dart';
import '../model/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatView extends StatelessWidget {
  final ChatModel chatDocument;

  ChatView(this.chatDocument);

  // _getChatMembers() {}

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new CustomScrollView(
        slivers: <Widget>[
          new SliverAppBar(
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            flexibleSpace: new FlexibleSpaceBar(
              title: new Text(chatDocument.name),
              background: new Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  chatDocument.avatarURL != ""
                      ? Image.network(
                          chatDocument.avatarURL,
                          fit: BoxFit.cover,
                        )
                      : new Image.asset(
                          'assets/default-chat.png',
                          fit: BoxFit.cover,
                        ),
                ],
              ),
            ),
          ),
          // new StreamBuilder<QuerySnapshot>(
          //   stream: Firestore.instance
          //       .collection('joinedChats')
          //       .where('chatId', isEqualTo: chatDocument.id)
          //       .snapshots(),
          //   builder:
          //       (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          //     if (snapshot.hasError)
          //       return new Text('Error: ${snapshot.error}');
          //     switch (snapshot.connectionState) {
          //       case ConnectionState.waiting:
          //         return new Text(''); // Not displaying Loading...
          //       default:
          //         return new ListView.builder(
          //           itemCount: snapshot.data.documents.length,
          //           itemBuilder: (BuildContext context, int index) {
          //             // var chatDocument = ChatModel();
          //             // chatDocument.setChatModelFromJoinedChatDocumentSnapshot(
          //             // snapshot.data.documents[index]);
          //             // new ListTile(
          //             //   leading: new CircleAvatar(
          //             //     backgroundImage:
          //             //         new NetworkImage(
          //             //           'https://graph.facebook.com/${snapshot.data.documents[index]['user']['facebookID']}/picture?height=500'
          //             //           ),
          //             //   ),
          //             //   title: new Text("Group 1"),
          //             //   subtitle: new Text("Member1, Member2..."),
          //             // );
          //           },
          //         );
          //     }
          //   },
          // ),
          new SliverList(
            delegate: new SliverChildListDelegate(<Widget>[
              new Text(chatDocument.about)
              // new ListTile(
              //   leading: new Icon(
              //     Icons.thumb_down,
              //     color: Colors.red,
              //   ),
              //   title: new Text(
              //     "Report spam",
              //     style: new TextStyle(color: Colors.red),
              //   ),
              // )
            ]),
          )
        ],
      ),
    );
  }
}
