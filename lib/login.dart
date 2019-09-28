import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fractal/chats_provider.dart';
import 'package:fractal/providers/anonimity_switch_provider.dart';
import 'package:fractal/providers/blocked_user_provider.dart';
import 'package:fractal/providers/notifications_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import './auth_state.dart';
import './model/models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import './terms_of_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LoginPage extends StatefulWidget {
  bool redirectBack = false;

  LoginPage({this.redirectBack = false});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String facebookProfilePicture;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FacebookLogin facebookLogin = FacebookLogin();

  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );

  bool showCircularProgress = false;
  DocumentSnapshot userDocument;
  var isLoggedIn = AuthState.currentUser != null;

  _buildAppBar() {
    return widget.redirectBack ? AppBar(title: new Text("Profile")) : null;
  }

  @override
  Widget build(BuildContext context) {
    const loggedInUserText = "End User License Agreement";
    const notLoggedInUserText =
        "By creating an account, I accept Fractal's End User License Agreement";

    return Scaffold(
      appBar: _buildAppBar(),
      body: AuthState.currentUser != null
          ? _displayUserData()
          : _displayLoginButton(),
      bottomNavigationBar: new Container(
          height: 40.0,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context)
                  .push(new MaterialPageRoute(builder: (context) {
                return new TermsOfService();
              }));
            },
            child: Center(
                child: Text(
              AuthState.currentUser == null
                  ? notLoggedInUserText
                  : loggedInUserText,
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            )),
          )),
      floatingActionButton: AuthState.currentUser != null
          ? FloatingActionButton(
              elevation: 0.6,
              onPressed: () => _logout(),
              child: new Icon(Icons.exit_to_app, color: Colors.white),
              backgroundColor: Theme.of(context).accentColor,
            )
          : null,
    );
  }

  void _kickstartProviders() {
    BlockedUserManager blockedUsersProvider = Provider.of<BlockedUserManager>(context);
    // CachedChats cachedChatsProvider = Provider.of<CachedChats>(context);
    AnonymitySwitch anonymitySwitchProvider = Provider.of<AnonymitySwitch>(context);

    blockedUsersProvider.kickstartBlockedUserIds();
    anonymitySwitchProvider.resetAnonimitySwitch();
  }

  void onLoginStatusChanged(bool isLoggedIn,
      {userDocument, String profileUrl}) async {

    // TODO: find a right place to put this in    
    NotificationsManager notificationsProvider = Provider.of<NotificationsManager>(context);

    if (isLoggedIn) {
      AuthState.instance.setUser(userDocument, profileUrl);
      SharedPreferences prefs;
      prefs = await SharedPreferences.getInstance();
      prefs.setString("id", userDocument.documentID);
      notificationsProvider.kickStartFCM();
      this._kickstartProviders();
    } else {
      AuthState.instance.setUser(null, null);
    }

    if (widget.redirectBack) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        this.userDocument = userDocument;
        this.showCircularProgress = false;
        this.isLoggedIn = isLoggedIn;
      });
    }
  }

  void _kickStartGoogleUser(
      FirebaseUser user, GoogleSignInAccount googleUser) async {
    if (user != null) {
      final QuerySnapshot result = await Firestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid)
          .getDocuments();

      final List<DocumentSnapshot> documents = result.documents;

      if (documents.length == 0) {
        // Update data to server if new user
        Firestore.instance.collection('users').document(user.uid).setData({
          'name': user.displayName,
          'about': "",
          "email": user.email,
          "lastSeen": Timestamp(user.metadata.lastSignInTimestamp, 0),
          "googleProfileURL": googleUser.photoUrl,
          "isGoogle": true,
          "timestamp": Timestamp(user.metadata.creationTimestamp, 0),
          'uid': user.uid,
          "username": ""
        });

        var userDocumentNew = await Firestore.instance
            .collection('users')
            .document(user.uid)
            .get();

        onLoginStatusChanged(true,
            userDocument: userDocumentNew, profileUrl: "");
      } else {
        var userDocumentNew = await Firestore.instance
            .collection('users')
            .document(user.uid)
            .get();

        onLoginStatusChanged(true,
            userDocument: userDocumentNew, profileUrl: "");
      }
    }
  }

  // TODO: fix, stopped here
  void initiateGoogleLogin() async {
    setState(() {
      this.showCircularProgress = true;
    });
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      FirebaseUser user = await _auth.signInWithCredential(credential);

      _kickStartGoogleUser(user, googleUser);
    } catch (error) {
      onLoginStatusChanged(false);
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            FacebookSignInButton(onPressed: () {
              initiateFacebookLogin();
            }),
            GoogleSignInButton(
              onPressed: () {
                initiateGoogleLogin();
              },
            )
          ],
        ),
      );
    }
  }

  _displayUserData() {
    bool isGoogle = (AuthState.currentUser.data.containsKey('isGoogle') &&
        AuthState.currentUser.data['isGoogle']);

    AnonymitySwitch anonimityProvider = Provider.of<AnonymitySwitch>(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 200, // media query this
            width: 200,
            child: CachedNetworkImage(
              imageUrl: isGoogle
                  ? AuthState.currentUser.data['googleProfileURL']
                  : 'https://graph.facebook.com/${AuthState.currentUser['facebookID']}/picture?height=200',
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: anonimityProvider.isAnonymous
                        ? AssetImage('assets/default-avatar.png')
                        : imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // TODO: placeholder can be like a placeholder avatar used for images within chats
              // placeholder: (context, url) => CircularProgressIndicator(),
              // errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
          SizedBox(height: 28.0),
          Text(
            !anonimityProvider.isAnonymous
                ? AuthState.currentUser['name']
                : anonimityProvider.anonymousName,
            style: TextStyle(
              fontSize: 20.0,
            ),
          ),
          new RaisedButton(
            onPressed: anonimityProvider.updateAnonymity,
            textColor:
                !anonimityProvider.isAnonymous ? Colors.white : Colors.black,
            color: !anonimityProvider.isAnonymous
                ? Color.fromRGBO(0, 132, 255, 0.7)
                : Color.fromRGBO(230, 230, 230, 1.0),
            padding: const EdgeInsets.all(8.0),
            child: new Text(
              anonimityProvider.isAnonymous ? "Anonymous" : "Public",
            ),
          ),
        ],
      ),
    );
  }

  
  _clearCache() {
    BlockedUserManager blockedUsersProvider = Provider.of<BlockedUserManager>(context);
    CachedChats cachedChatsProvider = Provider.of<CachedChats>(context);
    AnonymitySwitch anonymitySwitchProvider = Provider.of<AnonymitySwitch>(context);
    
    blockedUsersProvider.clearBlockedUserIds();
    cachedChatsProvider.clearCache();
    anonymitySwitchProvider.resetAnonimitySwitch();
  }

  _logout() async {
    NotificationsManager notificationsProvider = Provider.of<NotificationsManager>(context);
    

    // TODO: check user type to do the right logout
    await notificationsProvider.deleteDeviceToken();
    await facebookLogin.logOut();
    await _googleSignIn.signOut();
    // empty user related cache
    _clearCache();

    SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();
    prefs.clear();
    // prefs.commit(); --> is there anything that is used instead
    
    _auth.signOut();
    onLoginStatusChanged(false);
  }
}