import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fractal/messages_provider.dart';
import 'package:provider/provider.dart';
import './chatmessagelistitem.dart';
import '../model/models.dart';

// TODO: cached messages firebase provider and consumer in here

class MessagesList extends StatefulWidget {
  final ChatModel chatDocument;

  MessagesList({this.chatDocument});

  @override
  _MessagesListState createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  CachedMessagesFirebase messagesProvider;

  _checkPreviousMessageSameSender(
      DocumentSnapshot nextMessage, DocumentSnapshot currentMessage) {
    // TODO: check for edge cases
    String nextMessageSenderId = nextMessage.data['sender']['id'];
    String currentMessageSenderId = currentMessage['sender']['id'];

    // TODO: refactor
    bool nextMessageIsAnonymous =
        nextMessage.data['sender']['isAnonymous'] != null
            ? nextMessage.data['sender']['isAnonymous']
            : false;

    bool currentMessageIsAnonymous =
        currentMessage.data['sender']['isAnonymous'] != null
            ? currentMessage.data['sender']['isAnonymous']
            : false;

    return (nextMessageSenderId == currentMessageSenderId &&
        nextMessageIsAnonymous == currentMessageIsAnonymous);
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      messagesProvider =
          Provider.of<CachedMessagesFirebase>(context, listen: false);
    });
    // TODO: could use the duration in here to do every 30 min
    messagesProvider.fetchMessagesForCache(widget.chatDocument.id);
  }

  _buildMessagesList(snapshot) {
    if (snapshot.data != null) {
      return new Scrollbar(
        child: new ListView.builder(
          physics: new ClampingScrollPhysics(),
          reverse: true,
          itemCount: snapshot.data.documents.length,
          itemBuilder: (BuildContext context, int index) {
            var isPreviousMessageByTheSameSender = false;
            if (index < snapshot.data.documents.length - 1) {
              isPreviousMessageByTheSameSender =
                  _checkPreviousMessageSameSender(
                      snapshot.data.documents[index + 1],
                      snapshot.data.documents[index]);
            }
            return new Container(
              padding: EdgeInsets.all(2.0),
              child: new ChatMessageListItem(
                  messageSnapshot: snapshot.data.documents[index],
                  isPreviousMessageByTheSameSender:
                      isPreviousMessageByTheSameSender),
            );
          },
        ),
      );
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }

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
            initialData:
                messagesProvider.getCachedMessages(widget.chatDocument.id),
            stream: messagesProvider.fetchMessages(widget.chatDocument.id),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError)
                return new Text('Error: ${snapshot.error}');
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              return _buildMessagesList(snapshot);
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
