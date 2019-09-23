import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fractal/chat/chatscreen.dart';
import 'package:fractal/chat_screen_provider.dart';
import 'package:fractal/providers/anonimity_switch_provider.dart';
import 'package:fractal/providers/blocked_user_provider.dart';
import 'package:fractal/providers/messaging_provider.dart';
import 'package:fractal/providers/notifications_provider.dart';
import './WhatsAppHome.dart';
import './auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import './last_message.dart';
import './reported_chats_provider.dart';
import './chats_provider.dart';
import './messages_provider.dart';

Widget getErrorWidget(BuildContext context, FlutterErrorDetails error) {
  return Center(
    child: Text(
      "", // TODO: short term cheating Error Appeared
      style: Theme.of(context).textTheme.title.copyWith(color: Colors.white),
    ),
  );
}

void main() {
  runApp(LoginPage());
}

// TODO: change the name to FractalStartingScreen
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  DocumentSnapshot userDocument;
  bool showCircularProgress = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _db = Firestore.instance;
  Widget _appBarTitle = new Text('Fractal');
  final FirebaseMessaging _fcm = FirebaseMessaging();
  StreamSubscription iosSubscription;

  void _requestNotifications() {
    if (Platform.isIOS) {
      iosSubscription = _fcm.onIosSettingsRegistered.listen((data) {
        //TODO: save the token  OR subscribe to a topic here
      });

      _fcm.requestNotificationPermissions(IosNotificationSettings());
    }
  }

  Future<Null> _function() async {
    // TODO: configure to store custom user data
    SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();
    if (prefs.getString("id") != null) {
      setState(() {
        showCircularProgress = true;
      });
      // print("Got the user");
      Firestore.instance
          .collection('users')
          .document(prefs.getString("id"))
          .get()
          .then((userDocument) {
        // print(userDocument['name']);
        AuthState.instance.setUser(userDocument, "");

        setState(() {
          showCircularProgress = false;
        });
      });
    } else {}
  }

  // TODO: move FCM login into a BLoC or a provider
  void _fcmSetup() {
    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        // TODO optional
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        // TODO optional
      },
    );
  }

  @override
  void initState() {
    super.initState();
    this._function();
    this._requestNotifications();
  }

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return getErrorWidget(context, errorDetails);
    };

    return MultiProvider(
        providers: [
          ChangeNotifierProvider<LastMessages>(builder: (_) => LastMessages()),
          ChangeNotifierProvider<ReportedChatIds>(
              builder: (_) => ReportedChatIds()),
          ChangeNotifierProvider<CachedChats>(builder: (_) => CachedChats()),
          ChangeNotifierProvider<CachedMessagesFirebase>(
              builder: (_) => CachedMessagesFirebase()),
          ChangeNotifierProvider<ChatScreenManager>(
              builder: (_) => ChatScreenManager()),
          ChangeNotifierProvider<AnonymitySwitch>(
              builder: (_) => AnonymitySwitch()),
          ChangeNotifierProvider<BlockedUserManager>(
              builder: (_) => BlockedUserManager()),
          ChangeNotifierProvider<NotificationsManager>(
              builder: (_) => NotificationsManager(fcm: _fcm)),
        ],
        child: MaterialApp(
          // TODO: make sure works, add more
          routes: {'/chat': (context) => ChatScreen()},
          debugShowCheckedModeBanner: false,
          home: Scaffold(
              appBar: AppBar(
                elevation: 0.0,
                title: _appBarTitle,
              ),
              body: showCircularProgress
                  ? Center(child: CircularProgressIndicator())
                  : _displayHomePage()),
        ));
  }

  _displayHomePage() {
    return WhatsAppHome(userDocument: userDocument);
  }
}
