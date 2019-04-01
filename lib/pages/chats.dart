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
                return new ChatItem(chatDocument: chatDocument);
              },
            );
        }
      },
    );
  }
}





// import 'package:flutter/material.dart';
// // import '../view/ChatScreen.dart';
// import '../model/models.dart';
// import '../chat/chatscreen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../view/chatItem.dart';
// import '../auth_state.dart';

// class chats extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() {
//     return new ChatState();
//   }
// }

// class ChatState extends State<chats> {
//   var joinedChats;

//   @override
//   void initState() {
//     super.initState();
//     print("Initialising the chats state");
//     setState(() {
//       _fetchJoinedChats().then((documents) {
//         print("Setting the state!");
//         // print(documents.length);
//         joinedChats = documents;
//       });
//     });
//   }

//   Future<QuerySnapshot> _fetchJoinedChats() async {
//     final QuerySnapshot querySnapshot = await Firestore.instance
//         .collection('joinedChats')
//         .orderBy('timestamp', descending: true)
//         .limit(10)
//         .getDocuments();

//     return querySnapshot;
//   }

//   _sortDocuments(unsortedDocuments) async {
//     print("Foreach starting");
//     await unsortedDocuments.forEach((document) {
      
//       // print(document.data['timestamp']);
//       Firestore.instance
//           .collection('messages')
//           .where('chatId', isEqualTo: document.documentID)
//           .orderBy("timestamp", descending: true)
//           .getDocuments()
//           .then((messages) {
//             print("Foreeach continuitng"); 

//         if (messages.documents.length != 0) {
//           var timestamp = messages.documents[0].data['timestamp']
//               .toDate()
//               ;
//               print(timestamp);
//           document.data['lastUpdate'] = timestamp;
//         } else {
//           // print("the length is 0");
//           var timestamp = document.data['timestamp'].toDate().millisecondsSinceEpoch;
//           document.data['lastUpdate'] = timestamp;
//           print(document.data['lastUpdate']);
//         }
//       });
      
//     });

//     print("Foreach ending");
//     return unsortedDocuments;
//   }

//   _acutallySortDocuments(unsortedDocuments) {
//     print(unsortedDocuments);
//     // print(unsortedDocuments[0].data);
//     // sort here
//     // unsortedDocuments.sort((a,b) {
//     //   return a.data['lastUpdated'].compareTo(b.data['lastUpdated']);
//     // });

//     return unsortedDocuments;
//   }


//   _finalFuture(updatedDocuments)  {
//     print("Final future starting");
//     return FutureBuilder<dynamic>(
//       future: updatedDocuments,
//       builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
//         switch (snapshot.connectionState) {
//           case ConnectionState.none:
//             return Text(''); //Press button to start.
//           case ConnectionState.active:
//           case ConnectionState.waiting:
//             return Text(''); // Awaiting result...
//           case ConnectionState.done:
//             if (snapshot.hasError) {
//               return Text('Error: ${snapshot.error}');
//             }
//             print("something");
//             var actuallySortedDocuments = _acutallySortDocuments(snapshot.data);
//             print(actuallySortedDocuments);
//             return Text("SHIT");
//         }
//         return null; // unreachable
//       },
//     );    
//    }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<QuerySnapshot>(
//       future: _fetchJoinedChats(),
//       builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         switch (snapshot.connectionState) {
//           case ConnectionState.none:
//             return Text(''); //Press button to start.
//           case ConnectionState.active:
//           case ConnectionState.waiting:
//             return Text(''); // Awaiting result...
//           case ConnectionState.done:
//             if (snapshot.hasError) {
//               return Text('Error: ${snapshot.error}');
//             }
//             var unsortedDocuments = snapshot.data.documents.toList();
//             var updatedDocuments = _sortDocuments(unsortedDocuments);
//             // return Text('Result: ${snapshot.data.documents.length}');
//             return _finalFuture(updatedDocuments);
//         }
//         return null; // unreachable
//       },
//     );
//   }

//   // @override
//   // Widget build(BuildContext context) {
//   //   return ListView.builder(
//   //     itemCount: 1,
//   //     itemBuilder: (BuildContext context, int index) {
//   //       print(joinedChats);
//   //       var chatDocument = ChatModel();
//   //       chatDocument.setChatModelFromJoinedChatDocumentSnapshot(
//   //           joinedChats.documents[index]);
//   //       return new ChatItem(chatDocument: chatDocument);
//   //     },
//   //   );
//   // }

// //   new FutureBuilder(
// //   future: _calculation, // a Future<String> or null
// //   builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
// //     switch (snapshot.connectionState) {
// //       case ConnectionState.none: return new Text('Press button to start');
// //       case ConnectionState.waiting: return new Text('Awaiting result...');
// //       default:
// //         if (snapshot.hasError)
// //           return new Text('Error: ${snapshot.error}');
// //         else
// //           return new Text('Result: ${snapshot.data}');
// //     }
// //   },
// // )

//   // TODO: allow ordering chats according to the timestamp of their last message

//   // int chatsLimit = 10;

//   // final joinedChats = Firestore.instance
//   //     .collection('joinedChats')
//   //     .where('user.id', isEqualTo: AuthState.currentUser.documentID)
//   //     .orderBy('timestamp', descending: true)
//   //     .limit(2)
//   //     .snapshots();

//   // final _scrollController = new ScrollController();

//   // @override
//   // initState() {
//   //   super.initState();

//   //   _scrollController.addListener(() {
//   //     double maxScroll = _scrollController.position.maxScrollExtent;
//   //     double currentScroll = _scrollController.position.pixels;
//   //     double delta = 200.0; // or something else..
//   //     print(maxScroll);
//   //     print(currentScroll);
//   //     // TODO: fix the scroll after state is changeds
//   //     setState(() {
//   //       if (maxScroll - currentScroll <= delta) {
//   //         chatsLimit = chatsLimit + 10;
//   //       }
//   //       _scrollController.position.pixels = currentScroll;
//   //     });
//   //   });
//   // }

//   // @override
//   // Widget build(BuildContext context) {
//   //   return StreamBuilder<QuerySnapshot>(
//   //     stream: Firestore.instance
//   //         .collection('joinedChats')
//   //         .where('user.id', isEqualTo: AuthState.currentUser.documentID)
//   //         .orderBy('timestamp', descending: true)
//   //         .limit(chatsLimit)
//   //         .snapshots(),
//   //     builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//   //       if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
//   //       switch (snapshot.connectionState) {
//   //         case ConnectionState.waiting:
//   //           return new Text(''); // Not displaying Loading...
//   //         default:
//   //           return new ListView.builder(
//   //             controller: _scrollController,
//   //             itemCount: snapshot.data.documents.length,
//   //             itemBuilder: (BuildContext context, int index) {
//   //               var chatDocument = ChatModel();
//   //               chatDocument.setChatModelFromJoinedChatDocumentSnapshot(
//   //                   snapshot.data.documents[index]);
//   //               return new ChatItem(chatDocument: chatDocument);
//   //             },
//   //           );
//   //       }
//   //     },
//   //   );
//   // }
// }
