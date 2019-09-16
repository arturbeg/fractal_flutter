import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:collection';

class CachedMessagesFirebase with ChangeNotifier {
  
  HashMap<String, QuerySnapshot> _cachedMessages = HashMap<String, QuerySnapshot>();

  QuerySnapshot getCachedMessages(String chatId) {
    if(_cachedMessages.containsKey(chatId)) {
      print("Invoke cached messages");
      return _cachedMessages[chatId];
    } else {
      return null;
    }
  }

  void updateCachedMessages(String chatId, QuerySnapshot updatedCachedMessages) {
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
