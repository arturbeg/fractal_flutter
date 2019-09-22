import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:async/async.dart';
import 'package:fractal/auth_state.dart';
import 'package:fractal/model/models.dart';

/*
https://stackoverflow.com/questions/53459669/so-what-is-the-simplest-approach-for-caching-in-flutter
*/

// TODO: later name CachedChatsAndFirebase
class CachedChats with ChangeNotifier {

  List<ChatModel> _cachedSavedChats;
  List<ChatModel> _cachedExploredChats;

  List<ChatModel> getCachedSavedChats() {
    if(_cachedSavedChats==null) {
      _fetchSavedChatsForCache();
      return null;
    } else {
      _cachedSavedChats.sort(
      (ChatModel a, ChatModel b) {
        return a.timestamp.compareTo(b.timestamp);
      }
    );

    return _cachedSavedChats.reversed.toList();
    }
  }

  List<ChatModel>  getCachedExploredChats() {
    if(_cachedExploredChats==null) {
      fetchExploredChatsForCache();
      return null;
    } else {
      return _cachedExploredChats;
    }
  } 

  bool isChatSaved(ChatModel chatDocument) {
    if(_cachedSavedChats==null) {
      _fetchSavedChatsForCache();
      return null;
    }

    List<String> _cachedSavedChatsIds = _cachedSavedChats.map(
      (ChatModel savedChat) {
        return savedChat.id;
      }
    ).toList();

    return _cachedSavedChatsIds.contains(chatDocument.id);
  }
  

  void locallyUpdateCachedSavedChats(ChatModel chatDocument, bool isJoining) {

    List<String> _cachedSavedChatsIds = _cachedSavedChats.map(
      (ChatModel savedChat) {
        return savedChat.id;
      }
    ).toList();

    if(isJoining && !_cachedSavedChatsIds.contains(chatDocument.id)) {
      _cachedSavedChats.add(chatDocument);
    }

    if(!isJoining && _cachedSavedChatsIds.contains(chatDocument.id)) {
      _cachedSavedChats.remove(chatDocument);
    }

    notifyListeners();
  }
  
  _fetchSavedChatsForCache() async {
    QuerySnapshot savedChats = await Firestore.instance
        .collection('joinedChats')
        .where('user.id', isEqualTo: AuthState.currentUser.documentID)
        .orderBy('timestamp', descending: true)
        .limit(80)
        .getDocuments();
    
    List<ChatModel> savedChatsChatModel = savedChats.documents.map(
      (documentSnapshot) {
        var chatDocument = ChatModel();
        chatDocument.setChatModelFromJoinedChatDocumentSnapshot(documentSnapshot);
        return chatDocument;
      }
    ).toList();

    updatedCachedSavedChats(savedChatsChatModel);
  }


  Future<Null> fetchExploredChatsForCache() async {
    QuerySnapshot exploredChats = await Firestore.instance
        .collection('chats')
        .where('isSubchat', isEqualTo: false)
        .orderBy('reddit.rank')
        .limit(30)
        .getDocuments();


    List<ChatModel> exploredChatsChatModel = exploredChats.documents.map(
      (documentSnapshot) {
        var chatDocument = ChatModel();
        chatDocument.setChatModelFromDocumentSnapshot(documentSnapshot);
        return chatDocument;
      }
    ).toList();

    updatedCachedExploredChats(exploredChatsChatModel);
    return null;
  }

  void updatedCachedSavedChats(List<ChatModel> updatedSavedChats) {
    _cachedSavedChats = updatedSavedChats;
    notifyListeners();
  }

  void updatedCachedExploredChats(List<ChatModel> updatedCachedExploredChats) {
    _cachedExploredChats = updatedCachedExploredChats;
      notifyListeners();
  }
}



// TODO: move the whole firebase logic here
  // TODO: bring explored chats logic here
  // TODO: make a getter for the subchats of a specific chat