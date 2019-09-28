// If the user does not have an Anonymity Switch property on Firebase, assume its set to false, then set it once the user takes action

import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fractal/auth_state.dart';
import 'package:fractal/model/models.dart';
import 'package:fractal/login.dart';
import 'package:random_string/random_string.dart';
import 'dart:math' show Random;

class AnonymitySwitch extends ChangeNotifier {
  bool _isAnonymous = initAnonymitySwitch();
  String _anonymousName = generateAnonymousName();

  get isAnonymous => _isAnonymous;
  get anonymousName => _anonymousName;
    
  static String generateAnonymousName() {
    String numericString = randomNumeric(4).toString();
    return "Anonymous ${numericString}";
  }

  void resetAnonimitySwitch() {
    _isAnonymous = initAnonymitySwitch();
    _anonymousName = generateAnonymousName();
    notifyListeners();
  }

  static bool initAnonymitySwitch() {
    if(AuthState.currentUser!=null && AuthState.currentUser.data['isAnonymous'] != null) {
      return AuthState.currentUser.data['isAnonymous'];
    } else {
      return false;
    }
  } 

  void updateAnonymity() {
    _isAnonymous = !_isAnonymous;
    if(_isAnonymous) {
      _anonymousName = generateAnonymousName();
    }
    updateAnonymityOnFirebase();
    notifyListeners();
  }

  void updateAnonymityOnFirebase() {
    assert(AuthState.currentUser != null);
    if (AuthState.currentUser != null) {
      Firestore.instance.runTransaction((transaction) async {
        DocumentReference documentReference = Firestore.instance
            .collection('users')
            .document(AuthState.currentUser.documentID);
        Object data = {'isAnonymous': _isAnonymous};
        await transaction.update(documentReference, data);
      });
      // TODO: edit AuthState as well
    }
  }
}
