import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  // TODO: would be cool to enforce types
  var id;
  var about; // String
  var avatarURL; // String
  var lastMessage; // ChatLastMessageModel
  var name; // String
  var owner; // ChatOwnerModel
  var timestamp; // DateTime
  var parentChat; // ParentChatModel
  var isSubchat;
  var parentMessageId;

  getFirebaseTimestamp() {
    var millisecondsSinceEpoch = timestamp.millisecondsSinceEpoch;
    return Timestamp.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  }

  // TODO: fix the joined chat model
  setChatModelFromJoinedChatDocumentSnapshot(
      DocumentSnapshot joinedChatDocument) {
    id = joinedChatDocument['chatId'];
    about = joinedChatDocument['about'];
    avatarURL = joinedChatDocument['avatarURL'];
    // lastMessage = ChatLastMessageModel(imageURL: joinedChatDocument['lastMessage']['imageURL'], text: joinedChatDocument['lastMessage']['text']);
    name = joinedChatDocument['name'];
    owner = ChatOwnerModel(
        avatarURL: joinedChatDocument['owner']['avatarURL'],
        id: joinedChatDocument['owner']['id'],
        name: joinedChatDocument['owner']['name']);
    timestamp = joinedChatDocument['chatTimestamp'].toDate();


    parentChat = ParentChatModel(avatarURL: joinedChatDocument['parentChat']['avatarURL'],
                                 id: joinedChatDocument['parentChat']['id'],
                                 name: joinedChatDocument['parentChat']['name'],
    );

    parentMessageId = joinedChatDocument['parentMessageId'];
    
  }

  setChatModelFromDocumentSnapshot(DocumentSnapshot chatDocument) {
    id = chatDocument.documentID;
    about = chatDocument['about'];
    avatarURL = chatDocument['avatarURL'];
    name = chatDocument['name'];
    owner = ChatOwnerModel(
        avatarURL: chatDocument['owner']['avatarURL'],
        id: chatDocument['owner']['id'],
        name: chatDocument['owner']['name']);

    timestamp = chatDocument['timestamp'].toDate();

    parentChat = ParentChatModel(avatarURL: chatDocument['parentChat']['avatarURL'],
                                 id: chatDocument['parentChat']['id'],
                                 name: chatDocument['parentChat']['name'],
    );

    parentMessageId = chatDocument['parentMessageId'];
  }

  // TODO: fix the Algolia Snapshot model
  setChatModelFromAlgoliaSnapshot(chatAlgoliaDocument) {
    id = chatAlgoliaDocument['objectId'];
    about = chatAlgoliaDocument['about'];
    avatarURL = chatAlgoliaDocument['avatarURL'];
    name = chatAlgoliaDocument['name'];
    owner = ChatOwnerModel(
        avatarURL: chatAlgoliaDocument['owner']['avatarURL'],
        id: chatAlgoliaDocument['owner']['id'],
        name: chatAlgoliaDocument['owner']['name']);

    final millisecondsSinceEpoch =
        chatAlgoliaDocument['timestamp']['_seconds'] * 1000;
    timestamp = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  }
}

// class ChatLastMessageModel {

//   final String imageURL;
//   final String text;

//   ChatLastMessageModel({this.imageURL, this.text});

//   getChatLastMessageModelMap() {
//     final map = {
//       'imageURL':imageURL,
//       'text': text
//     };

//     return map;
//   }
// }

class ChatOwnerModel {
  final String avatarURL;
  final String id;
  final String name;

  ChatOwnerModel({this.avatarURL, this.id, this.name});

  getChatOwnerModelMap() {
    final map = {'avatarURL': avatarURL, 'id': id, 'name': name};

    return map;
  }
}

// TODO: add the model to all the above-mentioned classes
class ParentChatModel {
  final String avatarURL;
  final String id;
  final String name;

  ParentChatModel({this.avatarURL, this.id, this.name});

  getParentChatModelMap() {
    final map = {'avatarURL': avatarURL, 'id': id, 'name': name};

    return map;
  }
}
