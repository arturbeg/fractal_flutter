import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

// Auth State broardcasts the current user document to all the pages that listen to it
class AuthState {
  
  StreamController _streamController = new StreamController<DocumentSnapshot>.broadcast();
  Stream get onAuthStateChanged => _streamController.stream;

  static AuthState instance = new AuthState._();
  AuthState._();

  setUser(user) {
    AuthState.currentUser = user;
    _streamController.add(user);
  }

  static DocumentSnapshot currentUser;
}

