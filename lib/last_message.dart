import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

// For now just caching
// Cache for last messages of chats
// provide the parent chat id and get the cached last message back, if there is none then return null
class LastMessages with ChangeNotifier {
  HashMap<String, QuerySnapshot> _cachedLastMessages =
      HashMap<String, QuerySnapshot>();

  QuerySnapshot getCachedLastMessage(String parentChatId) {
    if (_cachedLastMessages.containsKey(parentChatId)) {
      return _cachedLastMessages[parentChatId];
    } else {
      _fetchLastMessageForCache(parentChatId);
      return null;
    }
  }

  void _fetchLastMessageForCache(String chatId) async {
    QuerySnapshot documents = await Firestore.instance
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy("timestamp", descending: true)
        .limit(1)
        .getDocuments();
    updateCachedLastMessages(chatId, documents);
  }

  void updateCachedLastMessages(
      String parentChatId, QuerySnapshot updatedLastMessage) {
    _cachedLastMessages[parentChatId] = updatedLastMessage;
    notifyListeners();
  }

  Stream<QuerySnapshot> fetchLastMessageFirebaseStream(String chatId) {
    
    Stream<QuerySnapshot> stream = Firestore.instance
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy("timestamp", descending: true)
        .limit(1)
        .snapshots();     
    return stream;
  }

  // TODO: move the whole firebase logic here

}
