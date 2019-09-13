import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExploreChatsCache {
  
  StreamController _exploreChatsController = new StreamController<QuerySnapshot>.broadcast();

  Stream get onExploreChatsChange => _exploreChatsController.stream;

  static ExploreChatsCache instance = new ExploreChatsCache._();
  ExploreChatsCache._();

  setExploreChats(snapshot) {
    print("Explored Chats Cache is set");
    ExploreChatsCache.snapshot = snapshot;
    _exploreChatsController.add(snapshot);
  }

  static QuerySnapshot snapshot;

}
