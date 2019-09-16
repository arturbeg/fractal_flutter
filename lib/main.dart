import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './WhatsAppHome.dart';
import './auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import './last_message.dart';
import './reported_chats_provider.dart';
import './chats_provider.dart';

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

  Future<Null> _function() async {
    // TODO: configure to store custom user data
    SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();
    if (prefs.getString("id") != null) {
      setState(() {
        showCircularProgress = true;
      });
      print("Got the user");
      Firestore.instance
          .collection('users')
          .document(prefs.getString("id"))
          .get()
          .then((userDocument) {
        print(userDocument['name']);
        AuthState.instance.setUser(userDocument, "");
        setState(() {
          showCircularProgress = false;
        });
      });
    } else {
      // onLoginStatusChanged(false);
      print('Is not logged in');
    }
  }

  @override
  void initState() {
    super.initState();
    this._function();
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
        ],
        child: MaterialApp(
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
