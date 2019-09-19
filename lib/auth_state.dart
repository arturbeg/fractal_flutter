import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

// Auth State broardcasts the current user document to all the pages that listen to it
// AuthState will now act as cache accessible by different parts of the app (for now includes the current user as well as the explored chats)
class AuthState {
  
  StreamController _streamController = new StreamController<DocumentSnapshot>.broadcast();
  Stream get onAuthStateChanged => _streamController.stream;

  static AuthState instance = new AuthState._();
  AuthState._();

  setUser(user, profileUrl) {
    AuthState.currentUser = user;
    _streamController.add(user);
  }

  static DocumentSnapshot currentUser;
  // TODO: serialisations
}

