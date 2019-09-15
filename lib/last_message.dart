import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// For now just caching
// Cache for last messages of chats
// provide the parent chat id and get the cached last message back, if there is none then return null
class LastMessages with ChangeNotifier {
  HashMap<String, QuerySnapshot> _cachedLastMessages = HashMap<String, QuerySnapshot>();

  QuerySnapshot getCachedLastMessage(String parentChatId) {
    if(_cachedLastMessages.containsKey(parentChatId)) {
      return _cachedLastMessages[parentChatId];
    } else {
      return null;
    }
  }

  void updateCachedLastMessages(String parentChatId, QuerySnapshot updatedLastMessage) {
    _cachedLastMessages[parentChatId] = updatedLastMessage;
    notifyListeners();
  }

  // TODO: move the whole firebase logic here

}