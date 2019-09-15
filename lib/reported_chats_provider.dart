import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import './auth_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './login.dart';

class ReportedChatIds with ChangeNotifier {
  HashMap<String, bool> _cachedReportedChats = HashMap<String, bool>();

  bool isChatReported(String chatId) {
    print("Checking if the chat is reported");
    if (AuthState.currentUser != null) {
      if (_cachedReportedChats.containsKey(chatId)) {
        return _cachedReportedChats[chatId];
      } else {
        isChatReportedFetch(chatId);
        return false;
      }
    } else {
      return false;
    }
  }

  void updateCachedReportedChats(String chatId, bool isChatReported) {
    print("Updating reported chats cache");
    _cachedReportedChats[chatId] = isChatReported;
    notifyListeners();
  }

  // TODO: make sure only executed once per session (memoiser)
  void isChatReportedFetch(chatId) async {
    if (AuthState.currentUser != null) {
      Firestore.instance
          .collection('users')
          .document(AuthState.currentUser.documentID)
          .get()
          .then((userDocument) {
        if (userDocument.data.containsKey('reportedChats')) {
          final List reportedChats = userDocument.data['reportedChats'];
          updateCachedReportedChats(chatId, reportedChats.contains(chatId));
        } else {
          updateCachedReportedChats(chatId, false);
        }
      });
    }
  }

  void updateReportedChatFirebase(
      String chatId, bool isChatReported, BuildContext context) async {
    print("Update reported chat firebase");

    if (AuthState.currentUser != null) {
      Firestore.instance.runTransaction((transaction) async {
        var documentReference = Firestore.instance
            .collection('users')
            .document(AuthState.currentUser.documentID);

        var data;

        if (isChatReported) {
          data = {
            'reportedChats': FieldValue.arrayRemove([chatId])
          };
        } else {
          data = {
            'reportedChats': FieldValue.arrayUnion([chatId])
          };
        }

        await transaction.update(documentReference, data);

        Scaffold.of(context).showSnackBar(SnackBar(
          content:
              isChatReported ? Text("Report removed!") : Text("Chat reported"),
        ));
        updateCachedReportedChats(chatId, !isChatReported);
      });
    } else {
      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
        return new LoginPage(redirectBack: true);
      }));
    }
  }
}
