import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './chatmessagelistitem.dart';
import '../model/models.dart';

class MessagesList extends StatelessWidget {
  final ChatModel chatDocument;

  MessagesList({this.chatDocument});

  _checkPreviousMessageSameSender(DocumentSnapshot nextMessage, DocumentSnapshot currentMessage) {
    // TODO: check for edge cases
    String nextMessageSenderId = nextMessage.data['sender']['id'];
    String currentMessageSenderId = currentMessage['sender']['id'];
    return nextMessageSenderId==currentMessageSenderId;
  }

  // TODO: use a placeholder for the messages to display instead of loading?
  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (_) {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: new Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance
                .collection('messages')
                .where('chatId', isEqualTo: chatDocument.id)
                .orderBy('timestamp', descending: true)
                .limit(200) // can adjust later
                .snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError)
                return new Text('Error: ${snapshot.error}');
              if (snapshot.data != null) {
                return new ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (BuildContext context, int index) {
                    // TODO: check if the previous sender is the same
                    var isPreviousMessageByTheSameSender = false; 
                    if(index<snapshot.data.documents.length-1) {
                      isPreviousMessageByTheSameSender = _checkPreviousMessageSameSender(snapshot.data.documents[index+1], snapshot.data.documents[index]);
                    }
                    return new Container(
                      padding: EdgeInsets.all(0.5),
                      child: new ChatMessageListItem(
                        messageSnapshot: snapshot.data.documents[index], isPreviousMessageByTheSameSender: isPreviousMessageByTheSameSender
                      ),
                    );
                  },
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          )),
    );
  }
}

// TODO: check this code out, might help with the Loading... issues
// StreamBuilder<List<Content>> _getContentsList(BuildContext context) {
//   final BlocProvider blocProvider = BlocProvider.of(context);
//   int page = 1;
//   return StreamBuilder<List<Content>>(
//       stream: blocProvider.contentBloc.contents,
//       initialData: [],
//       builder: (context, snapshot) {
//         if (snapshot.data.isNotEmpty) {
//           return ListView.builder(itemBuilder: (context, index) {
//             if (index < snapshot.data.length) {
//               return ContentBox(content: snapshot.data.elementAt(index));
//             } else if (index / 5 == page) {
//               page++;
//               blocProvider.contentBloc.index.add(index);
//             }
//           });
//         } else {
//           return Center(
//             child: CircularProgressIndicator(),
//           );
//         }
//       });
// }
