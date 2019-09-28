import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fractal/auth_state.dart';
import 'package:fractal/chats_provider.dart';
import 'package:fractal/model/models.dart';
import 'package:fractal/login.dart';
import 'package:fractal/providers/notifications_provider.dart';

// TODO: later migrate all the joined stuff into MOOR
class ChatScreenManager with ChangeNotifier {

  void leaveChat(ChatModel chatDocument, BuildContext context,
      CachedChats cachedChatsProvider, NotificationsManager notificationsProvider) async {
    if (cachedChatsProvider.getCachedSavedChats() != null) {
      cachedChatsProvider.locallyUpdateCachedSavedChats(chatDocument, false);
    }
    if (AuthState.currentUser != null) {
      // update cachedSavedChatsState
      final QuerySnapshot result = await Firestore.instance
          .collection('joinedChats')
          .where('chatId', isEqualTo: chatDocument.id)
          .where('user.id', isEqualTo: AuthState.currentUser.documentID)
          .getDocuments()
          .then((snapshot) {
        for (DocumentSnapshot ds in snapshot.documents) {
          ds.reference.delete();
          // notificationsProvider.fcm.unsubscribeFromTopic(chatDocument.id);
        }
      });
    } else {
      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
        return new LoginPage(redirectBack: true);
      }));
    }
  }

  void joinChat(ChatModel chatDocument, BuildContext context,
      CachedChats cachedChatsProvider, NotificationsManager notificationsProvider) {
    // TODO: update saved messages cache

    if (cachedChatsProvider.getCachedSavedChats() != null) {
      cachedChatsProvider.locallyUpdateCachedSavedChats(chatDocument, true);
    }

    if (AuthState.currentUser != null) {
      final reference = Firestore.instance.collection('joinedChats');
      reference.document().setData({
        // TODO: update ChatModel
        "notificationsON": true,
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
          "name": AuthState.currentUser.data['name'],
          'isGoogle': AuthState.currentUser['isGoogle'],
          'googleProfileURL': AuthState.currentUser['googleProfileURL'],
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
      // NOTIFICATIONS, notifylisteners()?
      // notificationsProvider.fcm.subscribeToTopic(chatDocument.id);
    } else {
      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
        return new LoginPage(redirectBack: true);
      }));
    }
  }
}

  // HashMap<String, bool> _isChatJoinedMap = HashMap<String, bool>();

  // bool getIsChatJoined(String chatId) {
  //   if (_isChatJoinedMap.containsKey(chatId)) {
  //     return _isChatJoinedMap[chatId];
  //   } else {
  //     _isChatJoined(chatId);
  //     return false;
  //   }
  // }

  // Could turn private
  // void updateIsChatJoined(String chatId, bool isJoined) {
  //   _isChatJoinedMap[chatId] = isJoined;
  //   notifyListeners();
  // }

  // Future<bool> _isChatJoined(String chatId) async {
  //   final QuerySnapshot result = await Firestore.instance
  //       .collection('joinedChats')
  //       .where('chatId', isEqualTo: chatId)
  //       .where('user.id', isEqualTo: AuthState.currentUser.documentID)
  //       .getDocuments();

  //   final List<DocumentSnapshot> documents = result.documents;

  //   if (documents.length > 0) {
  //     updateIsChatJoined(chatId, true);
  //   } else {
  //     updateIsChatJoined(chatId, false);
  //   }
  // }