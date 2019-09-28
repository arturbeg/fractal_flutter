import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fractal/auth_state.dart';
import 'package:fractal/chat/chatscreen.dart';
import 'package:fractal/model/models.dart';

class NotificationsManager extends ChangeNotifier {
  final BuildContext context;
  bool isLoadingTheChat = true;

  NotificationsManager({this.context, this.fcm});
  
  FirebaseMessaging fcm = FirebaseMessaging();
  // get fcm => fcm;

  // TODO: dispose of the stream, find out why they should be disposed, read more on dart async
  StreamSubscription iosSubscription;

  void kickStartFCM() {
    fcm =
        FirebaseMessaging(); // init empty fcm, equivalent to unsubscribing from all topics
    _requestNotificationsAndSaveToken();
    // fcmSetup();
    notifyListeners();
  }

  void _requestNotificationsAndSaveToken() {
    if (Platform.isIOS) {
      iosSubscription = fcm.onIosSettingsRegistered.listen((data) {
        print(data);
        _saveDeviceToken();
      });

      fcm.requestNotificationPermissions(IosNotificationSettings());
    } else {
      _saveDeviceToken();
    }
  }

  // _openChatAfterNotification(Map<String, dynamic>  message) async {
  //   // joinedChatId
  //   String joinedChatId = message['data']['joinedChatId'];
  //   String notificationTitle = message['notification']['title'];
  //   Scaffold.of(context).showSnackBar(SnackBar(
  //     content: Text("Loading $notificationTitle"),
  //     duration: Duration(seconds: 4),
  //   ));
  //   // TODO: sort out caching
  //   DocumentSnapshot chatDocumentSnapshot = await Firestore.instance.collection('joinedChats').document(joinedChatId).get();
  //   ChatModel chatDocument = ChatModel();
  //   chatDocument.setChatModelFromJoinedChatDocumentSnapshot(chatDocumentSnapshot);
  //   return Navigator.push(context, new MaterialPageRoute(builder: (context) {
  //               return new ChatScreen(chatDocument: chatDocument,);
  //             })); 
  // }

  // void fcmSetup() {
  //   // TODO: can configure inside main?
  //   fcm.configure(
  //     onMessage: (Map<String, dynamic> message) async {
  //       print("onMessage: $message");
  //     },
  //     onLaunch: (Map<String, dynamic> message) async {
  //       print("onLaunch: $message");
  //       // TODO optional
  //       _openChatAfterNotification(message);
  //     },
  //     onResume: (Map<String, dynamic> message) async {
  //       print("onResume: $message");
  //       _openChatAfterNotification(message);
  //       // TODO optional
  //     },
  //   );
  //   notifyListeners();
  // }

  void _saveDeviceToken() async {
    if (AuthState.currentUser != null) {
      String fcmToken = await fcm.getToken();
      // Save it to Firestore
      if (fcmToken != null) {
        var tokens = Firestore.instance
            .collection('users')
            .document(AuthState.currentUser.documentID)
            .collection('tokens')
            .document(fcmToken);

        await tokens.setData({
          'token': fcmToken,
          'createdAt': FieldValue.serverTimestamp(), // optional
          'platform': Platform.operatingSystem // optional
        });
      }
    }
  }

  deleteDeviceToken() async {
    assert(AuthState.currentUser != null);
    if (AuthState.currentUser != null) {
      String fcmToken = await fcm.getToken();
      // Save it to Firestore
      if (fcmToken != null) {
        return Firestore.instance
            .collection('users')
            .document(AuthState.currentUser.documentID)
            .collection('tokens')
            .document(fcmToken)
            .delete();
      }
    }
  }
}

// void subscribeToAllSavedAndNonMutedChats() async {
//   if (AuthState.currentUser != null) {
//     QuerySnapshot savedChats = await Firestore.instance
//         .collection('joinedChats')
//         .where('user.id', isEqualTo: AuthState.currentUser.documentID)
//         .where('')
//         .getDocuments();
//     // TODO: stopped here
//     List<String> savedChatsIds = savedChats.documents.map(
//       (DocumentSnapshot savedChat) {

//         return savedChat.documentID;
//       }
//     ).toList();

//   }
// }
