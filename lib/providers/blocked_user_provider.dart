import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fractal/auth_state.dart';
import 'package:fractal/login.dart';

class BlockedUserManager extends ChangeNotifier {

  // Fix and turn into List<String> by creating a User serialiser
  List<dynamic> _blockedUserIds;
  get blockedUserIds => _blockedUserIds;


  bool isSenderBlocked(String senderId) {

    // TODO: refactor
    // if(_blockedUserIds == null) {
    //   List<dynamic> kickstartBlockedUserIds = AuthState.currentUser.data['blockedUsers'];
    //   _blockedUserIds = kickstartBlockedUserIds;
    //   if(_blockedUserIds == null) {
    //     _blockedUserIds = new List<dynamic>();
    //   }
    // }

    if(AuthState.currentUser.data['blockedUsers'] != null && _blockedUserIds==null) {
      _blockedUserIds = AuthState.currentUser.data['blockedUsers'];
    } 

    if(_blockedUserIds !=null && _blockedUserIds.contains(senderId)) {
      return true;
    } else {
      return false;
    }
  }

  void blockAction(DocumentSnapshot messageSnapshot, BuildContext context)
  {
              if (AuthState.currentUser != null) {
                
                String senderId = messageSnapshot['sender']['id'];
                bool isSenderBlocked = _blockedUserIds.contains(senderId);

                Firestore.instance.runTransaction((transaction) async {
                  var documentReference = Firestore.instance
                      .collection('users')
                      .document(AuthState.currentUser.documentID);

                  var data;

                  if (isSenderBlocked) {
                    data = {
                      'blockedUsers': FieldValue.arrayRemove(
                          [messageSnapshot['sender']['id']])
                    };
                    _blockedUserIds.remove(senderId);
                    notifyListeners();
                  } else {
                    data = {
                      'blockedUsers': FieldValue.arrayUnion(
                          [messageSnapshot['sender']['id']])
                    };
                    _blockedUserIds.add(senderId);
                    notifyListeners();
                  }

                  await transaction.update(documentReference, data);

                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      content: isSenderBlocked
                          ? Text("User unblocked!")
                          : Text("User blocked!"),
                      duration: Duration(milliseconds: 500),
                    ),
                  );

                });
              } else {
                Navigator.of(context)
                    .push(new MaterialPageRoute(builder: (context) {
                  return new LoginPage(redirectBack: true);
                }));
              }
            }

}