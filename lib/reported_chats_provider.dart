import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import './auth_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './login.dart';

class ReportedChatIds with ChangeNotifier {

  void updateReportedChatFirebase(
      String chatId, BuildContext context) async {

    if (AuthState.currentUser != null) {
      Firestore.instance.runTransaction((transaction) async {
        var documentReference = Firestore.instance
            .collection('users')
            .document(AuthState.currentUser.documentID);

        var data;

          data = {
            'reportedChats': FieldValue.arrayUnion([chatId])
          };
      
        await transaction.update(documentReference, data);

        Scaffold.of(context).showSnackBar(SnackBar(
          content:
              Text("Chat reported"),
        ));
      });
    } else {
      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
        return new LoginPage(redirectBack: true);
      }));
    }
  }
}
