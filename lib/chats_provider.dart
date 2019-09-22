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
  QuerySnapshot _cachedExploredChats;
  Future<QuerySnapshot> _exploredChatsFuture;

  CachedChats()
      :
        // TODO: fix this quick and dirty solution
        _exploredChatsFuture = Firestore.instance
            .collection('chats')
            .where('isSubchat', isEqualTo: false)
            .orderBy('reddit.rank')
            .limit(30)
            .getDocuments();

  List<ChatModel> getCachedSavedChats() {
    if(_cachedSavedChats==null) {
      _fetchSavedChatsForCache();
    }
    return _cachedSavedChats;
  }

  bool isChatSaved(ChatModel chatDocument) {
    if(_cachedSavedChats==null) {
      _fetchSavedChatsForCache();
      return null;
    }
    return _cachedSavedChats.contains(chatDocument);
  }
  
  get cachedExploredChats => _cachedExploredChats;
  get exploredChatsFuture => _exploredChatsFuture;

  void locallyUpdateCachedSavedChats(ChatModel chatDocument, bool isJoining) {
    
    if(isJoining && !_cachedSavedChats.contains(chatDocument)) {
      _cachedSavedChats.add(chatDocument);
    }

    if(!isJoining && _cachedSavedChats.contains(chatDocument)) {
      _cachedSavedChats.remove(chatDocument);
    }

    notifyListeners();
  }
  
  _fetchSavedChatsForCache() async {
    QuerySnapshot savedChats = await Firestore.instance
        .collection('joinedChats')
        .where('user.id', isEqualTo: AuthState.currentUser.documentID)
        .orderBy('lastMessageTimestamp', descending: true)
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

  void updatedCachedSavedChats(List<ChatModel> updatedSavedChats) {
    _cachedSavedChats = updatedSavedChats;
    notifyListeners();
  }

  void updatedCachedExploredChats(QuerySnapshot updatedCachedExploredChats, {bool notify:true}) {
    _cachedExploredChats = updatedCachedExploredChats;
    if(notify) {
      notifyListeners();
    }
  }

  // TODO: move the whole firebase logic here
  // TODO: bring explored chats logic here
  // TODO: make a getter for the subchats of a specific chat

  // TODO: memoise this?
  Future<QuerySnapshot> _fetchExploredChats() async {
    return await Firestore.instance
        .collection('chats')
        .where('isSubchat', isEqualTo: false)
        .orderBy('reddit.rank')
        .limit(30)
        .getDocuments();
  }

  Future<Null> handleRefresh() async {
    // update function for the future
    _exploredChatsFuture = _fetchExploredChats();
    notifyListeners();

    var cachedExploredChats = await _fetchExploredChats();
    updatedCachedExploredChats(cachedExploredChats, notify: false);
    return null;
  }
}