import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './auth_state.dart';
import './model/models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';

// TODO: start using loggers

class LoginPage extends StatefulWidget {
  bool redirectBack = false;

  LoginPage({this.redirectBack=false});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String facebookProfilePicture;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var facebookLogin = FacebookLogin();
  bool showCircularProgress = false;
  DocumentSnapshot userDocument;
  var isLoggedIn = AuthState.currentUser != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthState.currentUser!=null ? _displayUserData() : _displayLoginButton(),
      floatingActionButton: AuthState.currentUser!=null
          ? FloatingActionButton(
              elevation: 0.6,
              onPressed: () => _logout(),
              child: new Icon(Icons.exit_to_app, color: Colors.white),
              backgroundColor: Theme.of(context).accentColor,
            )
          : null,
    );
  }

  void onLoginStatusChanged(bool isLoggedIn,
      {userDocument, String profileUrl}) async {
    
    // setState(() {
    //   this.userDocument = userDocument;
    //   this.showCircularProgress = false;
    //   this.isLoggedIn = isLoggedIn;
    // });

    if (isLoggedIn) {
      AuthState.instance.setUser(userDocument, profileUrl);

      SharedPreferences prefs;
      prefs = await SharedPreferences.getInstance();
      prefs.setString("id", userDocument.documentID);
    } else {
      AuthState.instance.setUser(null, null);
    }

    if (widget.redirectBack) {
      Navigator.of(context).pop();
      // make sure setState is not relevant in here
    } else {
      print('Not a redirect back');
      setState(() {
        this.userDocument = userDocument;
        this.showCircularProgress = false;
        this.isLoggedIn = isLoggedIn;
      });
    }
  }

  void initiateFacebookLogin() async {
    var facebookLoginResult =
        await facebookLogin.logInWithReadPermissions(['email']);

    setState(() {
      this.showCircularProgress = true;
    });

    switch (facebookLoginResult.status) {
      case FacebookLoginStatus.error:
        onLoginStatusChanged(false);
        break;
      case FacebookLoginStatus.cancelledByUser:
        onLoginStatusChanged(false);
        break;
      case FacebookLoginStatus.loggedIn:
        try {
          final FacebookAccessToken accessToken =
              facebookLoginResult.accessToken;
          AuthCredential credential = FacebookAuthProvider.getCredential(
              accessToken: accessToken.token);
          FirebaseUser user = await _auth.signInWithCredential(credential);

          if (user != null) {
            final QuerySnapshot result = await Firestore.instance
                .collection('users')
                .where('uid', isEqualTo: user.uid)
                .getDocuments();

            final List<DocumentSnapshot> documents = result.documents;

            var graphResponse = await http.get(
                'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${facebookLoginResult.accessToken.token}');

            var profile = json.decode(graphResponse.body);
            if (documents.length == 0) {
              // Update data to server if new user
              Firestore.instance
                  .collection('users')
                  .document(user.uid)
                  .setData({
                'name': user.displayName,
                'about': "",
                "email": user.email,
                "lastSeen": Timestamp(user.metadata.lastSignInTimestamp, 0),
                "facebookID": profile['id'],
                "timestamp": Timestamp(user.metadata.creationTimestamp, 0),
                'uid': user.uid,
                "username": ""
              });

              var userDocumentNew = await Firestore.instance
                  .collection('users')
                  .document(user.uid)
                  .get();

              onLoginStatusChanged(true,
                  userDocument: userDocumentNew,
                  profileUrl: profile['picture']['data']['url']);
            } else {
              var userDocumentNew = await Firestore.instance
                  .collection('users')
                  .document(user.uid)
                  .get();

              onLoginStatusChanged(true,
                  userDocument: userDocumentNew,
                  profileUrl: profile['picture']['data']['url']);
            }
            break;
          }
        } catch (e) {
          //print(e);
        }
    }
  }

  _displayLoginButton() {
    if (showCircularProgress) {
      return Center(child: CircularProgressIndicator());
    } else {
      // TODO: make the button more appealing
      return Center(
        child: FacebookSignInButton(onPressed: () {
          initiateFacebookLogin();
        }),
      );
    }
  }

  _displayUserData() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 200.0,
            width: 200.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              image: DecorationImage(
                fit: BoxFit.fill,
                image: NetworkImage(
                    'https://graph.facebook.com/${AuthState.currentUser['facebookID']}/picture?height=200'),
                //TODO: have a default photo option in the app's assets
                //AssetImage('assets/default-avatar.png')
              ),
            ),
          ),
          SizedBox(height: 28.0),
          Text(
            AuthState.currentUser['name'],
            style: TextStyle(
              fontSize: 20.0,
            ),
          ),
        ],
      ),
    );
  }

  _logout() async {
    await facebookLogin.logOut();

    SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();
    prefs.clear();
    // prefs.commit(); --> is there anything that is used instead

    _auth.signOut();
    onLoginStatusChanged(false);
  }
}
