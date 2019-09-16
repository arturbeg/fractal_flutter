// TODO: make sure all imports start with package:fractal
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:collection';
import 'package:async/async.dart';

class CachedMessagesFirebase with ChangeNotifier {
  final AsyncMemoizer _memoizer = AsyncMemoizer();

  HashMap<String, QuerySnapshot> _cachedMessages =
      HashMap<String, QuerySnapshot>();

  QuerySnapshot getCachedMessages(String chatId) {
    if (_cachedMessages.containsKey(chatId)) {
      print("Invoke cached messages");
      return _cachedMessages[chatId];
    } else {
      _fetchMessagesForCache(chatId);
      return null;
    }
  }

  void _fetchMessagesForCache(String chatId) async {
    QuerySnapshot messages = await Firestore.instance
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .getDocuments();

    updateCachedMessages(chatId, messages);
  }

  void updateCachedMessages(
      String chatId, QuerySnapshot updatedCachedMessages) {
    _cachedMessages[chatId] = updatedCachedMessages;
    notifyListeners();
  }

  fetchMessages(chatId) {
    return Firestore.instance
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
