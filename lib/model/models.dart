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
  var lastMessageTimestamp;
  var user; // only related to the joinedChat case
  var url;
  var reddit;

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
        facebookID: joinedChatDocument['owner']['facebookID'],
        id: joinedChatDocument['owner']['id'],
        name: joinedChatDocument['owner']['name']);
    timestamp = joinedChatDocument['chatTimestamp'].toDate();
    lastMessageTimestamp = joinedChatDocument['lastMessageTimestamp'].toDate();

    parentChat = ParentChatModel(
      avatarURL: joinedChatDocument['parentChat']['avatarURL'],
      id: joinedChatDocument['parentChat']['id'],
      name: joinedChatDocument['parentChat']['name'],
    );

    user = ChatOwnerModel(
        facebookID: joinedChatDocument['user']['facebookID'],
        id: joinedChatDocument['user']['id'],
        name: joinedChatDocument['user']['name']);

    parentMessageId = joinedChatDocument['parentMessageId'];

    url = joinedChatDocument['url'] != null ? joinedChatDocument['url'] : "";

    isSubchat = joinedChatDocument['isSubchat'];

    reddit = RedditModel(
      author: joinedChatDocument['reddit']['author'],
      num_comments: joinedChatDocument['reddit']['num_comments'],
      rank: joinedChatDocument['reddit']['rank'],
      reddit_score: joinedChatDocument['reddit']['reddit_score'],
      shortlink: joinedChatDocument['reddit']['shortlink'],
      upvote_ratio: joinedChatDocument['reddit']['upvote_ratio'],
      id: joinedChatDocument['reddit']['id'],
      over_18: joinedChatDocument['reddit']['over_18'],
      subreddit: joinedChatDocument['reddit']['subreddit'],
      // created_utc: DateTime.fromMicrosecondsSinceEpoch(joinedChatDocument['reddit']['created_utc'])
      // "created_utc": submission.created_utc
    );
  }

  setChatModelFromDocumentSnapshot(DocumentSnapshot chatDocument) {

    id = chatDocument.documentID;
    about = chatDocument['about'];
    avatarURL = chatDocument['avatarURL'];
    name = chatDocument['name'];
    owner = ChatOwnerModel(
        facebookID: chatDocument['owner']['facebookID'],
        id: chatDocument['owner']['id'],
        name: chatDocument['owner']['name']);

    timestamp = chatDocument['timestamp'].toDate();

    lastMessageTimestamp = chatDocument['lastMessageTimestamp'].toDate();

    parentChat = ParentChatModel(
      avatarURL: chatDocument['parentChat']['avatarURL'],
      id: chatDocument['parentChat']['id'],
      name: chatDocument['parentChat']['name'],
    );

    parentMessageId = chatDocument['parentMessageId'];

    url = chatDocument['url'] != null ? chatDocument['url'] : "";

    isSubchat = chatDocument['isSubchat'];

    reddit = RedditModel(
      author: chatDocument['reddit']['author'],
      num_comments: chatDocument['reddit']['num_comments'],
      rank: chatDocument['reddit']['rank'],
      reddit_score: chatDocument['reddit']['reddit_score'],
      shortlink: chatDocument['reddit']['shortlink'],
      upvote_ratio: chatDocument['reddit']['upvote_ratio'],
      id: chatDocument['reddit']['id'],
      over_18: chatDocument['reddit']['over_18'],
      subreddit: chatDocument['reddit']['subreddit'],
      // created_utc: DateTime.
    
      
    );


  }

  // TODO: fix the Algolia Snapshot model
  setChatModelFromAlgoliaSnapshot(chatAlgoliaDocument) {
    id = chatAlgoliaDocument['objectId'];
    about = chatAlgoliaDocument['about'];
    avatarURL = chatAlgoliaDocument['avatarURL'];
    name = chatAlgoliaDocument['name'];
    owner = ChatOwnerModel(
        facebookID: chatAlgoliaDocument['owner']['facebookID'],
        id: chatAlgoliaDocument['owner']['id'],
        name: chatAlgoliaDocument['owner']['name']);

    parentChat = ParentChatModel(
      avatarURL: chatAlgoliaDocument['parentChat']['avatarURL'],
      id: chatAlgoliaDocument['parentChat']['id'],
      name: chatAlgoliaDocument['parentChat']['name'],
    );

    parentMessageId = chatAlgoliaDocument['parentMessageId'];

    final millisecondsSinceEpoch =
        chatAlgoliaDocument['timestamp']['_seconds'] * 1000;

    final millisecondsSinceEpochLastMessage =
        chatAlgoliaDocument['lastMessageTimestamp']['_seconds'] * 1000;

    lastMessageTimestamp =
        DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpochLastMessage);

    timestamp = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);

    url = chatAlgoliaDocument['url'] != null ? chatAlgoliaDocument['url'] : "";

    isSubchat = chatAlgoliaDocument['isSubchat'];

    reddit = RedditModel(
      author: chatAlgoliaDocument['reddit']['author'],
      num_comments: chatAlgoliaDocument['reddit']['num_comments'],
      rank: chatAlgoliaDocument['reddit']['rank'],
      reddit_score: chatAlgoliaDocument['reddit']['reddit_score'],
      shortlink: chatAlgoliaDocument['reddit']['shortlink'],
      upvote_ratio: chatAlgoliaDocument['reddit']['upvote_ratio'],
      id: chatAlgoliaDocument['reddit']['id'],
      over_18: chatAlgoliaDocument['reddit']['over_18'],
      subreddit: chatAlgoliaDocument['reddit']['subreddit'],
      // created_utc: DateTime.
    );
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
  final String facebookID;
  final String id;
  final String name;

  ChatOwnerModel({this.facebookID, this.id, this.name});

  getChatOwnerModelMap() {
    final map = {'facebookID': facebookID, 'id': id, 'name': name};

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

class RedditModel {
  // TODO: upper camel case

  final String id;
  final bool over_18;
  final String subreddit;
  final String author;
  final int num_comments;
  final int rank;
  final int reddit_score;
  final String shortlink;
  final double upvote_ratio;
  final DateTime created_utc; // utc will be converted to DateTime

  RedditModel(
      {this.author,
      this.num_comments,
      this.rank,
      this.reddit_score,
      this.shortlink,
      this.upvote_ratio,
      this.id,
      this.over_18,
      this.subreddit,
      this.created_utc});

  getRedditModelMap() {
    final map = {
      'author': author,
      'num_comments': num_comments,
      'rank': rank,
      'reddit_score': reddit_score,
      'shortlink': shortlink,
      'upvote_ratio': upvote_ratio,
    };

    return map;
  }
}
