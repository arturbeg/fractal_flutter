import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fractal/auth_state.dart';
import 'package:fractal/model/models.dart';
import 'package:fractal/login.dart';

// TODO: work on naming
// TODO: later migrate all the joined stuff into MOOR
class ChatScreenManager with ChangeNotifier {
  // TODO: introduce cache later (for the saved chats)

  HashMap<String, bool> _isChatJoinedMap = HashMap<String, bool>();

  bool getIsChatJoined(String chatId) {
    if (_isChatJoinedMap.containsKey(chatId)) {
      return _isChatJoinedMap[chatId];
    } else {
      _isChatJoined(chatId);
      return false;
    }
  }

  // Could turn private
  void updateIsChatJoined(String chatId, bool isJoined) {
    _isChatJoinedMap[chatId] = isJoined;
    notifyListeners();
  }

  Future<bool> _isChatJoined(String chatId) async {
    final QuerySnapshot result = await Firestore.instance
        .collection('joinedChats')
        .where('chatId', isEqualTo: chatId)
        .where('user.id', isEqualTo: AuthState.currentUser.documentID)
        .getDocuments();

    final List<DocumentSnapshot> documents = result.documents;

    if (documents.length > 0) {
      updateIsChatJoined(chatId, true);
    } else {
      updateIsChatJoined(chatId, false);
    }
  }

  Future<bool> leaveChat(String chatId, BuildContext context) async {
    if (AuthState.currentUser != null) {
      final QuerySnapshot result = await Firestore.instance
          .collection('joinedChats')
          .where('chatId', isEqualTo: chatId)
          .where('user.id', isEqualTo: AuthState.currentUser.documentID)
          .getDocuments()
          .then((snapshot) {
        for (DocumentSnapshot ds in snapshot.documents) {
          ds.reference.delete();
        }
      });
      updateIsChatJoined(chatId, false);
    } else {
      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
        return new LoginPage(redirectBack: true);
      }));
    }
  }

  joinChat(ChatModel chatDocument, BuildContext context) {
    if (AuthState.currentUser != null) {
      final reference = Firestore.instance.collection('joinedChats');
      reference.document().setData({
        "about": chatDocument.about,
        "avatarURL": chatDocument.avatarURL,
        "chatId": chatDocument.id,
        "chatTimestamp": chatDocument.getFirebaseTimestamp(),
        "name": chatDocument.name,
        "owner": chatDocument.owner.getChatOwnerModelMap(),
        "timestamp": FieldValue.serverTimestamp(),
        "user": {
          "id": AuthState.currentUser.documentID,
          "facebookID": AuthState.currentUser.data['facebookID'],
          "name": AuthState.currentUser.data['name']
        },
        "parentMessageId": chatDocument.parentMessageId,
        "parentChat": chatDocument.parentChat.getParentChatModelMap(),
        "isSubchat": chatDocument.isSubchat,
        "lastMessageTimestamp": FieldValue.serverTimestamp(),
        "url": chatDocument.url,
        "reddit": {
          "id": chatDocument.reddit.id,
          "author": chatDocument.reddit.author,
          "num_comments": chatDocument.reddit.num_comments,
          "over_18": chatDocument.reddit.over_18,
          "subreddit": chatDocument.reddit.subreddit,
          "upvote_ratio": chatDocument.reddit.upvote_ratio,
          "shortlink": chatDocument.reddit.shortlink,
          'reddit_score': chatDocument.reddit.reddit_score,
          'rank': chatDocument.reddit.rank
        },
      });
      updateIsChatJoined(chatDocument.id, true);
    } else {
      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
        return new LoginPage(redirectBack: true);
      }));
    }
  }
}
